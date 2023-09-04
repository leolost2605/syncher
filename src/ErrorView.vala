public class Syncher.ErrorView : Gtk.Box {
    private const string LABEL_MARKUP = "<span size='xx-large'><b>%s</b></span>\n<span weight='light'>%s</span>";

    private Gtk.Label label;

    construct {
        var menu = new Menu ();
        menu.append (_("Preferences"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_PREFERENCES);

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu",
            menu_model = menu,
            primary = true,
            tooltip_markup = Granite.markup_accel_tooltip ({"F10"}, "Menu")
        };
        menu_button.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_end (menu_button);

        var emblem = new Gtk.Image.from_icon_name ("dialog-error") {
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

        label = new Gtk.Label ("") {
            halign = CENTER,
            use_markup = true,
            justify = CENTER
        };

        var top_box = new Gtk.Box (VERTICAL, 3) {
            halign = CENTER
        };
        top_box.append (image_overlay);
        top_box.append (label);

        var spinner = new Gtk.Spinner () {
            spinning = true
        };

        var retry_icon = new Gtk.Image.from_icon_name ("view-refresh-symbolic");

        var preparing_stack = new Gtk.Stack () {
            transition_type = CROSSFADE
        };
        preparing_stack.add_child (retry_icon);
        preparing_stack.add_child (spinner);

        var retry_button_content = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        retry_button_content.append (preparing_stack);
        retry_button_content.append (new Gtk.Label (_("Retry")));

        var retry_button = new Gtk.Button () {
            child = retry_button_content,
            valign = CENTER
        };
        retry_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var change_button_content = new Gtk.Box (HORIZONTAL, 3) {
            halign = CENTER
        };
        change_button_content.append (new Gtk.Image.from_icon_name ("folder-open-symbolic"));
        change_button_content.append (new Gtk.Label (_("Change Location…")));

        var change_button = new Gtk.Button () {
            valign = CENTER,
            child = change_button_content,
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_PREFERENCES
        };

        var bottom_box = new Gtk.Box (HORIZONTAL, 12) {
            halign = CENTER,
            homogeneous = true
        };
        bottom_box.append (change_button);
        bottom_box.append (retry_button);

        var box = new Gtk.Box (VERTICAL, 24) {
            halign = CENTER,
            valign = CENTER,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        box.append (top_box);
        box.append (bottom_box);

        var handle = new Gtk.WindowHandle () {
            child = box,
            vexpand = true
        };

        var toast = new Granite.Toast (_("Synchronization Failed"));

        var overlay = new Gtk.Overlay () {
            child = handle
        };
        overlay.add_overlay (header_bar);
        overlay.add_overlay (toast);

        hexpand = true;
        vexpand = true;
        orientation = VERTICAL;
        append (overlay);

        map.connect (() => {
            var window = (Gtk.Window) get_root ();
            window.default_widget = retry_button;
        });

        var syncher_service = SyncherService.get_default ();

        retry_button.clicked.connect (() => {
            preparing_stack.visible_child = spinner;
            syncher_service.sync ();
        });

        syncher_service.finish_sync.connect (() => {
            preparing_stack.visible_child = retry_icon;
        });

        syncher_service.fatal_error.connect ((step, msg, details) => {
            toast.send_notification ();
            preparing_stack.visible_child = retry_icon;
        });

        syncher_service.notify["error-state"].connect (update_error_state);
        update_error_state ();
    }

    private void update_error_state () {
        if (SyncherService.get_default ().error_state == null) {
            return;
        }

        label.label = "<span size='xx-large'><b>%s</b></span>\n<span weight='light'>%s</span>".printf (
            _("A Fatal Error Occured"),
            _(SyncherService.get_default ().error_state.message)
        );
    }
}
