use std::net::SocketAddr;
use std::str::FromStr;
use std::io::{self, Write};

use anyhow::Result;
use axum::{routing::{get, post}, Router, extract::State, Form, response::Html, Json, response::Json as AxumJson};
use chrono::{Local, NaiveTime};
use serde::{Deserialize, Serialize};
use sqlx::{sqlite::{SqlitePoolOptions, SqliteConnectOptions, SqliteJournalMode, SqliteSynchronous}, SqlitePool};
use std::sync::Arc;
use tokio::signal;
use tokio::io::{AsyncBufReadExt, BufReader};
use tower_http::cors::{Any, CorsLayer};
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Clone)]
struct AppState {
    db: SqlitePool,
    external_api_url: String,
}

#[derive(Serialize, sqlx::FromRow, Clone)]
struct ShiftPlan {
    id: i64,
    team: String,
    shift_name: String,
    planned_output: i64,
    start_time: String,
    end_time: String,
}

#[derive(sqlx::FromRow)]
struct ScanCount { count: i64 }

#[derive(Deserialize)]
struct ScanForm { barcode: String }

#[derive(Serialize, Deserialize)]
struct ScanRequest { barcode: String }

#[derive(Serialize)]
struct ScanResponse { success: bool, message: String, current_count: i64 }

#[derive(Serialize)]
struct StatsResponse {
    team: String,
    shift_name: String,
    planned_output: i64,
    current_count: i64,
    completion_rate: f64,
}

#[derive(Serialize)]
struct ApiResponse<T> {
    success: bool,
    message: String,
    data: Option<T>,
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::from_default_env())
        .with(tracing_subscriber::fmt::layer())
        .init();

    let mut database_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite:scan_demo.db".into());
    // Normalize common mistake on Windows: use sqlite: for relative paths
    if database_url == "sqlite://scan_demo.db" {
        database_url = "sqlite:scan_demo.db".into();
    }
    let external_api_url = std::env::var("EXTERNAL_API_URL").unwrap_or_else(|_| "https://httpbin.org/post".into());

    let connect_opts = SqliteConnectOptions::from_str(&database_url)?
        .create_if_missing(true)
        .journal_mode(SqliteJournalMode::Wal)
        .synchronous(SqliteSynchronous::Normal);
    let db = SqlitePoolOptions::new().max_connections(5).connect_with(connect_opts).await?;
    migrate_and_seed(&db).await?;

    let state = Arc::new(AppState { db, external_api_url });

    // 检查是否以CLI模式运行
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 && args[1] == "--cli" {
        run_cli_mode(state).await?;
    } else {
        run_web_mode(state).await?;
    }
    Ok(())
}

async fn run_web_mode(state: Arc<AppState>) -> Result<()> {
    let app = Router::new()
        // Web 界面路由（保持兼容）
        .route("/", get(index))
        .route("/scan", post(scan_barcode))
        .route("/stats", get(get_stats))
        // JSON API 路由
        .route("/api/scan", post(api_scan_barcode))
        .route("/api/stats", get(api_get_stats))
        .route("/api/health", get(api_health))
        .with_state(state)
        .layer(CorsLayer::new().allow_methods(Any).allow_origin(Any).allow_headers(Any));

    let addr: SocketAddr = "0.0.0.0:3000".parse().unwrap();
    info!("Web模式启动，监听地址: {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    Ok(())
}

async fn run_cli_mode(state: Arc<AppState>) -> Result<()> {
    println!("=== 扫码生产看板 CLI 模式 ===");
    println!("输入 'quit' 或 'exit' 退出程序");
    println!("输入 'stats' 查看当前统计");
    println!("输入 'help' 查看帮助");
    println!("--------------------------------");

    let stdin = tokio::io::stdin();
    let mut reader = BufReader::new(stdin);
    let mut line = String::new();

    loop {
        print!("请输入条码: ");
        io::stdout().flush().unwrap();
        
        line.clear();
        if reader.read_line(&mut line).await? == 0 {
            break; // EOF
        }

        let input = line.trim();
        if input.is_empty() {
            continue;
        }

        match input {
            "quit" | "exit" => {
                println!("退出程序");
                break;
            }
            "stats" => {
                display_stats(&state).await?;
            }
            "help" => {
                println!("命令说明:");
                println!("  <条码> - 扫描条码");
                println!("  stats  - 显示当前统计");
                println!("  help   - 显示此帮助");
                println!("  quit   - 退出程序");
            }
            _ => {
                // 处理条码扫描
                let result = process_barcode_scan(&state, input).await?;
                println!("扫描结果: {}", if result.success { "✅ 成功" } else { "❌ 失败" });
                println!("消息: {}", result.message);
                println!("当前产量: {}", result.current_count);
            }
        }
        println!();
    }
    Ok(())
}

async fn display_stats(state: &Arc<AppState>) -> Result<()> {
    let now = Local::now().time();
    let plan: Option<ShiftPlan> = current_shift(&state.db, now).await.ok().flatten();
    let stats = current_stats(&state.db).await.unwrap_or(0);

    let (team, shift_name, planned) = plan
        .map(|p| (p.team, p.shift_name, p.planned_output))
        .unwrap_or_else(|| ("-".into(), "-".into(), 0));

    println!("=== 当前生产统计 ===");
    println!("班组: {}", team);
    println!("班次: {}", shift_name);
    println!("计划产量: {}", planned);
    println!("实际产量: {}", stats);
    println!("完成率: {:.1}%", if planned > 0 { (stats as f64 / planned as f64) * 100.0 } else { 0.0 });
    println!("==================");
    Ok(())
}

async fn process_barcode_scan(state: &Arc<AppState>, barcode: &str) -> Result<ScanResponse> {
    let now = Local::now();
    let mut success = false;
    let message;

    // 调用外部接口
    match reqwest::Client::new()
        .post(&state.external_api_url)
        .json(&serde_json::json!({ "barcode": barcode }))
        .send()
        .await
    {
        Ok(resp) => {
            if resp.status().is_success() {
                success = true;
                message = "扫描成功".into();
            } else {
                message = format!("外部接口错误: {}", resp.status());
            }
        }
        Err(e) => {
            message = format!("请求失败: {}", e);
        }
    }

    // 记录扫描
    let _ = sqlx::query("INSERT INTO scans (barcode, success, created_at) VALUES (?1, ?2, ?3)")
        .bind(barcode)
        .bind(if success { 1 } else { 0 })
        .bind(now.to_rfc3339())
        .execute(&state.db)
        .await;

    let stats = current_stats(&state.db).await.unwrap_or(0);
    Ok(ScanResponse { success, message, current_count: stats })
}

async fn shutdown_signal() {
    let _ = signal::ctrl_c().await;
    info!("shutdown signal received");
}

async fn migrate_and_seed(db: &SqlitePool) -> Result<()> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS shift_plan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            team TEXT NOT NULL,
            shift_name TEXT NOT NULL,
            planned_output INTEGER NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL
        )",
    )
    .execute(db)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS scans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT NOT NULL,
            success INTEGER NOT NULL,
            created_at TEXT NOT NULL
        )",
    )
    .execute(db)
    .await?;

    // seed a default shift if none
    let existing: (i64,) = sqlx::query_as("SELECT COUNT(1) FROM shift_plan")
        .fetch_one(db)
        .await?;
    if existing.0 == 0 {
        sqlx::query("INSERT INTO shift_plan (team, shift_name, planned_output, start_time, end_time) VALUES (?1, ?2, ?3, ?4, ?5)")
            .bind("A班")
            .bind("白班")
            .bind(500)
            .bind("08:00:00")
            .bind("20:00:00")
            .execute(db)
            .await?;
    }
    Ok(())
}

async fn index(State(state): State<Arc<AppState>>) -> Html<String> {
    let now = Local::now().time();
    let plan: Option<ShiftPlan> = current_shift(&state.db, now).await.ok().flatten();
    let stats = current_stats(&state.db).await.unwrap_or(0);

    let (team, shift_name, planned) = plan
        .map(|p| (p.team, p.shift_name, p.planned_output))
        .unwrap_or_else(|| ("-".into(), "-".into(), 0));

    let html = render_index(team, shift_name, planned, stats, None);
    Html(html)
}

async fn scan_barcode(State(state): State<Arc<AppState>>, Form(form): Form<ScanForm>) -> Html<String> {
    let barcode = form.barcode.trim().to_string();
    let now = Local::now();
    let mut success = false;
    let message;

    // call external API
    match reqwest::Client::new()
        .post(&state.external_api_url)
        .json(&serde_json::json!({ "barcode": barcode }))
        .send()
        .await
    {
        Ok(resp) => {
            if resp.status().is_success() {
                success = true;
                message = "扫描成功".into();
            } else {
                message = format!("外部接口错误: {}", resp.status());
            }
        }
        Err(e) => {
            message = format!("请求失败: {}", e);
        }
    }

    // record scan
    let _ = sqlx::query("INSERT INTO scans (barcode, success, created_at) VALUES (?1, ?2, ?3)")
        .bind(&barcode)
        .bind(if success { 1 } else { 0 })
        .bind(now.to_rfc3339())
        .execute(&state.db)
        .await;

    let stats = current_stats(&state.db).await.unwrap_or(0);
    
    // 只返回结果部分，而不是整个页面
    let status = if success { "✅ 成功" } else { "❌ 失败" };
    let result_html = format!(
        r#"<div id="result" class="card">
            <div style="margin-bottom: 8px;">{status} - {msg}</div>
            <div style="font-size: 14px; color: #666;">当前产量: {stats}</div>
        </div>"#,
        status = status,
        msg = html_escape(&message),
        stats = stats
    );
    
    Html(result_html)
}

async fn get_stats(State(state): State<Arc<AppState>>) -> Html<String> {
    let now = Local::now().time();
    let plan: Option<ShiftPlan> = current_shift(&state.db, now).await.ok().flatten();
    let stats = current_stats(&state.db).await.unwrap_or(0);

    let (team, shift_name, planned) = plan
        .map(|p| (p.team, p.shift_name, p.planned_output))
        .unwrap_or_else(|| ("-".into(), "-".into(), 0));

    let stats_html = format!(
        r#"<div class="grid">
            <div class="card"><b>当前班组</b><div>{team}</div></div>
            <div class="card"><b>当前班次</b><div>{shift}</div></div>
            <div class="card"><b>本班次排产量</b><div>{planned}</div></div>
            <div class="card"><b>实时产量</b><div id="produced">{stats}</div></div>
        </div>"#,
        team = html_escape(&team),
        shift = html_escape(&shift_name),
        planned = planned,
        stats = stats
    );
    
    Html(stats_html)
}

async fn current_shift(db: &SqlitePool, now: NaiveTime) -> Result<Option<ShiftPlan>> {
    let plans: Vec<ShiftPlan> = sqlx::query_as("SELECT id, team, shift_name, planned_output, start_time, end_time FROM shift_plan")
        .fetch_all(db)
        .await?;
    let selected = plans.into_iter().find(|p| {
        let start = NaiveTime::parse_from_str(&p.start_time, "%H:%M:%S").unwrap_or(NaiveTime::from_hms_opt(0,0,0).unwrap());
        let end = NaiveTime::parse_from_str(&p.end_time, "%H:%M:%S").unwrap_or(NaiveTime::from_hms_opt(23,59,59).unwrap());
        if end >= start {
            now >= start && now <= end
        } else {
            // crosses midnight
            now >= start || now <= end
        }
    });
    Ok(selected)
}

async fn current_stats(db: &SqlitePool) -> Result<i64> {
    let ScanCount { count } = sqlx::query_as::<_, ScanCount>("SELECT COUNT(1) as count FROM scans WHERE success = 1")
        .fetch_one(db)
        .await?;
    Ok(count)
}

fn render_index(team: String, shift: String, planned: i64, produced: i64, scan: Option<ScanResponse>) -> String {
    let status = scan.as_ref().map(|s| if s.success { "✅ 成功" } else { "❌ 失败" }).unwrap_or("");
    let msg = scan.as_ref().map(|s| s.message.as_str()).unwrap_or("");
    format!(
        r##"<!doctype html>
<html lang=\"zh-CN\">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>生产看板 Demo</title>
  <script src="https://unpkg.com/htmx.org@1.9.10"></script>
  <script src="https://unpkg.com/alpinejs@3.x.x" defer></script>
  <style>
    body {{ font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial; margin: 20px; }}
    .card {{ border: 1px solid #ddd; padding: 16px; border-radius: 8px; margin-bottom: 12px; }}
    .grid {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }}
    .ok {{ color: #067d17; }}
    .fail {{ color: #b00020; }}
    input[type=text] {{ font-size: 20px; padding: 8px; width: 100%; }}
    button {{ padding: 8px 12px; font-size: 16px; }}
  </style>
  </head>
  <body x-data="{{ barcode: '' }}">
    <h2>生产看板</h2>
    <div id="stats-container" class="grid">
      <div class="card"><b>当前班组</b><div>{team}</div></div>
      <div class="card"><b>当前班次</b><div>{shift}</div></div>
      <div class="card"><b>本班次排产量</b><div>{planned}</div></div>
      <div class="card"><b>实时产量</b><div id="produced">{produced}</div></div>
    </div>

    <div class="card">
      <form hx-post="/scan" hx-target="#result" hx-swap="outerHTML" hx-on::after-request="htmx.trigger('#stats-container', 'refresh-stats')">
        <label>条码输入</label>
        <input type="text" name="barcode" x-model="barcode" autofocus placeholder="扫描或输入条码后回车" />
        <button type="submit">提交</button>
      </form>
    </div>
    <div id="result" class="card">{status} {msg}</div>
    
    <script>
      document.body.addEventListener('refresh-stats', function() {{
        htmx.ajax('GET', '/stats', '#stats-container');
      }});
    </script>
  </body>
</html>"##,
        team = html_escape(&team),
        shift = html_escape(&shift),
        planned = planned,
        produced = produced,
        status = status,
        msg = html_escape(msg),
    )
}

fn html_escape(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

// ===== JSON API 处理函数 =====

async fn api_health() -> AxumJson<ApiResponse<String>> {
    AxumJson(ApiResponse {
        success: true,
        message: "服务正常运行".to_string(),
        data: Some("OK".to_string()),
    })
}

async fn api_scan_barcode(
    State(state): State<Arc<AppState>>, 
    Json(payload): Json<ScanRequest>
) -> AxumJson<ApiResponse<ScanResponse>> {
    let barcode = payload.barcode.trim().to_string();
    
    if barcode.is_empty() {
        return AxumJson(ApiResponse {
            success: false,
            message: "条码不能为空".to_string(),
            data: None,
        });
    }

    match process_barcode_scan(&state, &barcode).await {
        Ok(scan_result) => {
            AxumJson(ApiResponse {
                success: true,
                message: "扫描处理完成".to_string(),
                data: Some(scan_result),
            })
        }
        Err(e) => {
            AxumJson(ApiResponse {
                success: false,
                message: format!("处理失败: {}", e),
                data: None,
            })
        }
    }
}

async fn api_get_stats(State(state): State<Arc<AppState>>) -> AxumJson<ApiResponse<StatsResponse>> {
    let now = Local::now().time();
    
    match current_shift(&state.db, now).await {
        Ok(plan) => {
            let stats = current_stats(&state.db).await.unwrap_or(0);
            
            let (team, shift_name, planned) = plan
                .map(|p| (p.team, p.shift_name, p.planned_output))
                .unwrap_or_else(|| ("-".into(), "-".into(), 0));
            
            let completion_rate = if planned > 0 {
                (stats as f64 / planned as f64) * 100.0
            } else {
                0.0
            };
            
            let stats_response = StatsResponse {
                team,
                shift_name,
                planned_output: planned,
                current_count: stats,
                completion_rate,
            };
            
            AxumJson(ApiResponse {
                success: true,
                message: "统计数据获取成功".to_string(),
                data: Some(stats_response),
            })
        }
        Err(e) => {
            AxumJson(ApiResponse {
                success: false,
                message: format!("获取统计数据失败: {}", e),
                data: None,
            })
        }
    }
}
