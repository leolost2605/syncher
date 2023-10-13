/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Syncher.SyncherService : Object {
    public signal void fatal_error (ProgressStep step, string msg, string details = "");
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

    public HashTable<string, Module> modules_by_id;
    public List<Module> modules;

    private const string FLATPAK_REMOTES_FILE_NAME = ".flatpak-remotes";
    private const string FLATPAKS_FILE_NAME = ".installed-flatpaks";
    private const string DCONF_FILE_NAME = ".dconf-config";

    private Settings settings;
    private Cancellable cancellable;
    private uint timer_id = 0;

    construct {
        modules = new List<Module> ();
        modules_by_id = new HashTable<string, Module> (str_hash, str_equal);
        settings = new GLib.Settings ("io.github.leolost2605.syncher");
        cancellable = new Cancellable ();

        fatal_error.connect ((step, msg) => warning ("An error occured during %s: %s", step.to_string (), msg));

        modules.append (new DconfModule ());
        modules_by_id[modules.last ().data.id] = modules.last ().data;
        modules.append (new RepoModule ());
        modules_by_id[modules.last ().data.id] = modules.last ().data;
        modules.append (new AppModule ());
        modules_by_id[modules.last ().data.id] = modules.last ().data;
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

        foreach (var module in modules) {
            var file = dir.get_child ("." + module.id);
            yield module.import (file);
        }

        // if (settings.get_boolean ("sync-config")) {
        //     var dconf_file = dir.get_child (DCONF_FILE_NAME);
        //     // yield load_saved_configuration (dconf_file);
        //     yield modules_by_id["dconf"].import (dconf_file);
        // }

        // if (settings.get_boolean ("sync-apps")) {
        //     var flatpak_remotes_file = dir.get_child (FLATPAK_REMOTES_FILE_NAME);
        //     yield modules_by_id["repo"].import (flatpak_remotes_file);
        //     // yield add_saved_flatpak_remotes (flatpak_remotes_file);
        //     var flatpak_file = dir.get_child (FLATPAKS_FILE_NAME);
        //     yield modules_by_id["app"].import (flatpak_file);
        //     // yield install_saved_flatpak_apps (flatpak_file);
        // }

        finish_sync ();
    }

    public async void export (File dir) {
        start_sync (EXPORT);

        foreach (var module in modules) {
            var file = dir.get_child ("." + module.id);
            yield module.export (file);
        }

        // if (settings.get_boolean ("sync-config")) {
        //     var dconf_file = dir.get_child (DCONF_FILE_NAME);
        //     // yield save_configuration (dconf_file);
        //     yield modules_by_id["dconf"].export (dconf_file);
        // }

        // if (settings.get_boolean ("sync-apps")) {
        //     var flatpak_remotes_file = dir.get_child (FLATPAK_REMOTES_FILE_NAME);
        //     yield modules_by_id["repo"].export (flatpak_remotes_file);
        //     // yield save_flatpak_remotes (flatpak_remotes_file);
        //     var flatpak_file = dir.get_child (FLATPAKS_FILE_NAME);
        //     yield modules_by_id["app"].export (flatpak_file);
        //     // yield save_flatpak_apps (flatpak_file);
        // }

        finish_sync ();
    }
}
