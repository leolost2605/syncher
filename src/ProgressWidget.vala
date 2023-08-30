public class ProgressWidget : Object {
    public string label { get; set; default = "Task"; }
    public double fraction { get; set; default = 0; }

    public Gtk.Stack stack { get; construct; }
    public Gtk.Label label_widget { get; construct; }
    public Gtk.ProgressBar progress_bar { get; construct; }

    construct {
        var image = new Gtk.Image.from_icon_name ("emblem-default") {
            pixel_size = 32
        };

        var spinner = new Gtk.Spinner () {
            spinning = false
        };

        stack = new Gtk.Stack ();
        stack.add_named (image, "done");
        stack.add_named (spinner, "in-progress");

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
                spinner.spinning = true;
            } else {
                spinner.spinning = false;
            }
        });
    }
}
