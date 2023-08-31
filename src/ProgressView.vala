public class Syncher.ProgressView : Gtk.Box {
    construct {
        var back_button = new Gtk.Button.with_label (_("Back")) {
            visible = false
        };
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (back_button);

        var first_progress_widget = new ProgressWidget ("1");

        var second_progress_widget = new ProgressWidget ("2");

        var third_progress_widget = new ProgressWidget ("3");

        ProgressWidget[] progress_widgets = {first_progress_widget, second_progress_widget, third_progress_widget};

        var completed_stack = new Gtk.Stack ();
        completed_stack.add_named (new Gtk.Label ("<big>4</big>") { use_markup = true }, "step");
        completed_stack.add_named (new Gtk.Image.from_icon_name ("emblem-default") { pixel_size = 32 }, "emblem");

        var completed_label = new Gtk.Label (_("Completed"));

        var grid = new Gtk.Grid () {
            hexpand = true,
            valign = CENTER,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            row_spacing = 12,
            column_homogeneous = true
        };

        var handle = new Gtk.WindowHandle () {
            child = grid,
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

        back_button.clicked.connect (() => {
            ((Adw.Leaflet) get_ancestor (typeof (Adw.Leaflet))).navigate (BACK);
        });

        var settings = new GLib.Settings ("io.github.leolost2605.syncher");

        var syncher_service = SyncherService.get_default ();

        syncher_service.start_sync.connect ((sync_type) => {
            int[] needed_progress_widgets = {};

            if (settings.get_boolean ("sync-config")) {
                needed_progress_widgets += 0;
            }

            if (settings.get_boolean ("sync-apps")) {
                needed_progress_widgets += 1;
                needed_progress_widgets += 2;
            }

            if (sync_type == IMPORT) {
                first_progress_widget.label = _("Loading Configuration");
                second_progress_widget.label = _("Adding Software Sources");
                third_progress_widget.label = _("Installing Apps");
            } else {
                first_progress_widget.label = _("Saving Configuration");
                second_progress_widget.label = _("Saving Software Sources");
                third_progress_widget.label = _("Saving Apps");
            }

            int current = 0;
            foreach (var progress_widget_index in needed_progress_widgets) {
                var progress_widget = progress_widgets[progress_widget_index];

                grid.attach (progress_widget.stack, current + 1, 0, 1, 1);
                grid.attach (progress_widget.label_widget, current, 1, 3, 1);
                grid.attach (progress_widget.progress_bar, current + 2, 0, 3, 1);

                current += 4;
            }

            grid.attach (completed_stack, current + 1, 0, 1, 1);
            grid.attach (completed_label, current, 1, 3, 1);
        });

        syncher_service.finish_sync.connect (() => {
            completed_stack.set_visible_child_name ("emblem");
            back_button.visible = true;
        });

        unmap.connect (() => {
            grid.remove_row (0);
            grid.remove_row (0);

            completed_stack.set_visible_child_name ("step");
            first_progress_widget.fraction = 0;
            second_progress_widget.fraction = 0;
            third_progress_widget.fraction = 0;
            back_button.visible = false;
        });

        syncher_service.progress.connect ((step, percentage) => {
            switch (step) {
                case SAVING_CONFIGURATION:
                case LOADING_CONFIGURATION:
                    first_progress_widget.fraction = (double) percentage / 100;
                    break;

                case SAVING_REMOTES:
                case ADDING_REMOTES:
                    second_progress_widget.fraction = (double) percentage / 100;
                    break;

                case SAVING_FLATPAKS:
                case INSTALLING_FLATPAKS:
                    third_progress_widget.fraction = (double) percentage / 100;
                    break;
            }
        });
    }
}
