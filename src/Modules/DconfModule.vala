public class Syncher.DconfModule : Module {
    construct {
        var settings = new GLib.Settings ("io.github.leolost2605.syncher");
        settings.bind ("sync-config", this, "enabled", DEFAULT);

        import_label = _("Loading Configuration");
        export_label = _("Saving Configuration");
        id = "dconf";
    }

    public async override void import (File file) {
        progress = 0;

        if (!file.query_exists ()) {
            fatal_error ("File doesn't exist.");
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
                yield file.load_contents_async (cancellable, out contents, null);
                progress = 50;
            } catch (Error e) {
                fatal_error ("Failed to load config file: %s".printf (e.message));
                return;
            }

            Bytes stderr;
            yield subprocess.communicate_async (new Bytes (contents), cancellable, null, out stderr);

            var stderr_data = Bytes.unref_to_data (stderr);
            if (stderr_data != null) {
                fatal_error ("Failed to load saved configuration into dconf: %s".printf ((string) stderr_data));
            }
        } catch (Error e) {
            fatal_error ("Failed to create dconf load subprocess: %s".printf (e.message));
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
                "dconf",
                "dump",
                "/"
            );

            Bytes stderr;
            Bytes stdout;
            yield subprocess.communicate_async (null, cancellable, out stdout, out stderr);

            progress = 50;

            var stderr_data = Bytes.unref_to_data (stderr);
            var stdout_data = Bytes.unref_to_data (stdout);
            if (stderr_data != null) {
                fatal_error ("Failed to get current configuration from dconf: %s".printf ((string) stderr_data));
            } else if (stdout_data != null) {
                try {
                    yield file.replace_contents_async (stdout_data, null, false, REPLACE_DESTINATION, cancellable, null);
                } catch (Error e) {
                    fatal_error ("Failed to replace file contents: %s".printf (e.message));
                }
            }
        } catch (Error e) {
            fatal_error ("Failed to create subprocess: %s".printf (e.message));
        }

        progress = 100;
    }
}
