// Global menu for Free Download Manager, loaded by libfdm-globalmenu.so.
//
// It is created in the context of FDM's main window (qrc:/qml_ui/desktop/Main.qml),
// so the ids used below (appWindow, buildDownloadDlg, selectedDownloadsTools,
// importDlg, shutdownTools, ...) are the ones Main.qml declares. Each action
// mirrors the in-app main menu (MainMenu.qml) or toolbar (MainToolbar.qml), and
// the labels go through qsTranslate() with those files' contexts so they use
// FDM's own translations.
//
// No shortcuts are set: a native menu item with a shortcut also grabs it, which
// would make FDM's own Ctrl+N / Ctrl+V / Ctrl+A ambiguous and turn them off.

import QtQuick
import Qt.labs.platform as QtLabs
import org.freedownloadmanager.fdm
import org.freedownloadmanager.vmsqt
import org.freedownloadmanager.fdm.appfeatures

QtLabs.MenuBar {
    id: root

    window: appWindow

    readonly property bool rcActive: App.rc.client.active
    readonly property var power: shutdownTools.powerManagement
    readonly property bool shutdownArmed: !!power && power.shutdownComputerWhenDownloadsFinished

    function tr(context, text) {
        return qsTranslate(context, text) + App.loc.emptyString;
    }

    // Close FDM's own popup menu if it is open, as upstream's NativeMenuBar does.
    function run(action) {
        appWindow.nativeMenuItemTriggered();
        action();
    }

    function toggleShutdown(type) {
        let on = !(root.shutdownArmed && root.power.shutdownType == type);
        shutdownTools.setShutdownType(type, on);
    }

    QtLabs.Menu {
        title: root.tr("NativeMenuBar", "&File")

        QtLabs.MenuItem {
            text: root.tr("MainToolbar", "Add new download...")
            onTriggered: root.run(() => buildDownloadDlg.newDownload())
        }
        QtLabs.MenuItem {
            text: root.tr("MainMenu", "Paste urls from clipboard")
            enabled: !!App.clipboard.text.trim()
            onTriggered: root.run(() => App.pasteUrlsFromClipboard())
        }
        QtLabs.MenuItem {
            text: root.tr("MainMenu", "Paste urls from file")
            onTriggered: root.run(() => importDlg.openDialog('importListOfUrlsFromFile'))
        }
        QtLabs.MenuSeparator { visible: !root.rcActive }
        QtLabs.MenuItem {
            visible: !root.rcActive
            text: root.tr("MainMenu", "Export all downloads")
            onTriggered: root.run(() => exportDownloadsDlg.exportAll())
        }
        QtLabs.MenuItem {
            visible: !root.rcActive
            text: root.tr("MainMenu", "Import downloads")
            onTriggered: root.run(() => importDlg.openDialog('importDownloads'))
        }
        QtLabs.MenuSeparator {
            visible: App.features.hasFeature(AppFeatures.RemoteControlClient) || appWindow.portableSupported
        }
        QtLabs.MenuItem {
            visible: App.features.hasFeature(AppFeatures.RemoteControlClient)
            text: root.rcActive
                  ? root.tr("MainMenu", "Disconnect from remote %1").arg(App.shortDisplayName)
                  : root.tr("MainMenu", "Connect to remote %1").arg(App.shortDisplayName)
            onTriggered: root.run(() => {
                if (App.rc.client.active)
                    App.rc.client.disconnectFromRemoteApp();
                else
                    connectToRemoteAppDlg.open();
            })
        }
        QtLabs.MenuItem {
            visible: appWindow.portableSupported
            text: root.tr("MainMenu", "Create portable version")
            onTriggered: root.run(() => createPortableDlg.open())
        }
        QtLabs.MenuSeparator {}
        QtLabs.MenuItem {
            text: root.tr("MainMenu", "Quit")
            onTriggered: App.quit()
        }
    }

    QtLabs.Menu {
        title: root.tr("NativeMenuBar", "Downloads")

        QtLabs.MenuItem {
            text: root.tr("MainToolbar", "Start all")
            enabled: selectedDownloadsTools.downloadsToStartExist
            onTriggered: root.run(() => App.downloads.mgr.startAllDownloads())
        }
        QtLabs.MenuItem {
            text: root.tr("MainToolbar", "Pause all")
            enabled: selectedDownloadsTools.downloadsToStopExist
            onTriggered: root.run(() => {
                App.downloads.mgr.stopAllDownloads(true);
                let ids = App.downloads.tracker.runningIdsWithNoResumeSupport();
                if (ids.length)
                    appWindow.stopDownload(ids);
            })
        }
        QtLabs.MenuItem {
            visible: appWindow.btSupported && !!appWindow.btS &&
                     App.downloads.tracker.hasPostFinishedTasksDownloadsCount
            text: appWindow.btS ? appWindow.btS.startAllSeedingDownloadsUiText + App.loc.emptyString : ""
            enabled: App.downloads.tracker.finishedHasDisabledPostFinishedTasks
            onTriggered: root.run(() => App.downloads.mgr.startAllDownloadsWithPostFinishedTasks())
        }
        QtLabs.MenuItem {
            visible: appWindow.btSupported && !!appWindow.btS &&
                     App.downloads.tracker.hasPostFinishedTasksDownloadsCount
            text: appWindow.btS ? appWindow.btS.stopAllSeedingDownloadsUiText + App.loc.emptyString : ""
            enabled: App.downloads.tracker.finishedHasEnabledPostFinishedTasks
            onTriggered: root.run(() => App.downloads.mgr.stopAllDownloadsWithPostFinishedTasks())
        }
        QtLabs.MenuSeparator {}
        QtLabs.MenuItem {
            text: root.tr("NativeMenuBar", "Start selected")
            enabled: selectedDownloadsTools.checkedDownloadsToStartExist
            onTriggered: root.run(() => selectedDownloadsTools.startCheckedDownloads())
        }
        QtLabs.MenuItem {
            text: root.tr("NativeMenuBar", "Pause selected")
            enabled: selectedDownloadsTools.checkedDownloadsToStopExist
            onTriggered: root.run(() => selectedDownloadsTools.stopCheckedDownloads())
        }
        QtLabs.MenuItem {
            text: root.tr("NativeMenuBar", "Restart selected")
            enabled: selectedDownloadsTools.checkedDownloadsCount > 0
            onTriggered: root.run(() => selectedDownloadsTools.restartCheckedDownloads())
        }
        QtLabs.MenuItem {
            visible: !root.rcActive
            text: root.tr("MainToolbar", "Move to...")
            enabled: selectedDownloadsTools.currentDownloadId > 0
            onTriggered: root.run(() => movingFolderDlg.openForIds(selectedDownloadsTools.getCurrentDownloadIds()))
        }
        QtLabs.MenuSeparator {}
        QtLabs.MenuItem {
            text: root.tr("NativeMenuBar", "Remove from List")
            enabled: selectedDownloadsTools.checkedDownloadsCount > 0
            onTriggered: root.run(() => selectedDownloadsTools.removeCheckedFromList())
        }
        QtLabs.MenuItem {
            text: root.tr("MainToolbar", "Delete selected")
            enabled: selectedDownloadsTools.currentDownloadId > 0
            onTriggered: root.run(() => selectedDownloadsTools.removeCurrentDownloads())
        }
        QtLabs.MenuSeparator {}
        QtLabs.MenuItem {
            text: root.tr("DownloadsList", "Select all")
            onTriggered: root.run(() => selectedDownloadsTools.checkAll(true))
        }
    }

    QtLabs.Menu {
        title: root.tr("SettingsPage", "Settings")

        QtLabs.MenuItem {
            visible: !root.rcActive
            text: root.tr("MainMenu", "Preferences...")
            onTriggered: root.run(() => appWindow.openSettings())
        }
        QtLabs.MenuItem {
            visible: App.features.hasFeature(AppFeatures.Plugins) && !root.rcActive
            text: root.tr("MainMenu", "Add-ons...")
            onTriggered: root.run(() => appWindow.openPlugins())
        }
        QtLabs.MenuSeparator { visible: !root.rcActive }
        QtLabs.MenuItem {
            visible: !root.rcActive
            text: root.tr("MainMenu", "Export settings")
            onTriggered: root.run(() => exportSettingsDlg.open())
        }
        QtLabs.MenuItem {
            visible: !root.rcActive
            text: root.tr("MainMenu", "Import settings")
            onTriggered: root.run(() => importDlg.openDialog('importSettings'))
        }
        QtLabs.MenuSeparator { visible: appWindow.supportComputerShutdown }
        QtLabs.Menu {
            visible: appWindow.supportComputerShutdown
            enabled: !!root.power &&
                     (App.downloads.tracker.nonFinishedDownloadsRunning || root.shutdownArmed)
            title: root.tr("MainMenu", "Auto shutdown")

            QtLabs.MenuItem {
                text: root.tr("MainMenu", "Sleep")
                checkable: true
                checked: root.shutdownArmed && root.power.shutdownType == VmsQt.SuspendComputer
                onTriggered: root.toggleShutdown(VmsQt.SuspendComputer)
            }
            QtLabs.MenuItem {
                text: root.tr("MainMenu", "Shutdown")
                checkable: true
                checked: root.shutdownArmed && root.power.shutdownType == VmsQt.ShutdownComputer
                onTriggered: root.toggleShutdown(VmsQt.ShutdownComputer)
            }
        }
    }

    QtLabs.Menu {
        title: root.tr("NativeMenuBar", "Help")

        QtLabs.MenuItem {
            text: root.tr("MainMenu", "Contact support")
            onTriggered: root.run(() => Qt.openUrlExternally('https://www.freedownloadmanager.org/support.htm?' + App.serverCommonGetParameters))
        }
        QtLabs.MenuItem {
            visible: App.features.hasFeature(AppFeatures.SubmitBugReport)
            text: root.tr("MainMenu", "Submit a bug report")
            onTriggered: root.run(() => submitBugReportDlg.open())
        }
        QtLabs.MenuSeparator { visible: appWindow.updateSupported }
        QtLabs.MenuItem {
            visible: appWindow.updateSupported
            text: root.tr("MainMenu", "Check for updates...")
            onTriggered: root.run(() => appWindow.checkForUpdatesRequested())
        }
        QtLabs.MenuSeparator {}
        QtLabs.MenuItem {
            text: root.tr("MainMenu", "About")
            onTriggered: root.run(() => aboutDlg.open())
        }
    }

    // On Wayland a hidden window loses its surface, and with it the appmenu
    // address KWin knows about. Re-attaching makes Qt register the menu again.
    property Connections _reattach: Connections {
        target: appWindow
        function onVisibleChanged() {
            if (appWindow.visible) {
                root.window = null;
                root.window = appWindow;
            }
        }
    }
}
