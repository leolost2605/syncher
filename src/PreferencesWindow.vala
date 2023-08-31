public class Syncher.PreferencesWindow : Gtk.Window {
    public PreferencesWindow (Gtk.Window window) {
        Object (transient_for: window);
    }

    construct {
        var settings = new Settings ("io.github.leolost2605.syncher");
        var mounts = new ListStore (typeof (Mount));

        var location_label = new Granite.HeaderLabel (_("Location")) {
            secondary_text = _("Shared location used to synchronize your devices.")
        };

        var factory = new Gtk.SignalListItemFactory ();

        var drop_down = new Gtk.DropDown (mounts, null) {
            hexpand = true,
            factory = factory
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
            row_spacing = 6
        };
        grid.attach (location_label, 0, 0, 2);
        grid.attach (drop_down, 0, 1, 2);
        grid.attach (items_label, 0, 2, 2);
        grid.attach (apps_label, 0, 3);
        grid.attach (apps_switch, 1, 3);
        grid.attach (config_label, 0, 4);
        grid.attach (config_switch, 1, 4);

        var interval_label = new Granite.HeaderLabel (_("Interval")) {
            secondary_text = _("How often this device should synchronize with the remote location.")
        };

        // var factory = new Gtk.SignalListItemFactory ();

        // var drop_down = new Gtk.DropDown (mounts, null) {
        //     hexpand = true,
        //     factory = factory
        // };

        var sync_grid = new Gtk.Grid () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            column_spacing = 6,
            row_spacing = 6
        };
        sync_grid.attach (interval_label, 0, 0, 2);
        // sync_grid.attach (drop_down, 0, 1, 2);

        var stack = new Gtk.Stack ();
        stack.add_titled (grid, null, _("General"));
        stack.add_titled (sync_grid, null, _("Synchronization"));

        var switcher = new Gtk.StackSwitcher () {
            stack = stack
        };
        ((Gtk.BoxLayout) switcher.layout_manager).homogeneous = true;

        var header_bar = new Gtk.HeaderBar () {
            title_widget = switcher,
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        default_height = 400;
        default_width = 400;
        resizable = false;
        child = stack;
        titlebar = header_bar;
        present ();

        factory.bind.connect ((obj) => {
            var item = (Gtk.ListItem) obj;
            item.child = new Gtk.Label (((Mount) item.item).get_name ()) { halign = START };
        });

        var volume_monitor = VolumeMonitor.get ();
        foreach (var mount in volume_monitor.get_mounts ()) {
            mounts.append (mount);
        }

        drop_down.selected = Gtk.INVALID_LIST_POSITION;

        var selected = settings.get_string ("sync-location");
        if (selected != "") {
            for (int i = 0; i < mounts.get_n_items (); i++) {
                if (((Mount) mounts.get_item (i)).get_default_location ().get_uri () == selected) {
                    drop_down.selected = i;
                    break;
                }
            }
        }

        drop_down.notify["selected"].connect (() => {
            if (drop_down.selected == Gtk.INVALID_LIST_POSITION) {
                settings.set_string ("sync-location", "");
                return;
            }

            var mount = (Mount) drop_down.selected_item;

            var file = mount.get_default_location ();
            settings.set_string ("sync-location", file.get_uri ());
            SyncherService.get_default ().setup_synchronization (file);
        });
    }

    private void get_sync_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", (Gtk.Window) get_root (), SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                SyncherService.get_default ().setup_synchronization (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }
}
