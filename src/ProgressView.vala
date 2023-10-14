public class Syncher.ProgressView : Gtk.Box {
    public Gtk.HeaderBar header_bar { get; construct; }

    private Gtk.Button back_button;
    private Gtk.Label completed_step_label;
    private Gtk.Stack completed_stack;
    private Gtk.Label completed_label;
    private Gtk.Grid grid;

    construct {
        back_button = new Gtk.Button () {
            valign = CENTER
        };
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (back_button);

        completed_step_label = new Gtk.Label (null) {
            use_markup = true
        };

        completed_stack = new Gtk.Stack ();
        completed_stack.add_named (completed_step_label, "step");
        completed_stack.add_named (new Gtk.Image.from_icon_name ("emblem-default") { pixel_size = 32 }, "emblem");

        completed_label = new Gtk.Label (_("Completed"));

        grid = new Gtk.Grid () {
            hexpand = true,
            valign = CENTER,
            row_spacing = 12,
            column_homogeneous = true
        };

        var label = new Gtk.Label (
            "<span size='xx-large'><b>%s</b></span>\n<span weight='light'>%s</span>".printf (
                _("Working…"),
                _("Depending on your internet connection and number of apps, this can take a while.")
            )
        ) {
            halign = CENTER,
            use_markup = true,
            justify = CENTER
        };

        var box = new Gtk.Box (VERTICAL, 24) {
            valign = CENTER,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        box.append (label);
        box.append (grid);

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

        var syncher_service = SyncherService.get_default ();

        back_button.clicked.connect (() => {
            if (syncher_service.working) {
                syncher_service.cancel ();
            }

            ((Adw.Leaflet) get_ancestor (typeof (Adw.Leaflet))).navigate (BACK);
        });

        update_working_state ();
        syncher_service.notify["working"].connect (update_working_state);

        syncher_service.fatal_error.connect ((step, msg, details) => {
            if (step != SETUP && step != PREPARING) {
                return;
            }

            grid.sensitive = false;
        });

        unmap.connect (() => {
            grid.sensitive = true;
            grid.remove_row (0);
            grid.remove_row (0);
            grid.remove_row (0);
        });
    }

    private void update_working_state () {
        var syncher_service = SyncherService.get_default ();

        if (!syncher_service.working) {
            completed_stack.set_visible_child_name ("emblem");
            back_button.label = _("Back");
            return;
        }

        completed_stack.set_visible_child_name ("step");

        back_button.label = _("Cancel");

        ProgressWidget[] progress_widgets = {};

        int step = 1;
        foreach (var module in syncher_service.modules) {
            if (!module.enabled) {
                continue;
            }

            progress_widgets += new ProgressWidget (module, step++, syncher_service.current_sync_type);
        }

        int current = 0;
        foreach (var progress_widget in progress_widgets) {
            grid.attach (progress_widget.stack, current + 1, 0, 1, 1);
            grid.attach (progress_widget.label_widget, current, 1, 3, 1);
            grid.attach (progress_widget.progress_bar, current + 2, 0, 3, 1);
            grid.attach (progress_widget.error_info, current + 1, 2, 1, 1);

            current += 4;
        }

        completed_step_label.label = "<big>%i</big>".printf (step);
        grid.attach (completed_stack, current + 1, 0, 1, 1);
        grid.attach (completed_label, current, 1, 3, 1);
    }
}
