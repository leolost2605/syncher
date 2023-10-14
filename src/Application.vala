/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

namespace Syncher {
    private Settings settings;
}

public class Syncher.Application : Gtk.Application {
    private const OptionEntry[] OPTIONS = {
        { "background", 'b', 0, OptionArg.NONE, out run_in_background, "Run the Application in background", null},
        { null }
    };

    public static bool run_in_background;

    private MainWindow? main_window = null;

    public Application () {
        Object (
            application_id: "io.github.leolost2605.syncher",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        settings = new Settings ("io.github.leolost2605.syncher");
        add_main_option_entries (OPTIONS);
    }

    protected override void startup () {
        base.startup ();
        // Adw.init ();
        hold ();
    }

    protected override void activate () {
        if (run_in_background) {
            run_in_background = false;
            request_background.begin ();
            return;
        }

        if (main_window == null) {
            main_window = new MainWindow (this);
        } else {
            main_window.present ();
        }
    }

    public bool is_running_in_background () {
        return main_window == null;
    }

    public async void request_background () {
        var portal = new Xdp.Portal ();

        Xdp.Parent? parent = active_window != null ? Xdp.parent_new_gtk (active_window) : null;

        var command = new GenericArray<weak string> ();
        command.add ("io.github.leolost2605.syncher");
        command.add ("--background");

        try {
            if (!yield portal.request_background (
                parent,
                _("Syncher will automatically start when this device turns on and run when its window is closed so that it can keep it up to date."),
                (owned) command,
                Xdp.BackgroundFlags.AUTOSTART,
                null
            )) {
                release ();
            }
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                debug ("Request for autostart and background permissions denied: %s", e.message);
                release ();
            } else {
                warning ("Failed to request autostart and background permissions: %s", e.message);
            }
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
