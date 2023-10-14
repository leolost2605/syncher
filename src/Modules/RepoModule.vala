public class Syncher.RepoModule : Module {
    construct {
        var settings = new GLib.Settings ("io.github.leolost2605.syncher");
        settings.bind ("sync-apps", this, "enabled", DEFAULT);

        import_label = _("Adding Software Sources");
        export_label = _("Saving Software Sources");
        id = "repo";
    }

    public async override void import (File file) {
        progress = 0;

        if (!file.query_exists ()) {
            fatal_error ("File doesn't exist.");
            return;
        }

        uint8[] contents;
        try {
            yield file.load_contents_async (cancellable, out contents, null);
        } catch (Error e) {
            fatal_error ("Failed to load file: %s".printf (e.message));
            return;
        }

        var remotes = ((string) contents).split_set ("\n");

        for (int i = 0; i < remotes.length - 1; i++) {
            if (cancellable.is_cancelled ()) {
                return;
            }

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
                    yield subprocess.communicate_async (null, cancellable, null, out stderr);

                    var stderr_data = Bytes.unref_to_data (stderr);
                    if (stderr_data != null) {
                        error (_("Failed to add flatpak remote '%s'").printf (remotes[i]), (string) stderr_data);
                    }
                } catch (Error e) {
                    error (
                        _("Failed to add flatpak remote '%s'").printf (remotes[i]),
                        (string) "Failed to create flatpak remote-add subprocess: %s".printf (e.message)
                    );
                }
            } else {
                error (_("Failed to add flatpak remote '%s'").printf (remotes[i]), "Unknown parameters provided.");
            }

            progress = ((i + 1) / remotes.length) * 100;
        }

        progress = 100;
    }

    public async override void export (File file) {
        progress = 0;

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
            yield subprocess.communicate_async (null, cancellable, out stdout, out stderr);

            progress = 50;

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error ("Failed to save flatpak remotes: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, cancellable, null);
                } catch (Error e) {
                    fatal_error ("Failed to replace contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error ("Failed to create subprocess: %s".printf (e.message));
        }

        progress = 100;
    }
}
