public class Syncher.ModulePage : Gtk.Box, AbstractWelcomePage {
    public bool valid { get; protected set; default = false; }

    construct {
        var mounts = new ListStore (typeof (Mount));

        var image = new Gtk.Image.from_icon_name ("edit-find") {
            pixel_size = 128
        };

        var label = new Gtk.Label (
            "<span size='xx-large'><b>%s</b></span>\n<span weight='light'>%s</span>".printf (
                _("What to synchronize"),
                _("Next select the items you want to synchronize")
            )
        ) {
            halign = CENTER,
            use_markup = true,
            wrap = true,
            justify = CENTER
        };

        var top_box = new Gtk.Box (VERTICAL, 3) {
            halign = CENTER
        };
        top_box.append (image);
        top_box.append (label);

        var apps_label = new Gtk.Label (_("Apps")) {
            halign = END
        };

        var apps_switch = new Gtk.Switch () {
            halign = START,
            hexpand = true
        };
        settings.bind ("sync-apps", apps_switch, "active", DEFAULT);

        var config_label = new Gtk.Label (_("Settings")) {
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
            row_spacing = 12,
            halign = CENTER,
            column_homogeneous = true
        };
        grid.attach (apps_label, 0, 1);
        grid.attach (apps_switch, 1, 1);
        grid.attach (config_label, 0, 2);
        grid.attach (config_switch, 1, 2);

        valign = CENTER;
        orientation = VERTICAL;
        spacing = 24;
        append (top_box);
        append (grid);
    }
}
