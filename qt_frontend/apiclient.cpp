#include "apiclient.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <QDebug>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_baseUrl("http://localhost:3000")
    , m_timeoutTimer(new QTimer(this))
    , m_currentReply(nullptr)
{
    // 设置超时定时器
    m_timeoutTimer->setSingleShot(true);
    connect(m_timeoutTimer, &QTimer::timeout, this, &ApiClient::onTimeout);
    
    // 连接网络管理器信号
    connect(m_networkManager, &QNetworkAccessManager::finished, this, &ApiClient::onNetworkReplyFinished);
}

ApiClient::~ApiClient()
{
    if (m_currentReply) {
        m_currentReply->deleteLater();
    }
}

void ApiClient::setBaseUrl(const QString &url)
{
    m_baseUrl = url;
    qDebug() << "API Base URL set to:" << m_baseUrl;
}

QString ApiClient::getBaseUrl() const
{
    return m_baseUrl;
}

void ApiClient::scanBarcode(const QString &barcode)
{
    QJsonObject data;
    data["barcode"] = barcode;
    
    makeRequest("/api/scan", data);
}

void ApiClient::getStats()
{
    makeRequest("/api/stats");
}

void ApiClient::checkHealth()
{
    makeRequest("/api/health");
}

void ApiClient::makeRequest(const QString &endpoint, const QJsonObject &data)
{
    // 取消之前的请求
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }
    
    QUrl url(m_baseUrl + endpoint);
    QNetworkRequest request(url);
    
    // 设置请求头
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("User-Agent", "ScanDemo-QT5-Client/1.0");
    
    // 发送请求
    if (data.isEmpty()) {
        // GET 请求
        m_currentReply = m_networkManager->get(request);
    } else {
        // POST 请求
        QJsonDocument doc(data);
        m_currentReply = m_networkManager->post(request, doc.toJson());
    }
    
    // 连接错误信号
    connect(m_currentReply, QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this, &ApiClient::onNetworkError);
    
    // 启动超时定时器
    m_timeoutTimer->start(REQUEST_TIMEOUT_MS);
    
    qDebug() << "Making request to:" << url.toString();
}

void ApiClient::onNetworkReplyFinished()
{
    m_timeoutTimer->stop();
    
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }
    
    handleResponse(reply);
    
    // 清理
    reply->deleteLater();
    if (reply == m_currentReply) {
        m_currentReply = nullptr;
    }
}

void ApiClient::onNetworkError(QNetworkReply::NetworkError error)
{
    m_timeoutTimer->stop();
    
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }
    
    QString errorString = reply->errorString();
    qDebug() << "Network error:" << error << errorString;
    
    handleError(QString("网络错误: %1").arg(errorString));
    
    // 清理
    reply->deleteLater();
    if (reply == m_currentReply) {
        m_currentReply = nullptr;
    }
}

void ApiClient::onTimeout()
{
    if (m_currentReply) {
        m_currentReply->abort();
        handleError("请求超时");
    }
}

void ApiClient::handleResponse(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        handleError(QString("网络错误: %1").arg(reply->errorString()));
        return;
    }
    
    QByteArray data = reply->readAll();
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    
    if (parseError.error != QJsonParseError::NoError) {
        handleError(QString("JSON解析错误: %1").arg(parseError.errorString()));
        return;
    }
    
    QJsonObject response = doc.object();
    bool success = response["success"].toBool();
    QString message = response["message"].toString();
    
    if (!success) {
        handleError(QString("API错误: %1").arg(message));
        return;
    }
    
    // 根据请求类型处理响应
    QString url = reply->url().toString();
    if (url.contains("/api/scan")) {
        QJsonObject scanData = response["data"].toObject();
        emit scanResultReceived(scanData);
        emit responseReceived(QString("扫描成功: %1").arg(message));
    } else if (url.contains("/api/stats")) {
        QJsonObject statsData = response["data"].toObject();
        emit statsReceived(statsData);
        emit responseReceived(QString("统计数据更新: %1").arg(message));
    } else if (url.contains("/api/health")) {
        emit responseReceived(QString("服务健康检查: %1").arg(message));
    } else {
        emit responseReceived(QString("响应: %1").arg(message));
    }
}

void ApiClient::handleError(const QString &error)
{
    qDebug() << "API Error:" << error;
    emit errorOccurred(error);
}
