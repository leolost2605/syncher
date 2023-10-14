/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Syncher.SyncherService : Object {
    public signal void fatal_error (ProgressStep step, string msg, string details = "");

    public enum ProgressStep {
        SETUP,
        PREPARING
    }

    public enum SyncType {
        NONE,
        IMPORT,
        EXPORT
    }

    private static GLib.Once<SyncherService> _instance;
    public static unowned SyncherService get_default () {
        return _instance.once (() => { return new SyncherService (); });
    }

    public Error? error_state { get; private set; default = null; }
    public File sync_dir { get; private set; }
    public bool working { get; private set; default = false; }
    public SyncType current_sync_type { get; private set; default = NONE; }

    public List<Module> modules;

    private Settings settings;
    private Cancellable cancellable;
    private uint timer_id = 0;

    construct {
        modules = new List<Module> ();
        settings = new GLib.Settings ("io.github.leolost2605.syncher");
        cancellable = new Cancellable ();

        notify["working"].connect (() => {
            if (!working) {
                current_sync_type = NONE;
            }
        });

        fatal_error.connect ((step, msg) => warning ("An error occured during %s: %s", step.to_string (), msg));
    }

    public void setup_saved_synchronization () {
        var saved_location = settings.get_string ("sync-location");
        if (saved_location != "") {
            var dir = File.new_for_uri (saved_location);
            setup_synchronization (dir);
        }

        modules.append (new DconfModule ());
        modules.append (new RepoModule ());
        modules.append (new AppModule ());
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
        cancellable.reset ();

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
                    print ("Import!");
                    yield import (dir);
                } else if (!settings.get_boolean ("only-import")) {
                    print ("Export!");
                    yield export (dir);
                } else {
                    critical ("Something is wrong!");
                    return;
                }

                settings.set_int64 ("last-sync-time", new DateTime.now_utc ().to_unix ());
            } else {
                print ("Mod time is null!");
            }
        } catch (Error e) {
            warning ("Failed to get file info: %s", e.message);
        }

        working = false;
    }

    public async void import (File dir) {
        current_sync_type = IMPORT;
        working = true;

        foreach (var module in modules) {
            if (cancellable.is_cancelled ()) {
                break;
            }

            if (!module.enabled) {
                continue;
            }

            var file = dir.get_child ("." + module.id);
            yield module.import (file);
        }
    }

    public async void export (File dir) {
        current_sync_type = EXPORT;
        working = true;

        foreach (var module in modules) {
            if (cancellable.is_cancelled ()) {
                break;
            }

            if (!module.enabled) {
                continue;
            }

            var file = dir.get_child ("." + module.id);
            yield module.export (file);
        }
    }

    public void cancel () {
        if (!working) {
            return;
        }

        cancellable.cancel ();

        foreach (var module in modules) {
            module.cancel ();
        }
    }
}
