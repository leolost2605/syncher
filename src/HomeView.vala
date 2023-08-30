public class Syncher.HomeView : Gtk.Box {
    construct {
        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var emblem = new Gtk.Image.from_icon_name ("emblem-default") {
            halign = END,
            valign = END,
            pixel_size = 64
        };

        var image = new Gtk.Image.from_icon_name ("sync-synchronizing-symbolic") {
            pixel_size = 128
        };

        var image_overlay = new Gtk.Overlay () {
            child = image,
            halign = CENTER
        };
        image_overlay.add_overlay (emblem);

        var label = new Gtk.Label (_("<span size='xx-large'><b>Nothing to do!</b></span>\nYou're all synchronized. To manually start a new synchronization click the button below.")) {
            halign = CENTER,
            use_markup = true,
            justify = CENTER
        };

        var button_content = new Gtk.Box (HORIZONTAL, 3);
        button_content.append (new Gtk.Image.from_icon_name ("sync-synchronizing-symbolic"));
        button_content.append (new Gtk.Label (_("Synchronize Now")));

        var sync_now = new Gtk.Button () {
            halign = CENTER,
            child = button_content
        };

        var preparing_sync = new Gtk.Box (HORIZONTAL, 12) {
            halign = CENTER
        };
        preparing_sync.append (new Gtk.Spinner () {spinning = true});
        preparing_sync.append (new Gtk.Label (_("Preparing sync...")));

        var sync_now_stack = new Gtk.Stack () {
            margin_top = 12
        };
        sync_now_stack.add_child (sync_now);
        sync_now_stack.add_child (preparing_sync);

        var box = new Gtk.Box (VERTICAL, 12) {
            halign = CENTER,
            valign = CENTER,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        box.append (image_overlay);
        box.append (label);
        box.append (sync_now_stack);

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

        sync_now.clicked.connect (() => {
            sync_now_stack.visible_child = preparing_sync;
            get_sync_location ();
        });

        var syncher_service = SyncherService.get_default ();

        syncher_service.finish_sync.connect (() => {
            sync_now_stack.visible_child = sync_now;
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
