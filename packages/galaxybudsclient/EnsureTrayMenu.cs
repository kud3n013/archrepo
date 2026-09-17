using System;
using System.Reflection;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Threading;
using GalaxyBudsClient.Scripting.Hooks;
using Serilog;

public class EnsureTrayMenu : IHook
{
    public void OnHooked()
    {
        Log.Information("[EnsureTrayMenu] Hook registered; initializing tray menu with Open and Quit items");
        Task.Run(async () =>
        {
            // Allow UI and MainWindow initialization to finish
            await Task.Delay(500);
            await Dispatcher.UIThread.InvokeAsync(async () =>
            {
                await RebuildAndEnsureQuit();
            });
        });
    }

    private static async Task RebuildAndEnsureQuit()
    {
        try
        {
            // 1. Invoke upstream TrayManager.Instance.RebuildAsync() via reflection
            // By default, upstream only rebuilds the tray menu if a valid device is already paired.
            // Invoking it here ensures the tray menu (Open, status, Quit) is populated unconditionally on launch.
            var asm = typeof(GalaxyBudsClient.App).Assembly;
            var tmType = asm.GetType("GalaxyBudsClient.Utils.Interface.TrayManager");
            if (tmType != null)
            {
                var instProp = tmType.GetProperty("Instance", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
                var inst = instProp?.GetValue(null);
                var rebuildMethod = tmType.GetMethod("RebuildAsync", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
                if (inst != null && rebuildMethod != null)
                {
                    var task = (Task)rebuildMethod.Invoke(inst, null);
                    if (task != null)
                    {
                        await task;
                    }
                }
            }

            // 2. Double-check that a Quit option is present in TrayMenu
            var app = Application.Current as GalaxyBudsClient.App;
            if (app != null && app.TrayMenu != null)
            {
                bool hasQuit = false;
                foreach (var item in app.TrayMenu.Items)
                {
                    if (item is NativeMenuItem nmi && nmi.Header?.ToString().IndexOf("Quit", StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        hasQuit = true;
                        break;
                    }
                }

                if (!hasQuit)
                {
                    var quitItem = new NativeMenuItem("Quit");
                    quitItem.Click += (s, e) =>
                    {
                        Log.Information("[EnsureTrayMenu] Quit selected from tray menu");
                        Environment.Exit(0);
                    };
                    app.TrayMenu.Items.Add(quitItem);
                }
            }
        }
        catch (Exception ex)
        {
            Log.Error(ex, "[EnsureTrayMenu] Error ensuring tray menu options");
        }
    }

    public void OnUnhooked()
    {
    }
}
