/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class MyApp : Gtk.Application {
    private const string INSTALLED_FLATPAKS_FILE_NAME = ".installed_flatpaks";
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
                install_saved_flatpak_apps.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }

    private async void install_saved_flatpak_apps (File dir) {
        try {
            var file = File.new_build_filename (dir.get_path (), ".flatpak-apps");

            var subprocess = new Subprocess (
                STDERR_PIPE,
                "flatpak-spawn",
                "--host",
                "sh",
                file.get_path ()
            );
            var err_input_stream = subprocess.get_stderr_pipe ();

            yield subprocess.wait_async (null);

            if (subprocess.get_exit_status () != 0) {
                var buffer_is = new BufferedInputStream (err_input_stream);
                var builder = new StringBuilder ();
                uint8 buffer[100];
                ssize_t size;

                while ((size = yield buffer_is.read_async (buffer)) > 0) {
                    builder.append_len ((string) buffer, size);
                }

                warning ("Failed to install flatpak apps: %s", (string) builder.str);
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
            var err_input_stream = subprocess.get_stderr_pipe ();
            var out_input_stream = subprocess.get_stdout_pipe ();

            yield subprocess.wait_async (null);

            if (subprocess.get_exit_status () != 0) {
                var buffer_is = new BufferedInputStream (err_input_stream);
                var builder = new StringBuilder ();
                uint8 buffer[100];
                ssize_t size;

                while ((size = yield buffer_is.read_async (buffer)) > 0) {
                    builder.append_len ((string) buffer, size);
                }

                warning ("Failed to list flatpak applications: %s", (string) builder.str);
            } else {
                var data_is = new DataInputStream (out_input_stream);
                var builder = new StringBuilder ();
                string? data = null;

                while ((data = yield data_is.read_line_async ()) != null) {
                    builder.append ("flatpak install --user %s -y\n".printf (data));
                }

                var file = File.new_build_filename (dir.get_path (), ".flatpak-apps");

                try {
                    yield file.replace_contents_async (builder.data, null, false, REPLACE_DESTINATION, null, null);
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
