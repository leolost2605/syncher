public class Syncher.HomeView : Gtk.Box {
    construct {
        var header_bar = new Gtk.HeaderBar ();
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var placeholder = new Granite.Placeholder (_("Nothing to do!")) {
            description = _("Everything is up to date"),
            icon = new ThemedIcon ("emblem-default"),
            vexpand = true
        };

        var sync_now = new Gtk.Button.with_label (_("Sync now")) {
            halign = CENTER,
            margin_bottom = 36
        };

        var preparing_sync = new Gtk.Box (HORIZONTAL, 12) {
            halign = CENTER,
            margin_bottom = 36
        };
        preparing_sync.append (new Gtk.Spinner () {spinning = true});
        preparing_sync.append (new Gtk.Label (_("Preparing sync...")));

        var sync_now_stack = new Gtk.Stack ();
        sync_now_stack.add_child (sync_now);
        sync_now_stack.add_child (preparing_sync);

        var placeholder_box = new Gtk.Box (VERTICAL, 12);
        placeholder_box.append (placeholder);
        placeholder_box.append (sync_now_stack);

        var first_progress_widget = new ProgressWidget ();

        var second_progress_widget = new ProgressWidget ();

        var progress = new Gtk.Box (HORIZONTAL, 12) {
            valign = CENTER
        };
        progress.append (first_progress_widget);
        progress.append (second_progress_widget);

        var stack = new Gtk.Stack () {
            transition_type = CROSSFADE
        };
        stack.add_child (placeholder_box);
        stack.add_child (progress);

        spacing = 12;
        orientation = VERTICAL;
        hexpand = true;
        vexpand = true;
        append (header_bar);
        append (stack);

        sync_now.clicked.connect (() => {
            sync_now_stack.visible_child = preparing_sync;
            get_sync_location ();
        });

        var syncher_service = SyncherService.get_default ();

        syncher_service.start_sync.connect ((sync_type) => {
            stack.visible_child = progress;

            if (sync_type == IMPORT) {
                first_progress_widget.label = _("Installing Apps");
                second_progress_widget.label = _("Loading Configuration");
            } else {
                first_progress_widget.label = _("Saving Apps");
                second_progress_widget.label = _("Saving Configuration");
            }
        });

        syncher_service.finish_sync.connect (() => {
            stack.visible_child = placeholder_box;
            sync_now_stack.visible_child = sync_now;
            first_progress_widget.fraction = 0;
            second_progress_widget.fraction = 0;
        });

        syncher_service.progress.connect ((step, percentage) => {
            if (step == INSTALLING_FLATPAKS || step == SAVING_FLATPAKS) {
                first_progress_widget.fraction = (double) percentage / 100;
            } else {
                second_progress_widget.fraction = (double) percentage / 100;
            }
        });
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
