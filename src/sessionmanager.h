// SPDX-License-Identifier: BSD-3-Clause
// Copyright 2026 Nitrux Latinoamericana S.C. <hello@nxos.org>

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>

class QTimer;

class SessionManager final : public QObject
{
    Q_OBJECT

public:
    explicit SessionManager(const QString &avatarOverride = {},
                      const QString &iconMode = QStringLiteral("system"),
                      bool showUptime = true,
                      QObject *parent = nullptr);

    Q_PROPERTY(QString realName READ realName CONSTANT)
    Q_PROPERTY(QUrl avatarUrl READ avatarUrl CONSTANT)
    Q_PROPERTY(QString uptime READ uptime NOTIFY uptimeChanged)
    Q_PROPERTY(bool showUptime READ showUptime CONSTANT)
    Q_PROPERTY(QString iconMode READ iconMode CONSTANT)
    Q_PROPERTY(bool canSuspend READ canSuspend CONSTANT)
    Q_PROPERTY(bool canHibernate READ canHibernate CONSTANT)

    QString realName() const { return m_realName; }
    QUrl avatarUrl() const;
    QString uptime() const { return m_uptime; }
    bool showUptime() const { return m_showUptime; }
    QString iconMode() const { return m_iconMode; }
    bool canSuspend() const { return m_canSuspend; }
    bool canHibernate() const { return m_canHibernate; }

    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void reboot();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void lock();

signals:
    void uptimeChanged();
    void actionFailed(const QString &action, const QString &error);

private:
    void updateUptime();

    bool start(const QString &action, const QString &program,
               const QStringList &arguments);

    QString m_realName;
    QString m_avatarPath;
    QString m_uptime;
    QString m_iconMode;
    bool m_showUptime = true;
    bool m_canSuspend = false;
    bool m_canHibernate = false;
    QTimer *m_uptimeTimer = nullptr;
    bool startWithFallback(const QString &action, const QString &program,
                           const QStringList &arguments,
                           const QString &fallbackProgram);
};
