/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

namespace Syncher {
    private Settings settings;
}

public class Syncher.Application : Gtk.Application {
    public Application () {
        Object (
            application_id: "io.github.leolost2605.syncher",
            flags: ApplicationFlags.FLAGS_NONE
        );

        settings = new Settings ("io.github.leolost2605.syncher");
    }

    protected override void activate () {
        // Adw.init ();
        var main_window = new MainWindow (this);
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
