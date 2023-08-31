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
        grid.attach (first_progress_widget.stack, 1, 0, 1, 1);
        grid.attach (first_progress_widget.label_widget, 0, 1, 3, 1);
        grid.attach (first_progress_widget.progress_bar, 2, 0, 3, 1);
        grid.attach (second_progress_widget.stack, 5, 0, 1, 1);
        grid.attach (second_progress_widget.label_widget, 4, 1, 3, 1);
        grid.attach (second_progress_widget.progress_bar, 6, 0, 3, 1);
        grid.attach (third_progress_widget.stack, 9, 0, 1, 1);
        grid.attach (third_progress_widget.label_widget, 8, 1, 3, 1);
        grid.attach (third_progress_widget.progress_bar, 10, 0, 3, 1);

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
            first_progress_widget.visible = settings.get_boolean ("sync-config");
            second_progress_widget.visible = settings.get_boolean ("sync-apps");
            third_progress_widget.visible = settings.get_boolean ("sync-apps");

            if (settings.get_boolean ("sync-apps")) {
                grid.attach (completed_stack, 13, 0, 1, 1);
                grid.attach (completed_label, 12, 1, 3, 1);
            } else {
                grid.attach (completed_stack, 5, 0, 1, 1);
                grid.attach (completed_label, 4, 1, 3, 1);
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
        });

        syncher_service.finish_sync.connect (() => {
            completed_stack.set_visible_child_name ("emblem");
            back_button.visible = true;
        });

        unmap.connect (() => {
            grid.remove (completed_stack);
            grid.remove (completed_label);

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
