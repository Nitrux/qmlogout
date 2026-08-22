#include "sessionmanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QProcess>
#include <QTimer>

#include <pwd.h>
#include <unistd.h>

namespace {
bool usableImage(const QString &path)
{
    const QFileInfo info(path);
    if (!info.isFile() || !info.isReadable())
        return false;
    QImageReader reader(path);
    reader.setDecideFormatFromContent(true);
    return reader.canRead();
}
}

SessionManager::SessionManager(const QString &avatarOverride,
                               const QString &iconMode,
                               bool showUptime,
                               QObject *parent)
    : QObject(parent)
    , m_iconMode(iconMode.trimmed().toLower() == QStringLiteral("nerd")
                     ? QStringLiteral("nerd") : QStringLiteral("system"))
    , m_showUptime(showUptime)
{
    const passwd *entry = getpwuid(getuid());
    const QString username = entry ? QString::fromLocal8Bit(entry->pw_name)
                                   : QString::fromLocal8Bit(qgetenv("USER"));
    const QString home = entry ? QString::fromLocal8Bit(entry->pw_dir) : QDir::homePath();
    m_realName = entry ? QString::fromLocal8Bit(entry->pw_gecos).section(QLatin1Char(','), 0, 0).trimmed() : username;
    if (m_realName.isEmpty())
        m_realName = username;

    QString configured = avatarOverride.trimmed();
    configured.replace(QStringLiteral("%u"), username);
    configured.replace(QStringLiteral("%h"), home);
    const QStringList candidates{
        configured,
        home + QStringLiteral("/.face"),
        home + QStringLiteral("/.face.icon"),
        QStringLiteral("/var/lib/AccountsService/icons/") + username
    };
    m_avatarPath = QStringLiteral("qrc:/icons/user-avatar.svg");
    for (const QString &candidate : candidates) {
        if (usableImage(candidate)) {
            m_avatarPath = candidate;
            break;
        }
    }

    if (m_showUptime) {
        updateUptime();
        m_uptimeTimer = new QTimer(this);
        m_uptimeTimer->setInterval(1000);
        connect(m_uptimeTimer, &QTimer::timeout, this, &SessionManager::updateUptime);
        m_uptimeTimer->start();
    }
}

QUrl SessionManager::avatarUrl() const
{
    return m_avatarPath.startsWith(QStringLiteral("qrc:"))
        ? QUrl(m_avatarPath) : QUrl::fromLocalFile(m_avatarPath);
}

void SessionManager::updateUptime()
{
    QFile uptimeFile(QStringLiteral("/proc/uptime"));
    if (!uptimeFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return;
    bool ok = false;
    const qint64 totalSeconds = static_cast<qint64>(uptimeFile.readLine().split(' ').value(0).toDouble(&ok));
    if (!ok)
        return;
    const qint64 days = totalSeconds / 86400;
    const qint64 hours = (totalSeconds % 86400) / 3600;
    const qint64 minutes = (totalSeconds % 3600) / 60;
    const qint64 seconds = totalSeconds % 60;
    const QString value = days > 0
        ? QStringLiteral("%1d %2h %3m").arg(days).arg(hours).arg(minutes)
        : QStringLiteral("%1:%2:%3").arg(hours, 2, 10, QLatin1Char('0')).arg(minutes, 2, 10, QLatin1Char('0')).arg(seconds, 2, 10, QLatin1Char('0'));
    if (m_uptime != value) {
        m_uptime = value;
        emit uptimeChanged();
    }
}

void SessionManager::shutdown()
{
    startWithFallback(QStringLiteral("shutdown"), QStringLiteral("/usr/bin/loginctl"),
                      {QStringLiteral("poweroff")}, QStringLiteral("/sbin/poweroff"));
}

void SessionManager::reboot()
{
    startWithFallback(QStringLiteral("reboot"), QStringLiteral("/usr/bin/loginctl"),
                      {QStringLiteral("reboot")}, QStringLiteral("/sbin/reboot"));
}

void SessionManager::suspend()
{
    start(QStringLiteral("suspend"), QStringLiteral("/usr/bin/loginctl"),
          {QStringLiteral("suspend")});
}

void SessionManager::hibernate()
{
    start(QStringLiteral("hibernate"), QStringLiteral("/usr/bin/loginctl"),
          {QStringLiteral("hibernate")});
}

void SessionManager::logout()
{
    start(QStringLiteral("logout"), QStringLiteral("/usr/bin/hyprctl"),
          {QStringLiteral("dispatch"), QStringLiteral("exit")});
}

void SessionManager::lock()
{
    start(QStringLiteral("lock"), QStringLiteral("/usr/bin/desklock"), {});
}

bool SessionManager::startWithFallback(const QString &action, const QString &program,
                                       const QStringList &arguments,
                                       const QString &fallbackProgram)
{
    if (start(action, program, arguments))
        return true;

    return start(action, fallbackProgram, {});
}

bool SessionManager::start(const QString &action, const QString &program,
                           const QStringList &arguments)
{
    const QFileInfo executable(program);
    if (!executable.isFile() || !executable.isExecutable()) {
        emit actionFailed(action, tr("Command not found: %1").arg(program));
        return false;
    }

    if (!QProcess::startDetached(program, arguments)) {
        emit actionFailed(action, tr("Could not start: %1").arg(program));
        return false;
    }

    return true;
}
