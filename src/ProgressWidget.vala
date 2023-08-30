public class ProgressWidget : Gtk.Grid {
    public string label { get; set; default = "Task"; }
    public double fraction { get; set; default = 0; }

    private Gtk.Stack stack;

    construct {
        var image = new Gtk.Image.from_icon_name ("emblem-default");

        var to_do = new Gtk.Image.from_icon_name ("sync-synchronizing-symbolic");

        var spinner = new Gtk.Spinner () {
            spinning = true
        };

        stack = new Gtk.Stack ();
        stack.add_named (to_do, "to-do");
        stack.add_named (image, "done");
        stack.add_named (spinner, "in-progress");

        var label = new Gtk.Label (label);
        bind_property ("label", label, "label", SYNC_CREATE);

        var progress_bar = new Gtk.ProgressBar () {
            hexpand = true
        };
        bind_property ("fraction", progress_bar, "fraction", SYNC_CREATE);

        attach (stack, 0, 0);
        attach (label, 0, 1);
        attach (progress_bar, 1, 0, 2);

        notify["fraction"].connect (() => {
            if (fraction == 1) {
                stack.set_visible_child (image);
            } else if (fraction > 0) {
                stack.set_visible_child (spinner);
            } else {
                stack.set_visible_child (to_do);
            }
        });
    }
}
