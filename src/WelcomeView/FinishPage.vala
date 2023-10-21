public class Syncher.FinishPage : Gtk.Box, AbstractWelcomePage {
    public bool valid { get; protected set; default = true; }

    construct {
        var emblem = new Gtk.Image.from_icon_name ("preferences-system") {
            halign = END,
            valign = END,
            pixel_size = 64
        };

        var image = new Gtk.Image.from_icon_name ("application-x-executable") {
            pixel_size = 128
        };

        var image_overlay = new Gtk.Overlay () {
            child = image,
            halign = CENTER
        };
        image_overlay.add_overlay (emblem);

        var label = new Gtk.Label (
            "<span size='xx-large'><b>%s</b></span>\n<span weight='light'>%s</span>".printf (
                _("Finish"),
                _("Let's go!.")
            )
        ) {
            halign = CENTER,
            use_markup = true,
            wrap = true,
            justify = CENTER
        };

        halign = CENTER;
        valign = CENTER;
        orientation = VERTICAL;
        spacing = 3;

        append (image_overlay);
        append (label);
    }
}
