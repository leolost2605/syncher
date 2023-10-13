/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Syncher.SyncherService : Object {
    public signal void fatal_error (ProgressStep step, string msg, string details = "");
    public signal void error (ProgressStep step, string msg, string details);
    public signal void progress (ProgressStep step, int percentage);
    public signal void start_sync (SyncType sync_type);
    public signal void finish_sync ();

    public enum ProgressStep {
        CONFIG = 0,
        REMOTES = 1,
        APPS = 2,
        SETUP,
        PREPARING
    }

    public enum SyncType {
        IMPORT,
        EXPORT
    }

    private static GLib.Once<SyncherService> _instance;
    public static unowned SyncherService get_default () {
        return _instance.once (() => { return new SyncherService (); });
    }

    public Error? error_state { get; private set; default = null; }
    public File sync_dir { get; private set; }
    public HashTable<string, Module> modules { get; set; }

    private const string FLATPAK_REMOTES_FILE_NAME = ".flatpak-remotes";
    private const string FLATPAKS_FILE_NAME = ".installed-flatpaks";
    private const string DCONF_FILE_NAME = ".dconf-config";

    private Settings settings;
    private Cancellable cancellable;
    private uint timer_id = 0;

    construct {
        settings = new GLib.Settings ("io.github.leolost2605.syncher");
        cancellable = new Cancellable ();

        error.connect ((step, msg) => warning ("An error occured during %s: %s", step.to_string (), msg));
        fatal_error.connect ((step, msg) => warning ("An error occured during %s: %s", step.to_string (), msg));
        modules = new HashTable<string, Module> (str_hash, str_equal);
        var dmod = new DconfModule ();
        modules[dmod.id] = dmod;
    }

    public void setup_saved_synchronization () {
        var saved_location = settings.get_string ("sync-location");
        if (saved_location != "") {
            var dir = File.new_for_uri (saved_location);
            setup_synchronization (dir);
        }
    }

    public void setup_synchronization (File dir) {
        sync_dir = dir;

        if (!dir.query_exists ()) {
            error_state = new FileError.NOENT ("Synchronization directory doesn't exist.");
            fatal_error (SETUP, "Synchronization directory doesn't exist.");
            return;
        }

        error_state = null;

        debug ("Setting up synchronization for directory with uri: %s", dir.get_uri ());

        if (timer_id != 0) {
            Source.remove (timer_id);
        }

        sync.begin (sync_dir);

        timer_id = Timeout.add_seconds (3600, () => {
            sync.begin (sync_dir);
            return Source.CONTINUE;
        });
    }

    public async void sync (File? dir = null, bool should_export = true) {
        if (dir == null) {
            dir = sync_dir;
        }

        if (!dir.query_exists ()) {
            fatal_error (PREPARING, "Synchronization directory doesn't exist.");
            return;
        }

        var last_sync_time = new DateTime.from_unix_utc (settings.get_int64 ("last-sync-time"));

        try {
            var info = yield dir.query_info_async ("*", NONE);
            var mod_time = info.get_modification_date_time ();
            if (mod_time != null) {
                if (mod_time.compare (last_sync_time) > 0) {
                    yield import (dir);
                    print ("Import!");
                } else if (should_export) {
                    print ("Export!");
                    yield export (dir);
                } else {
                    return;
                }

                settings.set_int64 ("last-sync-time", new DateTime.now_utc ().to_unix ());
            } else {
                print ("Mod time is null!");
            }
        } catch (Error e) {
            warning ("Failed to get file info: %s", e.message);
        }
    }

    public async void import (File dir) {
        start_sync (IMPORT);

        if (settings.get_boolean ("sync-config")) {
            var dconf_file = dir.get_child (DCONF_FILE_NAME);
            // yield load_saved_configuration (dconf_file);
            yield modules["dconf"].import (dconf_file);
        }

        if (settings.get_boolean ("sync-apps")) {
            var flatpak_remotes_file = dir.get_child (FLATPAK_REMOTES_FILE_NAME);
            yield add_saved_flatpak_remotes (flatpak_remotes_file);
            var flatpak_file = dir.get_child (FLATPAKS_FILE_NAME);
            yield install_saved_flatpak_apps (flatpak_file);
        }

        finish_sync ();
    }

    private async void load_saved_configuration (File file) {
        progress (CONFIG, 0);

        if (!file.query_exists ()) {
            fatal_error (CONFIG, "File doesn't exist.");
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
                progress (CONFIG, 50);
            } catch (Error e) {
                fatal_error (CONFIG, "Failed to load config file: %s".printf (e.message));
                return;
            }

            Bytes stderr;
            yield subprocess.communicate_async (new Bytes (contents), null, null, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            if (stderr_data != null) {
                fatal_error (CONFIG, "Failed to load saved configuration into dconf: %s".printf ((string) stderr_data));
            }
        } catch (Error e) {
            fatal_error (CONFIG, "Failed to create dconf load subprocess: %s".printf (e.message));
        }

        progress (CONFIG, 100);
    }

    private async void add_saved_flatpak_remotes (File file) {
        progress (REMOTES, 0);

        if (!file.query_exists ()) {
            fatal_error (REMOTES, "File doesn't exist.");
            return;
        }

        uint8[] contents;
        try {
            yield file.load_contents_async (cancellable, out contents, null);
        } catch (Error e) {
            fatal_error (REMOTES, "Failed to load file: %s".printf (e.message));
            return;
        }

        var remotes = ((string) contents).split_set ("\n");

        for (int i = 0; i < remotes.length - 1; i++) {
            var parts = remotes[i].split_set ("\t");

            if (parts.length == 2) {
                try {
                    var subprocess = new Subprocess (
                        STDERR_PIPE,
                        "flatpak-spawn",
                        "--host",
                        "flatpak",
                        "remote-add",
                        "--if-not-exists",
                        parts[0],
                        parts[1]
                    );

                    Bytes stderr;
                    yield subprocess.communicate_async (null, null, null, out stderr);

                    var stderr_data = Bytes.unref_to_data (stderr);
                    if (stderr_data != null) {
                        error (REMOTES, _("Failed to add flatpak remote '%s'").printf (remotes[i]), (string) stderr_data);
                    }
                } catch (Error e) {
                    error (
                        REMOTES,
                        _("Failed to add flatpak remote '%s'").printf (remotes[i]),
                        (string) "Failed to create flatpak remote-add subprocess: %s".printf (e.message)
                    );
                }
            } else {
                error (REMOTES, _("Failed to add flatpak remote '%s'").printf (remotes[i]), "Unknown parameters provided.");
            }

            progress (REMOTES, ((i + 1) / remotes.length) * 100);
        }

        progress (REMOTES, 100);
    }

    private async void install_saved_flatpak_apps (File file) {
        progress (APPS, 0);

        if (!file.query_exists ()) {
            fatal_error (APPS, "File doesn't exist.");
            return;
        }

        uint8[] contents;
        try {
            yield file.load_contents_async (cancellable, out contents, null);
        } catch (Error e) {
            fatal_error (APPS, "Failed to load file: %s".printf (e.message));
            return;
        }

        var apps = ((string)contents).split_set ("\n");

        for (int i = 0; i < apps.length - 1; i++) {
            var parts = apps[i].split_set ("\t");

            if (parts.length == 2) {
                try {
                    var subprocess = new Subprocess (
                        STDERR_PIPE,
                        "flatpak-spawn",
                        "--host",
                        "flatpak",
                        "install",
                        "-y",
                        "--noninteractive",
                        "--or-update",
                        "--user",
                        parts[0],
                        parts[1],
                        "stable"
                    );

                    Bytes stderr;
                    yield subprocess.communicate_async (null, null, null, out stderr);

                    var stderr_data = Bytes.unref_to_data (stderr);
                    if (stderr_data != null) {
                        error (APPS, _("Failed to install flatpak app '%s'").printf (apps[i]), (string) stderr_data);
                    }
                } catch (Error e) {
                    error (APPS, _("Failed to install flatpak app '%s'").printf (apps[i]), "Failed to create flatpak install subprocess: %s".printf (e.message));
                }
            } else {
                error (APPS, _("Failed to install flatpak app '%s'").printf (apps[i]), "Unknown parameters provided.");
            }

            progress (APPS, (int) (((double) (i + 1) / (double) apps.length) * 100));
        }

        progress (APPS, 100);
    }

    public async void export (File dir) {
        start_sync (EXPORT);

        if (settings.get_boolean ("sync-config")) {
            var dconf_file = dir.get_child (DCONF_FILE_NAME);
            // yield save_configuration (dconf_file);
            yield modules["dconf"].export (dconf_file);
        }

        if (settings.get_boolean ("sync-apps")) {
            var flatpak_remotes_file = dir.get_child (FLATPAK_REMOTES_FILE_NAME);
            yield save_flatpak_remotes (flatpak_remotes_file);
            var flatpak_file = dir.get_child (FLATPAKS_FILE_NAME);
            yield save_flatpak_apps (flatpak_file);
        }

        finish_sync ();
    }

    private async void save_configuration (File file) {
        progress (CONFIG, 0);

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

            progress (CONFIG, 50);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error (CONFIG, "Failed to get current configuration from dconf: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    fatal_error (CONFIG, "Failed to replace file contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error (CONFIG, "Failed to create subprocess: %s".printf (e.message));
        }

        progress (CONFIG, 100);
    }

    private async void save_flatpak_remotes (File file) {
        progress (REMOTES, 0);

        try {
            var subprocess = new Subprocess (
                STDERR_PIPE | STDOUT_PIPE,
                "flatpak-spawn",
                "--host",
                "flatpak",
                "remotes",
                "--user",
                "--columns=name,url"
            );

            Bytes stderr;
            Bytes stdout;
            yield subprocess.communicate_async (null, null, out stdout, out stderr);

            progress (REMOTES, 50);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error (REMOTES, "Failed to save flatpak remotes: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    fatal_error (REMOTES, "Failed to replace contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error (REMOTES, "Failed to create subprocess: %s".printf (e.message));
        }

        progress (REMOTES, 100);
    }

    private async void save_flatpak_apps (File file) {
        progress (APPS, 0);

        try {
            var subprocess = new Subprocess (
                STDERR_PIPE | STDOUT_PIPE,
                "flatpak-spawn",
                "--host",
                "flatpak",
                "list",
                "--columns=origin,application",
                "--app",
                "--user"
            );

            Bytes stderr;
            Bytes stdout;
            yield subprocess.communicate_async (null, null, out stdout, out stderr);

            progress (APPS, 50);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error (APPS, "Failed to save flatpak apps: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, null, null);
                } catch (Error e) {
                    fatal_error (APPS, "Failed to replace contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error (APPS, "Failed to create subprocess: %s".printf (e.message));
        }

        progress (APPS, 100);
    }
}
