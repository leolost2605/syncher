public class Syncher.PreferencesWindow : Gtk.Window {
    private Gtk.Label custom_location_label;

    public PreferencesWindow (Gtk.Window window) {
        Object (transient_for: window);
    }

    construct {
        var mounts = new ListStore (typeof (Mount));

        var location_label = new Granite.HeaderLabel (_("Location")) {
            secondary_text = _("Shared location used to synchronize your devices.")
        };

        var drop_down_checkbutton = new Gtk.CheckButton ();

        var factory = new Gtk.SignalListItemFactory ();

        var drop_down = new Gtk.DropDown (mounts, null) {
            hexpand = true,
            factory = factory
        };

        var custom_label = new Gtk.Label (_("Custom:"));

        var custom_check_button = new Gtk.CheckButton () {
            group = drop_down_checkbutton
        };

        custom_location_label = new Gtk.Label (_("Change Location…"));

        var custom_button_content = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        custom_button_content.append (new Gtk.Image.from_icon_name ("folder-open-symbolic"));
        custom_button_content.append (custom_location_label);

        var custom_button = new Gtk.Button () {
            valign = CENTER,
            child = custom_button_content
        };

        var custom_box = new Gtk.Box (HORIZONTAL, 6);
        custom_box.append (custom_label);
        custom_box.append (custom_button);

        var only_import_label = new Granite.HeaderLabel (_("Only Import")) {
            secondary_text = _("Never export this device configuration to the sync location. Can be useful if you want apps installed here to not show up on your other devices but their apps should still show up here.")
        };

        var only_import_switch = new Gtk.Switch () {
            valign = START
        };
        settings.bind ("only-import", only_import_switch, "active", DEFAULT);

        var only_import_box = new Gtk.Box (HORIZONTAL, 6) {
            margin_top = 12
        };
        only_import_box.append (only_import_label);
        only_import_box.append (only_import_switch);

        var grid = new Gtk.Grid () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            column_spacing = 6,
            row_spacing = 6
        };
        grid.attach (location_label, 0, 0, 2);
        grid.attach (drop_down_checkbutton, 0, 1);
        grid.attach (drop_down, 1, 1);
        grid.attach (custom_check_button, 0, 2);
        grid.attach (custom_box, 1, 2);
        grid.attach (only_import_box, 0, 3, 2);

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

        var modules_grid = new Gtk.Grid () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            column_spacing = 6,
            row_spacing = 6
        };
        modules_grid.attach (items_label, 0, 2, 2);
        modules_grid.attach (apps_label, 0, 3);
        modules_grid.attach (apps_switch, 1, 3);
        modules_grid.attach (config_label, 0, 4);
        modules_grid.attach (config_switch, 1, 4);

        var stack = new Gtk.Stack ();
        stack.add_titled (grid, null, _("General"));
        stack.add_titled (modules_grid, null, _("Modules"));

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

        drop_down_checkbutton.bind_property ("active", drop_down, "sensitive", SYNC_CREATE);
        custom_check_button.bind_property ("active", custom_box, "sensitive", SYNC_CREATE);

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
                    drop_down_checkbutton.active = true;
                    break;
                }
            }

            if (drop_down.selected == Gtk.INVALID_LIST_POSITION) {
                var file = File.new_for_uri (selected);
                custom_location_label.label = file.get_basename ();
                custom_check_button.active = true;
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

        custom_button.clicked.connect (get_sync_location);

        custom_check_button.toggled.connect (() => {
            if (!custom_check_button.active) {
                custom_location_label.label = _("Change Location…");
                settings.set_string ("sync-location", "");
            }
        });
    }

    private void get_sync_location () {
        var file_chooser = new Gtk.FileChooserNative (_("Choose location"), this, SELECT_FOLDER, _("Accept"), _("Cancel"));
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                custom_location_label.label = file.get_basename ();
                SyncherService.get_default ().setup_synchronization (file);
                settings.set_string ("sync-location", file.get_uri ());
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }
}
