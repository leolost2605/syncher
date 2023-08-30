/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Syncher.SyncherService : Object {
    public signal void fatal_error (ProgressStep step, string msg);
    public signal void error (ProgressStep step, string msg);
    public signal void progress (ProgressStep step, int percentage);
    public signal void start_sync (SyncType sync_type);
    public signal void finish_sync ();

    public enum ProgressStep {
        LOADING_CONFIGURATION,
        INSTALLING_FLATPAKS,
        SAVING_CONFIGURATION,
        SAVING_FLATPAKS
    }

    public enum SyncType {
        IMPORT,
        EXPORT
    }

    private static GLib.Once<SyncherService> _instance;
    public static unowned SyncherService get_default () {
        return _instance.once (() => { return new SyncherService (); });
    }


    private const string FLATPAKS_FILE_NAME = ".installed-flatpaks";
    private const string DCONF_FILE_NAME = ".dconf-config";

    private Cancellable cancellable;

    construct {
        cancellable = new Cancellable ();

        error.connect ((step, msg) => warning ("An error occured during %s: %s", step.to_string (), msg));
        fatal_error.connect ((step, msg) => warning ("An error occured during %s: %s", step.to_string (), msg));
    }

    public async void sync (File dir, bool should_export = true) {
        var settings = new GLib.Settings ("io.github.leolost2605.syncher");
        var file = dir.get_child (FLATPAKS_FILE_NAME);
        if (file.query_exists ()) {
            try {
                var info = yield file.query_info_async ("*", NONE);
                var mod_time = info.get_modification_date_time ();
                if (mod_time != null) {
                    var last_sync_time = new DateTime.from_unix_utc (settings.get_int64 ("last-sync-time"));
                    if (mod_time.difference (last_sync_time) > TimeSpan.MINUTE) {
                        import.begin (dir);
                        settings.set_int64 ("last-sync-time", mod_time.to_unix ());
                        print ("Import!");
                        return;
                    } else if (should_export) {
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
            if (should_export) {
                export.begin (dir);
            }
        }

        settings.set_int64 ("last-sync-time", new DateTime.now_utc ().to_unix ());
    }

    public async void import (File dir) {
        start_sync (IMPORT);

        var flatpak_file = dir.get_child (FLATPAKS_FILE_NAME);
        yield install_saved_flatpak_apps (flatpak_file);
        var dconf_file = dir.get_child (DCONF_FILE_NAME);
        yield load_saved_configuration (dconf_file);

        finish_sync ();
    }

    private async void install_saved_flatpak_apps (File file) {
        progress (INSTALLING_FLATPAKS, 0);

        if (!file.query_exists ()) {
            fatal_error (INSTALLING_FLATPAKS, "File doesn't exist.");
            return;
        }

        uint8[] contents;
        try {
            yield file.load_contents_async (cancellable, out contents, null);
        } catch (Error e) {
            fatal_error (INSTALLING_FLATPAKS, "Failed to load file: %s".printf (e.message));
            return;
        }

        var apps = ((string)contents).split_set ("\n");

        int counter = 0;
        foreach (var app in apps) {
            try {
                var subprocess = new Subprocess (
                    STDERR_PIPE,
                    "flatpak-spawn",
                    "--host",
                    "flatpak",
                    "install",
                    "-y",
                    app
                );

                Bytes stderr;
                yield subprocess.communicate_async (null, null, null, out stderr);

                var stderr_data = Bytes.unref_to_data (stderr);
                if (stderr_data != null) {
                    error (INSTALLING_FLATPAKS, "Failed to install flatpak app '%s': %s".printf (app, (string) stderr_data));
                }
            } catch (Error e) {
                error (INSTALLING_FLATPAKS, "Failed to create flatpak install subprocess: %s".printf (e.message));
            }

            counter++;
            progress (INSTALLING_FLATPAKS, (counter / apps.length) * 100);
        }

        progress (INSTALLING_FLATPAKS, 100);
    }

    private async void load_saved_configuration (File file) {
        progress (LOADING_CONFIGURATION, 0);

        if (!file.query_exists ()) {
            fatal_error (LOADING_CONFIGURATION, "File doesn't exist.");
            return;
        }

        try {
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
                progress (LOADING_CONFIGURATION, 50);
            } catch (Error e) {
                fatal_error (LOADING_CONFIGURATION, "Failed to load config file: %s".printf (e.message));
                return;
            }

            Bytes stderr;
            yield subprocess.communicate_async (new Bytes (contents), null, null, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            if (stderr_data != null) {
                fatal_error (LOADING_CONFIGURATION, "Failed to load saved configuration into dconf: %s".printf ((string) stderr_data));
            }
        } catch (Error e) {
            fatal_error (LOADING_CONFIGURATION, "Failed to create dconf load subprocess: %s".printf (e.message));
        }

        progress (LOADING_CONFIGURATION, 100);
    }

    public async void export (File dir) {
        start_sync (EXPORT);

        var flatpak_file = dir.get_child (FLATPAKS_FILE_NAME);
        yield save_flatpak_apps (flatpak_file);
        var dconf_file = dir.get_child (DCONF_FILE_NAME);
        yield save_configuration (dconf_file);

        finish_sync ();
    }

    private async void save_flatpak_apps (File file) {
        progress (SAVING_FLATPAKS, 0);

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

            progress (SAVING_FLATPAKS, 50);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error (SAVING_FLATPAKS, "Failed to save flatpak apps: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    fatal_error (SAVING_FLATPAKS, "Failed to replace contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error (SAVING_FLATPAKS, "Failed to create subprocess: %s".printf (e.message));
        }

        progress (SAVING_FLATPAKS, 100);
    }

    private async void save_configuration (File file) {
        progress (SAVING_CONFIGURATION, 0);

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

            progress (SAVING_CONFIGURATION, 50);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error (SAVING_CONFIGURATION, "Failed to get current configuration from dconf: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    fatal_error (SAVING_CONFIGURATION, "Failed to replace file contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error (SAVING_CONFIGURATION, "Failed to create subprocess: %s".printf (e.message));
        }

        progress (SAVING_CONFIGURATION, 100);
    }
}
