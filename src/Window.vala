/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Syncher.MainWindow : Gtk.ApplicationWindow {
    public const string ACTION_GROUP_PREFIX = "win";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";
    public const string ACTION_PREFERENCES = "preferences";

    private const ActionEntry[] ACTION_ENTRIES = {
        {ACTION_PREFERENCES, on_action_preferences }
    };


    public MainWindow (Application application) {
        Object (
            application: application
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);
        // var uris = new Gtk.StringList (null);
        // var drop_down = new Gtk.DropDown (uris, null);
        // var volume_monitor = VolumeMonitor.get ();
        // foreach (var mount in volume_monitor.get_mounts ()) {
        //     uris.append (mount.get_default_location ().get_uri ());
        //     var dir = mount.get_default_location ();
        //     var test = File.new_build_filename (dir.get_path (), "test2");
        //     try {
        //         test.create (NONE, null);
        //     } catch (Error e) {
        //         warning ("Failed to creat file: %s", e.message);
        //     }
        // }

        var home_view = new HomeView ();

        var progress_view = new ProgressView ();

        var leaflet = new Adw.Leaflet () {
            can_unfold = false,
            hexpand = true,
            vexpand = true
        };
        leaflet.append (home_view);
        leaflet.append (progress_view);

        child = leaflet;
        default_height = 550;
        default_width = 800;
        title = "Syncher";
        titlebar = new Gtk.Grid () { visible = false };
        present ();

        var syncher_service = SyncherService.get_default ();

        syncher_service.start_sync.connect (() => {
            leaflet.visible_child = progress_view;
        });
    }

    private void on_action_preferences () {
        new PreferencesWindow (this);
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
