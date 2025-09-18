#include "barcodescanner.h"
#include "apiclient.h"
#include <QJsonObject>
#include <QDebug>

BarCodeScanner::BarCodeScanner(ApiClient *apiClient, QObject *parent)
    : QObject(parent)
    , m_apiClient(apiClient)
{
    // 连接API客户端的扫描结果信号
    connect(m_apiClient, &ApiClient::scanResultReceived, this, &BarCodeScanner::onScanResultReceived);
}

void BarCodeScanner::scanBarcode(const QString &barcode)
{
    if (barcode.isEmpty()) {
        emit scanError("条码不能为空");
        return;
    }
    
    qDebug() << "Scanning barcode:" << barcode;
    m_apiClient->scanBarcode(barcode);
}

void BarCodeScanner::onScanResultReceived(const QJsonObject &result)
{
    bool success = result["success"].toBool();
    QString message = result["message"].toString();
    int currentCount = result["current_count"].toInt();
    
    qDebug() << "Scan result - Success:" << success << "Message:" << message << "Count:" << currentCount;
    
    emit scanCompleted(success, message, currentCount);
}
