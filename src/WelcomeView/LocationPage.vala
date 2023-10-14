public class Syncher.LocationPage : Gtk.Grid, AbstractWelcomePage {
    public bool valid { get; protected set; default = false; }

    construct {
        var mounts = new ListStore (typeof (Mount));

        var image = new Gtk.Image.from_icon_name ("folder-remote") {
            pixel_size = 128
        };

        var label = new Gtk.Label (
            "<span size='xx-large'><b>%s</b></span>\n<span weight='light'>%s</span>".printf (
                _("Synchronization Location"),
                _("To synchronize your devices first choose a file location where all you devices have access to. This can be for example a WebDav server but also a USB-Stick that you move between your devices. Connecting to a server can be easily done using most file browsers for example elementary's pre-installed Files. The current version of Syncher will use approximately 1MB of space.")
            )
        ) {
            halign = CENTER,
            use_markup = true,
            wrap = true,
            justify = CENTER
        };

        var top_box = new Gtk.Box (VERTICAL, 3) {
            halign = CENTER,
            margin_bottom = 24
        };
        top_box.append (image);
        top_box.append (label);

        var drop_down_checkbutton = new Gtk.CheckButton ();

        var drop_down_label = new Gtk.Label (_("Connected volumes will automatically show up here: ")) {
            halign = START
        };

        var factory = new Gtk.SignalListItemFactory ();

        var drop_down = new Gtk.DropDown (mounts, null) {
            hexpand = true,
            factory = factory
        };

        var drop_down_box = new Gtk.Box (VERTICAL, 3);
        drop_down_box.append (drop_down_label);
        drop_down_box.append (drop_down);

        var custom_check_button = new Gtk.CheckButton () {
            group = drop_down_checkbutton
        };

        var custom_location_label = new Gtk.Label (_("Change Location…")) {
            ellipsize = MIDDLE
        };

        var custom_button_content = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        custom_button_content.append (new Gtk.Image.from_icon_name ("folder-open-symbolic"));
        custom_button_content.append (custom_location_label);

        var custom_button = new Gtk.Button () {
            valign = CENTER,
            child = custom_button_content
        };

        var custom_box = new Gtk.Box (VERTICAL, 3);
        custom_box.append (new Gtk.Label (_("Want to select a specific location? Choose a custom sync location:")) { halign = START });
        custom_box.append (custom_button);

        margin_top = 12;
        margin_bottom = 12;
        margin_start = 12;
        margin_end = 12;
        column_spacing = 6;
        row_spacing = 12;
        valign = CENTER;
        attach (top_box, 0, 0, 2);
        attach (drop_down_checkbutton, 0, 1);
        attach (drop_down_box, 1, 1);
        attach (custom_check_button, 0, 2);
        attach (custom_box, 1, 2);

        drop_down_checkbutton.bind_property ("active", drop_down_box, "sensitive", SYNC_CREATE);
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

        drop_down.notify["selected"].connect (() => {
            if (drop_down.selected == Gtk.INVALID_LIST_POSITION) {
                settings.set_string ("sync-location", "");
                valid = false;
                return;
            }

            var mount = (Mount) drop_down.selected_item;

            var file = mount.get_default_location ();
            settings.set_string ("sync-location", file.get_uri ());
            valid = true;
        });

        custom_button.clicked.connect (() => {
            var file_chooser = new Gtk.FileChooserNative (_("Choose location"), (Gtk.Window) get_root (), SELECT_FOLDER, _("Accept"), _("Cancel"));
            file_chooser.response.connect ((res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    var file = file_chooser.get_file ();
                    custom_location_label.label = file.get_basename ();
                    settings.set_string ("sync-location", file.get_uri ());
                    valid = true;
                }
                file_chooser.destroy ();
            });

            file_chooser.show ();
        });

        custom_check_button.toggled.connect (() => {
            if (!custom_check_button.active) {
                custom_location_label.label = _("Change Location…");
                settings.set_string ("sync-location", "");
                valid = false;
            }
        });
    }
}
