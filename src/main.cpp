// SPDX-License-Identifier: BSD-3-Clause
// Copyright 2026 Nitrux Latinoamericana S.C. <hello@nxos.org>

#include <QGuiApplication>
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QWindow>

#include <cstdlib>

#include <LayerShellQt/Window>

#include "sessionmanager.h"

namespace {
QString ensureConfigurationFile()
{
    const QString configDirectory = QStandardPaths::writableLocation(
        QStandardPaths::ConfigLocation) + QStringLiteral("/qmlogout");
    const QString configPath = configDirectory + QStringLiteral("/qmlogout.conf");

    if (QFile::exists(configPath))
        return configPath;

    if (!QDir().mkpath(configDirectory))
        return {};

    QFile defaults(QStringLiteral(":/config/qmlogout.conf"));
    if (!defaults.open(QIODevice::ReadOnly))
        return {};

    QSaveFile config(configPath);
    if (!config.open(QIODevice::WriteOnly)
        || config.write(defaults.readAll()) < 0
        || !config.commit()) {
        return {};
    }

    return configPath;
}

void configureLayerShellWindow(QWindow *window)
{
    if (!window)
        return;

    auto *layerWindow = LayerShellQt::Window::get(window);
    if (!layerWindow)
        return;

    layerWindow->setScope(QStringLiteral("org.maui.qmlogout"));
    layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
    layerWindow->setKeyboardInteractivity(
        LayerShellQt::Window::KeyboardInteractivityExclusive);
    layerWindow->setExclusiveZone(-1);

    LayerShellQt::Window::Anchors anchors;
    anchors |= LayerShellQt::Window::AnchorTop;
    anchors |= LayerShellQt::Window::AnchorBottom;
    anchors |= LayerShellQt::Window::AnchorLeft;
    anchors |= LayerShellQt::Window::AnchorRight;
    layerWindow->setAnchors(anchors);
    layerWindow->setDesiredSize(QSize(0, 0));
    layerWindow->setMargins(QMargins(0, 0, 0, 0));
}
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle(QStringLiteral("org.mauikit.style"));
    app.setApplicationName(QStringLiteral("qmlogout"));
    app.setApplicationDisplayName(QStringLiteral("QMLogout"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));
    app.setQuitOnLastWindowClosed(false);

    const QString configPath = ensureConfigurationFile();
    if (configPath.isEmpty())
        return EXIT_FAILURE;

    QSettings config(configPath, QSettings::IniFormat);
    const double overlayOpacity = qBound(
        0.0, config.value(QStringLiteral("Appearance/OverlayOpacity"), 0.76).toDouble(), 1.0);
    const QString iconMode = config.value(QStringLiteral("Appearance/IconMode"),
                                           QStringLiteral("system")).toString();
    const QString avatarOverride = config.value(QStringLiteral("Appearance/AvatarImage"))
                                       .toString();
    const bool showUptime = config.value(QStringLiteral("SystemUptime/ShowUptime"), true)
                                .toBool();
    const int actionTimeout = qBound(1,
        config.value(QStringLiteral("Session/ActionTimeout"), 30).toInt(), 120);

    SessionManager sessionManager(avatarOverride, iconMode, showUptime);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("OverlayOpacity"),
                                             overlayOpacity);
    engine.rootContext()->setContextProperty(QStringLiteral("ActionTimeout"),
                                             actionTimeout);
    engine.rootContext()->setContextProperty(QStringLiteral("sessionManager"),
                                             &sessionManager);

    const QUrl url(QStringLiteral("qrc:/app/qmlogout/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *object, const QUrl &objectUrl) {
        if (!object && objectUrl == url)
            QCoreApplication::exit(EXIT_FAILURE);
    }, Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty())
        return EXIT_FAILURE;

    auto *window = qobject_cast<QWindow *>(engine.rootObjects().constFirst());
    configureLayerShellWindow(window);
    if (window)
        window->show();

    return app.exec();
}
