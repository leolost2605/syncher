public abstract class Syncher.Module : Object {
    public class DetailedError : Object {
        public string msg { get; construct; }
        public string details { get; construct; }
        public bool fatal { get; construct; }

        public DetailedError (string msg, string details, bool fatal = false) {
            Object (
                msg: msg,
                details: details,
                fatal: fatal
            );
        }
    }

    public string import_label { get; set; }
    public string export_label { get; set; }
    public int progress { get; protected set; default = 0; }
    public string id { get; set; }
    public bool enabled { get; set; default = true; }
    public ListStore errors { get; construct; }

    protected Cancellable cancellable;

    construct {
        cancellable = new Cancellable ();
        errors = new ListStore (typeof (DetailedError));

        var syncher_service = SyncherService.get_default ();
        syncher_service.notify["working"].connect (() => {
            if (syncher_service.working) {
                progress = 0;
                cancellable.reset ();
                errors.remove_all ();
            }
        });
    }

    public abstract async void import (File file);
    public abstract async void export (File file);

    public void cancel () {
        cancellable.cancel ();
    }

    protected void error (string message, string details) {
        var error = new DetailedError (message, details);
        errors.append (error);
    }

    protected void fatal_error (string message, string details = "") {
        var error = new DetailedError (message, details, true);
        errors.append (error);

        var app = (Application) GLib.Application.get_default ();

        if (!app.is_running_in_background ()) {
            return;
        }

        var notification = new Notification (_("An Error occured"));
        notification.set_body (message);

        app.send_notification (null, notification);
    }
}
