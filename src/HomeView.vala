public class Syncher.HomeView : Gtk.Box {
    construct {
        var header_bar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Grid (),
            hexpand = true,
            valign = START
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var image = new Gtk.Image.from_icon_name ("emblem-default") {
            pixel_size = 64
        };

        var label = new Gtk.Label (_("<big><b>Nothing to do</b></big>\nYou're up to date")) {
            halign = CENTER,
            use_markup = true,
            justify = CENTER
        };

        var button_content = new Gtk.Box (HORIZONTAL, 3);
        button_content.append (new Gtk.Image.from_icon_name ("sync-synchronizing-symbolic"));
        button_content.append (new Gtk.Label (_("Synchronize Now")));

        var sync_now = new Gtk.Button () {
            halign = CENTER,
            child = button_content
        };

        var preparing_sync = new Gtk.Box (HORIZONTAL, 12) {
            halign = CENTER
        };
        preparing_sync.append (new Gtk.Spinner () {spinning = true});
        preparing_sync.append (new Gtk.Label (_("Preparing sync...")));

        var sync_now_stack = new Gtk.Stack () {
            margin_top = 12
        };
        sync_now_stack.add_child (sync_now);
        sync_now_stack.add_child (preparing_sync);

        // var placeholder_box = new Gtk.Box (VERTICAL, 12);
        // placeholder_box.append (placeholder);
        // placeholder_box.append (sync_now_stack);

        // var first_progress_widget = new ProgressWidget ();

        // var second_progress_widget = new ProgressWidget ();

        // var progress = new Gtk.Box (HORIZONTAL, 12) {
        //     valign = CENTER
        // };
        // progress.append (first_progress_widget);
        // progress.append (second_progress_widget);

        // var stack = new Gtk.Stack () {
        //     transition_type = CROSSFADE
        // };
        // stack.add_child (placeholder_box);
        // stack.add_child (progress);

        var box = new Gtk.Box (VERTICAL, 12) {
            halign = CENTER,
            valign = CENTER,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        box.append (image);
        box.append (label);
        box.append (sync_now_stack);

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

        sync_now.clicked.connect (() => {
            sync_now_stack.visible_child = preparing_sync;
            get_sync_location ();
        });

        var syncher_service = SyncherService.get_default ();

        syncher_service.finish_sync.connect (() => {
            sync_now_stack.visible_child = sync_now;
        });

        // syncher_service.start_sync.connect ((sync_type) => {
        //     stack.visible_child = progress;

        //     if (sync_type == IMPORT) {
        //         first_progress_widget.label = _("Installing Apps");
        //         second_progress_widget.label = _("Loading Configuration");
        //     } else {
        //         first_progress_widget.label = _("Saving Apps");
        //         second_progress_widget.label = _("Saving Configuration");
        //     }
        // });

        // syncher_service.finish_sync.connect (() => {
        //     stack.visible_child = placeholder_box;
        //     sync_now_stack.visible_child = sync_now;
        //     first_progress_widget.fraction = 0;
        //     second_progress_widget.fraction = 0;
        // });

        // syncher_service.progress.connect ((step, percentage) => {
        //     if (step == INSTALLING_FLATPAKS || step == SAVING_FLATPAKS) {
        //         first_progress_widget.fraction = (double) percentage / 100;
        //     } else {
        //         second_progress_widget.fraction = (double) percentage / 100;
        //     }
        // });
    }

    private void get_sync_location () {
        var file_chooser = new Gtk.FileChooserNative ("Choose location", (Gtk.Window) get_root (), SELECT_FOLDER, "Accept", "Cancel");
        file_chooser.response.connect ((res) => {
            if (res == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser.get_file ();
                SyncherService.get_default ().sync.begin (file);
            }
            file_chooser.destroy ();
        });

        file_chooser.show ();
    }
}
