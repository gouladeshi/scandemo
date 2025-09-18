#ifndef BARCODESCANNER_H
#define BARCODESCANNER_H

#include <QObject>
#include <QString>

class ApiClient;

class BarCodeScanner : public QObject
{
    Q_OBJECT

public:
    explicit BarCodeScanner(ApiClient *apiClient, QObject *parent = nullptr);
    
    void scanBarcode(const QString &barcode);

signals:
    void scanCompleted(bool success, const QString &message, int currentCount);
    void scanError(const QString &error);

private slots:
    void onScanResultReceived(const QJsonObject &result);

private:
    ApiClient *m_apiClient;
};

#endif // BARCODESCANNER_H
