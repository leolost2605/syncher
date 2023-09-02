public class Syncher.ProgressWidget : Object {
    public SyncherService.ProgressStep step { get; construct; }
    public string label { get; set; default = "Task"; }

    public Gtk.Stack stack { get; construct; }
    public Gtk.Label label_widget { get; construct; }
    public Gtk.ProgressBar progress_bar { get; construct; }
    public Gtk.Revealer error_info { get; construct; }

    private Gtk.ListBox error_dialog_list;

    public ProgressWidget (SyncherService.ProgressStep step) {
        Object (step: step);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("emblem-default") {
            pixel_size = 32
        };

        var spinner = new Gtk.Spinner () {
            spinning = true
        };

        var step_label = new Gtk.Label ("<big>%i</big>".printf (step + 1)) {
            use_markup = true
        };

        var fatal_image = new Gtk.Image.from_icon_name ("dialog-error") {
            pixel_size = 32
        };

        stack = new Gtk.Stack ();
        stack.add_child (step_label);
        stack.add_child (spinner);
        stack.add_child (image);
        stack.add_child (fatal_image);

        label_widget = new Gtk.Label (label);
        bind_property ("label", label_widget, "label", SYNC_CREATE);

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

        syncher_service.start_sync.connect (() => {
            // error_dialog_list.remove_all ();
        });

        syncher_service.progress.connect ((_step, percentage) => {
            if (_step != step) {
                return;
            }

            progress_bar.fraction = (double) percentage / 100;

            if (stack.visible_child == fatal_image) {
                return;
            }

            if (percentage == 100) {
                stack.set_visible_child (image);
            } else if (percentage > 0) {
                stack.set_visible_child (spinner);
            }
        });

        syncher_service.error.connect ((_step, msg, details) => {
            if (_step != step) {
                return;
            }

            error_info.reveal_child = true;

            add_error_details (msg, details);
        });

        syncher_service.fatal_error.connect ((_step, msg, details) => {
            if (_step != step) {
                return;
            }

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
