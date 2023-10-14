public class Syncher.ProgressWidget : Object {
    public Syncher.Module module { get; construct; }
    public int step { get; construct; }
    public SyncherService.SyncType sync_type { get; construct; }

    public Gtk.Stack stack { get; construct; }
    public Gtk.Label label_widget { get; construct; }
    public Gtk.ProgressBar progress_bar { get; construct; }
    public Gtk.Revealer error_info { get; construct; }

    private Gtk.ListBox error_dialog_list;

    public ProgressWidget (Module module, int step, SyncherService.SyncType sync_type) {
        Object (
            module: module,
            step: step,
            sync_type: sync_type
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("emblem-default") {
            pixel_size = 32
        };

        var spinner = new Gtk.Spinner () {
            spinning = true
        };

        var step_label = new Gtk.Label ("<big>%i</big>".printf (step)) {
            use_markup = true
        };

        var fatal_image = new Gtk.Image.from_icon_name ("dialog-error") {
            pixel_size = 32
        };

        stack = new Gtk.Stack ();
        stack.add_child (step_label);
        stack.add_named (spinner, "spinner");
        stack.add_named (image, "image");
        stack.add_named (fatal_image, "fatal");

        label_widget = new Gtk.Label (sync_type == IMPORT ? module.import_label : module.export_label);

        progress_bar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = CENTER
        };

        var error_info_button = new Gtk.Button.from_icon_name ("dialog-information-symbolic");
        error_info_button.add_css_class (Granite.STYLE_CLASS_ERROR);

        error_info = new Gtk.Revealer () {
            child = error_info_button,
            reveal_child = false
        };

        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Label ("Error!")
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        error_dialog_list = new Gtk.ListBox () {
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3
        };
        error_dialog_list.add_css_class (Granite.STYLE_CLASS_BACKGROUND);

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = error_dialog_list,
            hexpand = true,
            vexpand = true
        };

        var error_dialog = new Gtk.Window () {
            child = scrolled_window,
            titlebar = header_bar,
            default_height = 400,
            default_width = 300
        };

        var syncher_service = SyncherService.get_default ();

        update_progress ();
        module.notify["progress"].connect (update_progress);

        module.error.connect ((msg, details) => {
            error_info.reveal_child = true;

            add_error_details (msg, details);
        });

        module.fatal_error.connect ((msg, details) => {
            stack.set_visible_child (fatal_image);
            error_info.reveal_child = true;
            progress_bar.sensitive = false;

            add_error_details (msg, details, true);
        });

        progress_bar.unmap.connect (() => {
            progress_bar.sensitive = true;
            progress_bar.fraction = 0;
            error_info.reveal_child = false;
            stack.set_visible_child (step_label);
        });

        error_info_button.clicked.connect (() => {
            error_dialog.present ();
        });
    }

    private void update_progress () {
        progress_bar.fraction = (double) module.progress / 100;

        if (stack.visible_child_name == "fatal") {
            return;
        }

        if (module.progress == 100) {
            stack.set_visible_child_name ("image");
        } else if (module.progress > 0) {
            stack.set_visible_child_name ("spinner");
        }
    }

    private void add_error_details (string msg, string details, bool fatal = false) {
        var details_label = new Gtk.Label (details) {
            wrap = true,
            wrap_mode = WORD_CHAR
        };
        details_label.add_css_class (Granite.STYLE_CLASS_TERMINAL);

        var expander = new Gtk.Expander (fatal ? _("Fatal error: %s").printf (msg) : msg) {
            child = details_label,
            hexpand = true,
            margin_top = 3,
            margin_bottom = 3
        };

        error_dialog_list.append (expander);
    }
}
