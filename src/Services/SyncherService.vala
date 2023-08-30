/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

[SingleInstance]
public class Syncher.SyncherService : Object {
    private const string INSTALLED_FLATPAKS_FILE_NAME = ".installed-flatpaks";
    private const string DCONF_CONFIG_FILE_NAME = ".dconf-config";

    public async void sync (File dir) {
        var file = dir.get_child (INSTALLED_FLATPAKS_FILE_NAME);
        if (file != null) {
            try {
                var info = yield file.query_info_async ("*", NONE);
                var mod_time = info.get_modification_date_time ();
                if (mod_time != null) {
                    var settings = new GLib.Settings ("io.github.leolost2605.syncher");
                    var last_import_time = new DateTime.from_unix_utc (settings.get_int64 ("last-import-time"));
                    if (mod_time.difference (last_import_time) > TimeSpan.MINUTE) {
                        import.begin (dir);
                        settings.set_int64 ("last-import-time", mod_time.to_unix ());
                        print ("Import!");
                    } else {
                        print ("Export!");
                        export.begin (dir);
                    }
                } else {
                    print ("Mod time is null!");
                }
            } catch (Error e) {
                warning ("Failed to get file info: %s", e.message);
            }
        } else {
            print ("Sync dir not found!");
            export.begin (dir);
        }
    }

    public async void export (File dir) {
        save_flatpak_apps.begin (dir);
        save_configuration.begin (dir);
    }

    public async void import (File dir) {
        install_saved_flatpak_apps.begin (dir);
        load_saved_configuration.begin (dir);
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
}
