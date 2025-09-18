#ifndef APICLIENT_H
#define APICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>

class ApiClient : public QObject
{
    Q_OBJECT

public:
    explicit ApiClient(QObject *parent = nullptr);
    ~ApiClient();

    void setBaseUrl(const QString &url);
    QString getBaseUrl() const;
    
    // API 方法
    void scanBarcode(const QString &barcode);
    void getStats();
    void checkHealth();

signals:
    void responseReceived(const QString &response);
    void errorOccurred(const QString &error);
    void statsReceived(const QJsonObject &stats);
    void scanResultReceived(const QJsonObject &result);

private slots:
    void onNetworkReplyFinished();
    void onNetworkError(QNetworkReply::NetworkError error);
    void onTimeout();

private:
    void makeRequest(const QString &endpoint, const QJsonObject &data = QJsonObject());
    void handleResponse(QNetworkReply *reply);
    void handleError(const QString &error);

    QNetworkAccessManager *m_networkManager;
    QString m_baseUrl;
    QTimer *m_timeoutTimer;
    QNetworkReply *m_currentReply;
    
    static const int REQUEST_TIMEOUT_MS = 10000; // 10秒超时
};

#endif // APICLIENT_H
