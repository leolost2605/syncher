public class Syncher.WelcomePage : Gtk.Box, AbstractWelcomePage {
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
                _("Welcome"),
                _("Follow the instructions to get Syncher up and running and out of your way for seamless integration between your devices! If you are new to Linux it is recommended to use the detailed First Setup Guide by clicking 'Need Help?'.")
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
