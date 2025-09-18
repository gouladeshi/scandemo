#ifndef STATSDISPLAY_H
#define STATSDISPLAY_H

#include <QObject>
#include <QString>

class ApiClient;

class StatsDisplay : public QObject
{
    Q_OBJECT

public:
    explicit StatsDisplay(ApiClient *apiClient, QObject *parent = nullptr);
    
    void refreshStats();
    
    // 获取当前统计数据
    QString getTeam() const { return m_team; }
    QString getShift() const { return m_shift; }
    int getPlannedOutput() const { return m_plannedOutput; }
    int getCurrentCount() const { return m_currentCount; }
    double getCompletionRate() const { return m_completionRate; }

signals:
    void statsUpdated();
    void statsError(const QString &error);

private slots:
    void onStatsReceived(const QJsonObject &stats);

private:
    ApiClient *m_apiClient;
    
    // 统计数据
    QString m_team;
    QString m_shift;
    int m_plannedOutput;
    int m_currentCount;
    double m_completionRate;
};

#endif // STATSDISPLAY_H
