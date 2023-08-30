/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Syncher.MainWindow : Gtk.ApplicationWindow {
    public MainWindow (Application application) {
        Object (
            application: application
        );
    }

    construct {
        var headerbar = new Gtk.HeaderBar () {
            show_title_buttons = true
        };

        var uris = new Gtk.StringList (null);
        var drop_down = new Gtk.DropDown (uris, null);
        var export = new Gtk.Button.with_label ("Export");
        var import = new Gtk.Button.with_label ("Import");
        var sync = new Gtk.Button.with_label ("Sync");
        var box = new Gtk.Box (VERTICAL, 12);
        box.append (drop_down);
        box.append (export);
        box.append (import);
        box.append (sync);
        box.append (new ProgressWidget ());
        var volume_monitor = VolumeMonitor.get ();
        foreach (var mount in volume_monitor.get_mounts ()) {
            uris.append (mount.get_default_location ().get_uri ());
            var dir = mount.get_default_location ();
            var test = File.new_build_filename (dir.get_path (), "test2");
            try {
                test.create (NONE, null);
            } catch (Error e) {
                warning ("Failed to creat file: %s", e.message);
            }
        }

        child = box;
        default_height = 300;
        default_width = 300;
        title = "MyApp";
        titlebar = headerbar;
        present ();

        export.clicked.connect (get_location);
        import.clicked.connect (get_import_location);
        sync.clicked.connect (get_sync_location);
    }

    private void get_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", this, SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                SyncherService.get_default ().export.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }

    private void get_import_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", this, SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                SyncherService.get_default ().import.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }

    private void get_sync_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", this, SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                SyncherService.get_default ().sync.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }
}
