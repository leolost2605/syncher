// Below all pages in light weight font: All settings can be changed later from the app menu.

// Page 1:

// To synchronize your devices first choose a file location where all you devices have access to. This can be for example a WebDav server but also a USB-Stick that you move between your devices. Connecting to a server can be easily done using most file browsers for example elementary's pre-installed Files. The current version of Syncher will use approximately 1MB of space.
// Connected volumes will automatically show up here:
// Want to select a specific location? Choose a custom sync location:

// Need help? Click for a detailed setup guide.

// Page 2:

// Next select the items you want to synchronize:
// Apps
// Settings

// Page 3:

// Last warnings
// Warning: This is not a replacement for a backup solution for your files. In fact this doesn't synchronize any files.
// Warning 2: Depending on how often you have no internet connection on a device this might sync outdated settings. However it will never uninstall any applications. Be sure to report any unexpected issues that arise.

// Click for more details of what Syncher does and doesn't do.

public class Syncher.WelcomeView : Gtk.Box {
    public signal void finished ();

    private Adw.Carousel carousel;
    private Gtk.Button next_button;

    construct {
        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

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
                _("Follow the instructions below to get Syncher up and running and out of your way for seamless integration between your devices.")
            )
        ) {
            halign = CENTER,
            use_markup = true,
            justify = CENTER
        };

        var top_box = new Gtk.Box (VERTICAL, 3) {
            halign = CENTER
        };
        top_box.append (image_overlay);
        top_box.append (label);

        var location_page = new LocationPage ();

        var module_page = new ModulePage ();

        carousel = new Adw.Carousel () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            hexpand = true,
            vexpand = true,
            halign = CENTER
        };
        carousel.append (location_page);
        carousel.append (module_page);

        var help_link = new Gtk.LinkButton.with_label ("https://github.com/leolost2605/syncher/wiki/First-Setup-Guide", _("Need help?"));

        var indicator = new Adw.CarouselIndicatorDots ();
        indicator.carousel = carousel;

        next_button = new Gtk.Button.with_label (_("Next")) {
            halign = END,
            width_request = 86,
            sensitive = false
        };
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var bottom_box = new Gtk.CenterBox ();
        bottom_box.set_start_widget (help_link);
        bottom_box.set_center_widget (indicator);
        bottom_box.set_end_widget (next_button);

        var box = new Gtk.Box (VERTICAL, 24) {
            hexpand = true,
            vexpand = true,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        box.append (carousel);
        box.append (bottom_box);

        var handle = new Gtk.WindowHandle () {
            child = box,
            vexpand = true
        };

        var overlay = new Gtk.Overlay () {
            child = handle
        };
        overlay.add_overlay (header_bar);

        hexpand = true;
        vexpand = true;
        orientation = VERTICAL;
        append (overlay);

        next_button.bind_property ("sensitive", carousel, "interactive", SYNC_CREATE);

        next_button.clicked.connect (() => {
            var current = (int) carousel.position;
            carousel.scroll_to (carousel.get_nth_page (current + 1), true);
        });

        location_page.notify["valid"].connect (() => {
            if (carousel.get_nth_page ((int) carousel.position) != location_page) {
                return;
            }

            next_button.sensitive = location_page.valid;
        });

        module_page.notify["valid"].connect (() => {
            if (carousel.get_nth_page ((int) carousel.position) != module_page) {
                return;
            }

            next_button.sensitive = module_page.valid;
        });
    }

    private void get_sync_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", (Gtk.Window) get_root (), SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                SyncherService.get_default ().sync.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }
}
