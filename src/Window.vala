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

    private ErrorView error_view;
    private ProgressView progress_view;
    private Adw.Leaflet leaflet;

    public MainWindow (Application application) {
        Object (
            application: application
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        var syncher_service = SyncherService.get_default ();

        error_view = new ErrorView ();

        var home_view = new HomeView ();

        progress_view = new ProgressView ();

        leaflet = new Adw.Leaflet () {
            can_unfold = false,
            hexpand = true,
            vexpand = true
        };

        child = leaflet;
        default_height = 550;
        default_width = 800;
        title = "Syncher";
        titlebar = new Gtk.Grid () { visible = false };
        present ();

        var size_group = new Gtk.SizeGroup (VERTICAL);
        size_group.add_widget (error_view.header_bar);
        size_group.add_widget (home_view.header_bar);
        size_group.add_widget (progress_view.header_bar);

        if (settings.get_string ("sync-location") == "") {
            var welcome_view = new WelcomeView ();
            leaflet.append (welcome_view);
            welcome_view.finished.connect (() => {
                leaflet.append (home_view);
                SyncherService.get_default ().setup_saved_synchronization ();
                leaflet.remove (welcome_view);
            });
        } else {
            leaflet.append (home_view);
        }

        update_working_state ();
        syncher_service.notify["working"].connect (update_working_state);

        update_error_state ();
        syncher_service.notify["error-state"].connect (update_error_state);

        leaflet.notify["visible-child"].connect (() => {
            if (leaflet.get_adjacent_child (FORWARD) != null) {
                leaflet.remove (leaflet.get_adjacent_child (FORWARD));
            }
        });
    }

    private void on_action_preferences () {
        new PreferencesWindow (this);
    }

    private void update_working_state () {
        if (SyncherService.get_default ().working) {
            if (progress_view.parent == null) {
                leaflet.append (progress_view);
            }

            leaflet.visible_child = progress_view;
        }
    }

    private void update_error_state () {
        if (SyncherService.get_default ().error_state != null) {
            if (error_view.parent == null) {
                leaflet.append (error_view);
            }

            leaflet.visible_child = error_view;
        }
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
