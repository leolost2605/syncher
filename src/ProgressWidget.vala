public class ProgressWidget : Object {
    public string step { get; construct; }
    public string label { get; set; default = "Task"; }
    public double fraction { get; set; default = 0; }

    public Gtk.Stack stack { get; construct; }
    public Gtk.Label label_widget { get; construct; }
    public Gtk.ProgressBar progress_bar { get; construct; }
    public Gtk.Revealer error_info { get; construct; }

    public string error_msg { get; set; }
    public string error_details { get; set; }

    public ProgressWidget (string step) {
        Object (step: step);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("emblem-default") {
            pixel_size = 32
        };

        var spinner = new Gtk.Spinner () {
            spinning = true
        };

        var step_label = new Gtk.Label ("<big>%s</big>".printf (step)) {
            use_markup = true
        };

        stack = new Gtk.Stack ();
        stack.add_child (step_label);
        stack.add_child (spinner);
        stack.add_child (image);

        label_widget = new Gtk.Label (label);
        bind_property ("label", label_widget, "label", SYNC_CREATE);

        progress_bar = new Gtk.ProgressBar () {
            hexpand = true,
            valign = CENTER
        };
        bind_property ("fraction", progress_bar, "fraction", SYNC_CREATE);

        notify["fraction"].connect (() => {
            if (fraction == 1) {
                stack.set_visible_child (image);
            } else if (fraction > 0) {
                stack.set_visible_child (spinner);
            } else {
                stack.set_visible_child (step_label);
            }
        });

        var error_info_button = new Gtk.Button.from_icon_name ("dialog-information-symbolic");

        error_info_button.clicked.connect (() => {
            var err_dialog = new Granite.MessageDialog (_("An Error occured"), error_msg, new ThemedIcon (":"));
            err_dialog.show_error_details (error_details);
            err_dialog.present ();
        });

        error_info = new Gtk.Revealer () {
            child = error_info_button,
            reveal_child = true
        };
    }

    public void reset () {
        fraction = 0;
        error_info.reveal_child = false;
    }
}
