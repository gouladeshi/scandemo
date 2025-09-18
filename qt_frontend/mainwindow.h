#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTimer>
#include <memory>

QT_BEGIN_NAMESPACE
class QVBoxLayout;
class QHBoxLayout;
class QGridLayout;
class QLabel;
class QLineEdit;
class QPushButton;
class QTextEdit;
class QGroupBox;
class QProgressBar;
QT_END_NAMESPACE

class BarCodeScanner;
class StatsDisplay;
class ApiClient;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onScanButtonClicked();
    void onClearButtonClicked();
    void onRefreshStats();
    void onApiResponseReceived(const QString &response);
    void onApiError(const QString &error);
    void onStatsUpdated();

private:
    void setupUI();
    void setupConnections();
    void updateStatsDisplay();
    void logMessage(const QString &message, const QString &type = "INFO");

    // UI 组件
    QWidget *m_centralWidget;
    QVBoxLayout *m_mainLayout;
    
    // 统计显示区域
    QGroupBox *m_statsGroup;
    QGridLayout *m_statsLayout;
    QLabel *m_teamLabel;
    QLabel *m_shiftLabel;
    QLabel *m_plannedLabel;
    QLabel *m_currentLabel;
    QProgressBar *m_progressBar;
    
    // 扫码区域
    QGroupBox *m_scanGroup;
    QVBoxLayout *m_scanLayout;
    QLineEdit *m_barcodeInput;
    QPushButton *m_scanButton;
    QPushButton *m_clearButton;
    
    // 日志区域
    QGroupBox *m_logGroup;
    QVBoxLayout *m_logLayout;
    QTextEdit *m_logDisplay;
    QPushButton *m_refreshButton;
    
    // 业务逻辑组件
    std::unique_ptr<BarCodeScanner> m_scanner;
    std::unique_ptr<StatsDisplay> m_statsDisplay;
    std::unique_ptr<ApiClient> m_apiClient;
    
    // 定时器
    QTimer *m_statsTimer;
    
    // 当前统计数据
    QString m_currentTeam;
    QString m_currentShift;
    int m_plannedOutput;
    int m_currentCount;
    double m_completionRate;
};

#endif // MAINWINDOW_H
