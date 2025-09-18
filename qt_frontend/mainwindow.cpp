#include "mainwindow.h"
#include "barcodescanner.h"
#include "statsdisplay.h"
#include "apiclient.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QTextEdit>
#include <QGroupBox>
#include <QProgressBar>
#include <QTimer>
#include <QMessageBox>
#include <QDateTime>
#include <QApplication>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , m_centralWidget(nullptr)
    , m_mainLayout(nullptr)
    , m_statsGroup(nullptr)
    , m_scanGroup(nullptr)
    , m_logGroup(nullptr)
    , m_statsTimer(nullptr)
    , m_plannedOutput(0)
    , m_currentCount(0)
    , m_completionRate(0.0)
{
    setWindowTitle("扫码生产看板 - QT5 前端");
    setMinimumSize(800, 600);
    resize(1000, 700);
    
    // 创建业务逻辑组件
    m_apiClient = std::make_unique<ApiClient>();
    m_scanner = std::make_unique<BarCodeScanner>(m_apiClient.get());
    m_statsDisplay = std::make_unique<StatsDisplay>(m_apiClient.get());
    
    setupUI();
    setupConnections();
    
    // 启动定时器，每5秒刷新一次统计数据
    m_statsTimer = new QTimer(this);
    connect(m_statsTimer, &QTimer::timeout, this, &MainWindow::onRefreshStats);
    m_statsTimer->start(5000);
    
    // 初始加载统计数据
    onRefreshStats();
    
    logMessage("应用程序启动完成", "SUCCESS");
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupUI()
{
    m_centralWidget = new QWidget(this);
    setCentralWidget(m_centralWidget);
    
    m_mainLayout = new QVBoxLayout(m_centralWidget);
    m_mainLayout->setSpacing(20);
    m_mainLayout->setContentsMargins(20, 20, 20, 20);
    
    // 统计显示区域
    m_statsGroup = new QGroupBox("生产统计", this);
    m_statsLayout = new QGridLayout(m_statsGroup);
    
    m_teamLabel = new QLabel("班组: -", this);
    m_shiftLabel = new QLabel("班次: -", this);
    m_plannedLabel = new QLabel("计划产量: 0", this);
    m_currentLabel = new QLabel("当前产量: 0", this);
    
    m_progressBar = new QProgressBar(this);
    m_progressBar->setRange(0, 100);
    m_progressBar->setValue(0);
    m_progressBar->setFormat("完成率: %p%");
    
    // 设置标签样式
    QFont labelFont = m_teamLabel->font();
    labelFont.setPointSize(12);
    labelFont.setBold(true);
    m_teamLabel->setFont(labelFont);
    m_shiftLabel->setFont(labelFont);
    m_plannedLabel->setFont(labelFont);
    m_currentLabel->setFont(labelFont);
    
    m_statsLayout->addWidget(m_teamLabel, 0, 0);
    m_statsLayout->addWidget(m_shiftLabel, 0, 1);
    m_statsLayout->addWidget(m_plannedLabel, 1, 0);
    m_statsLayout->addWidget(m_currentLabel, 1, 1);
    m_statsLayout->addWidget(m_progressBar, 2, 0, 1, 2);
    
    // 扫码区域
    m_scanGroup = new QGroupBox("条码扫描", this);
    m_scanLayout = new QVBoxLayout(m_scanGroup);
    
    m_barcodeInput = new QLineEdit(this);
    m_barcodeInput->setPlaceholderText("请输入或扫描条码...");
    m_barcodeInput->setFont(QFont("Consolas", 14));
    
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    m_scanButton = new QPushButton("扫描", this);
    m_clearButton = new QPushButton("清空", this);
    m_refreshButton = new QPushButton("刷新统计", this);
    
    m_scanButton->setMinimumHeight(40);
    m_clearButton->setMinimumHeight(40);
    m_refreshButton->setMinimumHeight(40);
    
    buttonLayout->addWidget(m_scanButton);
    buttonLayout->addWidget(m_clearButton);
    buttonLayout->addWidget(m_refreshButton);
    buttonLayout->addStretch();
    
    m_scanLayout->addWidget(m_barcodeInput);
    m_scanLayout->addLayout(buttonLayout);
    
    // 日志区域
    m_logGroup = new QGroupBox("操作日志", this);
    m_logLayout = new QVBoxLayout(m_logGroup);
    
    m_logDisplay = new QTextEdit(this);
    m_logDisplay->setMaximumHeight(200);
    m_logDisplay->setReadOnly(true);
    m_logDisplay->setFont(QFont("Consolas", 9));
    
    m_logLayout->addWidget(m_logDisplay);
    
    // 添加到主布局
    m_mainLayout->addWidget(m_statsGroup);
    m_mainLayout->addWidget(m_scanGroup);
    m_mainLayout->addWidget(m_logGroup);
}

void MainWindow::setupConnections()
{
    // 按钮连接
    connect(m_scanButton, &QPushButton::clicked, this, &MainWindow::onScanButtonClicked);
    connect(m_clearButton, &QPushButton::clicked, this, &MainWindow::onClearButtonClicked);
    connect(m_refreshButton, &QPushButton::clicked, this, &MainWindow::onRefreshStats);
    
    // 回车键扫描
    connect(m_barcodeInput, &QLineEdit::returnPressed, this, &MainWindow::onScanButtonClicked);
    
    // API 连接
    connect(m_apiClient.get(), &ApiClient::responseReceived, this, &MainWindow::onApiResponseReceived);
    connect(m_apiClient.get(), &ApiClient::errorOccurred, this, &MainWindow::onApiError);
    
    // 统计更新连接
    connect(m_statsDisplay.get(), &StatsDisplay::statsUpdated, this, &MainWindow::onStatsUpdated);
}

void MainWindow::onScanButtonClicked()
{
    QString barcode = m_barcodeInput->text().trimmed();
    if (barcode.isEmpty()) {
        QMessageBox::warning(this, "警告", "请输入条码");
        return;
    }
    
    logMessage(QString("开始扫描条码: %1").arg(barcode), "INFO");
    m_scanButton->setEnabled(false);
    m_scanButton->setText("扫描中...");
    
    // 发送扫描请求
    m_scanner->scanBarcode(barcode);
}

void MainWindow::onClearButtonClicked()
{
    m_barcodeInput->clear();
    m_barcodeInput->setFocus();
    logMessage("清空输入框", "INFO");
}

void MainWindow::onRefreshStats()
{
    logMessage("刷新统计数据...", "INFO");
    m_statsDisplay->refreshStats();
}

void MainWindow::onApiResponseReceived(const QString &response)
{
    logMessage(QString("API响应: %1").arg(response), "SUCCESS");
    
    // 恢复扫描按钮状态
    m_scanButton->setEnabled(true);
    m_scanButton->setText("扫描");
    
    // 清空输入框并重新聚焦
    m_barcodeInput->clear();
    m_barcodeInput->setFocus();
    
    // 刷新统计数据
    onRefreshStats();
}

void MainWindow::onApiError(const QString &error)
{
    logMessage(QString("API错误: %1").arg(error), "ERROR");
    
    // 恢复扫描按钮状态
    m_scanButton->setEnabled(true);
    m_scanButton->setText("扫描");
    
    QMessageBox::critical(this, "错误", QString("操作失败: %1").arg(error));
}

void MainWindow::onStatsUpdated()
{
    updateStatsDisplay();
}

void MainWindow::updateStatsDisplay()
{
    // 从 StatsDisplay 获取最新数据
    m_currentTeam = m_statsDisplay->getTeam();
    m_currentShift = m_statsDisplay->getShift();
    m_plannedOutput = m_statsDisplay->getPlannedOutput();
    m_currentCount = m_statsDisplay->getCurrentCount();
    m_completionRate = m_statsDisplay->getCompletionRate();
    
    // 更新UI显示
    m_teamLabel->setText(QString("班组: %1").arg(m_currentTeam));
    m_shiftLabel->setText(QString("班次: %1").arg(m_currentShift));
    m_plannedLabel->setText(QString("计划产量: %1").arg(m_plannedOutput));
    m_currentLabel->setText(QString("当前产量: %1").arg(m_currentCount));
    
    m_progressBar->setValue(static_cast<int>(m_completionRate));
    
    // 根据完成率设置进度条颜色
    if (m_completionRate >= 100.0) {
        m_progressBar->setStyleSheet("QProgressBar::chunk { background-color: #4CAF50; }");
    } else if (m_completionRate >= 80.0) {
        m_progressBar->setStyleSheet("QProgressBar::chunk { background-color: #FF9800; }");
    } else {
        m_progressBar->setStyleSheet("QProgressBar::chunk { background-color: #2196F3; }");
    }
}

void MainWindow::logMessage(const QString &message, const QString &type)
{
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss");
    QString logEntry = QString("[%1] [%2] %3").arg(timestamp, type, message);
    
    m_logDisplay->append(logEntry);
    
    // 自动滚动到底部
    QTextCursor cursor = m_logDisplay->textCursor();
    cursor.movePosition(QTextCursor::End);
    m_logDisplay->setTextCursor(cursor);
}
