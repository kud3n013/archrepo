// Global menu for Free Download Manager.
//
// FDM ships a Qt.labs.platform MenuBar (NativeMenuBar.qml) but only loads it
// on macOS, and Main.qml has even that commented out. This library is added to
// the fdm binary's DT_NEEDED list. Once FDM's main window exists it loads
// GlobalMenuBar.qml into the window's own QML context, so the menu can call the
// same ids and functions as FDM's in-app menu. Qt then exports the menu through
// com.canonical.AppMenu.Registrar (X11) or the KDE appmenu protocol (Wayland).
//
// Only public Qt API and no moc, so the library works with the Qt that FDM
// bundles in /opt/freedownloadmanager/lib. FDM_GLOBALMENU=0 turns it off.

#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QTimer>
#include <QtCore/QUrl>
#include <QtGui/QGuiApplication>
#include <QtGui/QWindow>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQml/qqml.h>

namespace {

constexpr int kPollIntervalMs = 250;
constexpr int kMaxPolls = 4 * 60 * 5; // the main window shows up within seconds; give up after 5 minutes

QString menuFile()
{
    const QString path = qEnvironmentVariable("FDM_GLOBALMENU_QML");
    return path.isEmpty() ? QStringLiteral("/usr/share/fdm/GlobalMenuBar.qml") : path;
}

// Returns true once there is nothing left to do: the menu is attached, or it failed for good.
bool attachMenu()
{
    const auto windows = QGuiApplication::topLevelWindows();
    for (QWindow *window : windows) {
        QQmlContext *context = qmlContext(window);
        if (!context || context->nameForObject(window) != QLatin1String("appWindow"))
            continue;

        const QString path = menuFile();
        if (!QFileInfo::exists(path)) {
            qWarning("fdm-globalmenu: %s not found", qPrintable(path));
            return true;
        }

        QQmlComponent component(context->engine(), QUrl::fromLocalFile(path));
        QObject *menuBar = component.create(context);
        if (!menuBar) {
            qWarning() << "fdm-globalmenu:" << component.errors();
            return true;
        }
        menuBar->setParent(window);
        return true;
    }
    return false;
}

void startGlobalMenu()
{
    if (qEnvironmentVariable("FDM_GLOBALMENU") == QLatin1String("0"))
        return;
    // FDM also runs helper processes; only a GUI process has a window to attach to
    if (!qobject_cast<QGuiApplication *>(QCoreApplication::instance()))
        return;

    auto *timer = new QTimer(QCoreApplication::instance());
    timer->setInterval(kPollIntervalMs);
    QObject::connect(timer, &QTimer::timeout, timer, [timer, polls = 0]() mutable {
        if (attachMenu() || ++polls >= kMaxPolls) {
            timer->stop();
            timer->deleteLater();
        }
    });
    timer->start();
}

} // namespace

Q_COREAPP_STARTUP_FUNCTION(startGlobalMenu)
