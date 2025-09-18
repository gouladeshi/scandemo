#include "statsdisplay.h"
#include "apiclient.h"
#include <QJsonObject>
#include <QDebug>

StatsDisplay::StatsDisplay(ApiClient *apiClient, QObject *parent)
    : QObject(parent)
    , m_apiClient(apiClient)
    , m_team("-")
    , m_shift("-")
    , m_plannedOutput(0)
    , m_currentCount(0)
    , m_completionRate(0.0)
{
    // 连接API客户端的统计数据信号
    connect(m_apiClient, &ApiClient::statsReceived, this, &StatsDisplay::onStatsReceived);
}

void StatsDisplay::refreshStats()
{
    qDebug() << "Refreshing stats...";
    m_apiClient->getStats();
}

void StatsDisplay::onStatsReceived(const QJsonObject &stats)
{
    m_team = stats["team"].toString();
    m_shift = stats["shift_name"].toString();
    m_plannedOutput = stats["planned_output"].toInt();
    m_currentCount = stats["current_count"].toInt();
    m_completionRate = stats["completion_rate"].toDouble();
    
    qDebug() << "Stats updated - Team:" << m_team 
             << "Shift:" << m_shift 
             << "Planned:" << m_plannedOutput 
             << "Current:" << m_currentCount 
             << "Rate:" << m_completionRate;
    
    emit statsUpdated();
}
