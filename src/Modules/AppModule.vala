public class Syncher.AppModule : Module {
    construct {
        var settings = new GLib.Settings ("io.github.leolost2605.syncher");
        settings.bind ("sync-apps", this, "enabled", DEFAULT);

        import_label = _("Installing Apps");
        export_label = _("Saving Apps");
        id = "app";
    }

    public async override void import (File file) {
        progress (0);

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

        var apps = ((string)contents).split_set ("\n");

        for (int i = 0; i < apps.length - 1; i++) {
            if (cancellable.is_cancelled ()) {
                return;
            }

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
                        error (_("Failed to install flatpak app '%s'").printf (apps[i]), (string) stderr_data);
                    }
                } catch (Error e) {
                    error (_("Failed to install flatpak app '%s'").printf (apps[i]), "Failed to create flatpak install subprocess: %s".printf (e.message));
                }
            } else {
                error (_("Failed to install flatpak app '%s'").printf (apps[i]), "Unknown parameters provided.");
            }

            progress ((int) (((double) (i + 1) / (double) apps.length) * 100));
        }

        progress (100);
    }

    public async override void export (File file) {
        progress (0);

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
            yield subprocess.communicate_async (null, cancellable, out stdout, out stderr);

            progress (50);

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error ("Failed to save flatpak apps: %s".printf ((string) stderr_data));
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

        progress (100);
    }
}
