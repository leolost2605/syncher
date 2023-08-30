/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class MyApp : Gtk.Application {
    private const string INSTALLED_FLATPAKS_FILE_NAME = ".installed-flatpaks";
    private const string DCONF_CONFIG_FILE_NAME = ".dconf-config";

    private Gtk.DropDown drop_down;
    private Gtk.StringList uris;
    public MyApp () {
        Object (
            application_id: "io.github.myteam.myapp",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var headerbar = new Gtk.HeaderBar () {
            show_title_buttons = true
        };

        var main_window = new Gtk.ApplicationWindow (this) {
            default_height = 300,
            default_width = 300,
            title = "MyApp",
            titlebar = headerbar
        };
        uris = new Gtk.StringList (null);
        drop_down = new Gtk.DropDown (uris, null);
        var export = new Gtk.Button.with_label ("Export");
        var import = new Gtk.Button.with_label ("Import");
        var box = new Gtk.Box (VERTICAL, 12);
        box.append (drop_down);
        box.append (export);
        box.append (import);
        main_window.child = box;
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
        main_window.present ();
        export.clicked.connect (get_location);
        import.clicked.connect (get_import_location);
    }

    private void get_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", active_window, SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                save_flatpak_apps.begin (file);
                save_configuration.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }

    private void get_import_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", active_window, SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                load_saved_configuration.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }

    private async void install_saved_flatpak_apps (File dir) {
        try {
            var file = File.new_build_filename (dir.get_path (), INSTALLED_FLATPAKS_FILE_NAME);

            var subprocess = new Subprocess (
                STDERR_PIPE,
                "flatpak-spawn",
                "--host",
                "sh",
                file.get_path ()
            );

            Bytes stderr;
            yield subprocess.communicate_async (null, null, null, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            if (stderr_data != null) {
                warning ("Failed to install saved flatpak apps: %s", (string) stderr_data);
            }
        } catch (Error e) {
            warning ("Failed to create sh subprocess: %s", e.message);
        }
    }

    private async void save_flatpak_apps (File dir) {
        try {
            var subprocess = new Subprocess (
                STDERR_PIPE | STDOUT_PIPE,
                "flatpak-spawn",
                "--host",
                "flatpak",
                "list",
                "--columns=application",
                "--app"
            );

            Bytes stderr;
            Bytes stdout;
            yield subprocess.communicate_async (null, null, out stdout, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                warning ("Failed to save flatpak apps: %s", (string) stderr_data);
            } else if (stdout_data != null) {
                var file = File.new_build_filename (dir.get_path (), INSTALLED_FLATPAKS_FILE_NAME);
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    warning ("Failed to replace contents: %s", e.message);
                }
            }
        } catch (Error e) {
            warning ("Failed to create subprocess: %s", e.message);
        }
    }

    private async void load_saved_configuration (File dir) {
        try {
            var file = File.new_build_filename (dir.get_path (), DCONF_CONFIG_FILE_NAME);

            var subprocess = new Subprocess (
                STDIN_PIPE | STDERR_PIPE,
                "flatpak-spawn",
                "--host",
                "dconf",
                "load",
                "/"
            );

            uint8[] contents;
            try {
                yield file.load_contents_async (null, out contents, null);
            } catch (Error e) {
                warning ("Failed to load config file: %s", e.message);
                return;
            }

            Bytes stderr;
            yield subprocess.communicate_async (new Bytes (contents), null, null, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            if (stderr_data != null) {
                warning ("Failed to load saved configuration into dconf: %s", (string) stderr_data);
            }
        } catch (Error e) {
            warning ("Failed to create dconf load subprocess: %s", e.message);
        }
    }

    private async void save_configuration (File dir) {
        try {
            var subprocess = new Subprocess (
                STDERR_PIPE | STDOUT_PIPE,
                "flatpak-spawn",
                "--host",
                "dconf",
                "dump",
                "/"
            );

            Bytes stderr;
            Bytes stdout;
            yield subprocess.communicate_async (null, null, out stdout, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                warning ("Failed to load saved configuration into dconf: %s", (string) stderr_data);
            } else if (stdout_data != null) {
                var file = File.new_build_filename (dir.get_path (), DCONF_CONFIG_FILE_NAME);
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    warning ("Failed to replace contents: %s", e.message);
                }
            }
        } catch (Error e) {
            warning ("Failed to create subprocess: %s", e.message);
        }
    }

    public static int main (string[] args) {
        return new MyApp ().run (args);
    }
}
