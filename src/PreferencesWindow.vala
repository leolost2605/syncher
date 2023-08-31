public class Syncher.PreferencesWindow : Gtk.Window {

    public PreferencesWindow (Gtk.Window window) {
        Object (transient_for: window);
    }

    construct {
        var settings = new Settings ("io.github.leolost2605.syncher");

        var location_label = new Granite.HeaderLabel (_("Location")) {
            secondary_text = _("Shared location used to synchronize your devices.")
        };

        var drop_down = new Gtk.DropDown (null, null) {
            hexpand = true
        };

        var items_label = new Granite.HeaderLabel (_("Items")) {
            secondary_text = _("Items to synchronize between your devices.")
        };

        var apps_label = new Gtk.Label (_("Apps")) {
            halign = END
        };

        var apps_switch = new Gtk.Switch () {
            halign = START,
            hexpand = true
        };
        settings.bind ("sync-apps", apps_switch, "active", DEFAULT);

        var config_label = new Gtk.Label (_("Configuration")) {
            halign = END
        };

        var config_switch = new Gtk.Switch () {
            halign = START
        };
        settings.bind ("sync-config", config_switch, "active", DEFAULT);

        var grid = new Gtk.Grid () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            column_spacing = 6,
            row_spacing = 6,
            halign = CENTER,
            valign = CENTER
        };
        grid.attach (location_label, 0, 0, 2);
        grid.attach (drop_down, 0, 1, 2);
        grid.attach (items_label, 0, 2, 2);
        grid.attach (apps_label, 0, 3);
        grid.attach (apps_switch, 1, 3);
        grid.attach (config_label, 0, 4);
        grid.attach (config_switch, 1, 4);

        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var overlay = new Gtk.Overlay () {
            child = grid
        };
        overlay.add_overlay (header_bar);

        default_height = 290;
        default_width = 300;
        resizable = false;
        child = overlay;
        titlebar = new Gtk.Grid () { visible = false };
        present ();

        var uris = new Gtk.StringList (null);
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
    }
}
