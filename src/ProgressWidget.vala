public class ProgressWidget : Object {
    public string step { get; construct; }
    public string label { get; set; default = "Task"; }
    public double fraction { get; set; default = 0; }
    public bool visible { get; set; }

    public Gtk.Stack stack { get; construct; }
    public Gtk.Label label_widget { get; construct; }
    public Gtk.ProgressBar progress_bar { get; construct; }

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

        bind_property ("visible", stack, "visible", SYNC_CREATE);
        bind_property ("visible", label_widget, "visible", SYNC_CREATE);
        bind_property ("visible", progress_bar, "visible", SYNC_CREATE);

        notify["fraction"].connect (() => {
            if (fraction == 1) {
                stack.set_visible_child (image);
            } else if (fraction > 0) {
                stack.set_visible_child (spinner);
            } else {
                stack.set_visible_child (step_label);
            }
        });
    }
}
