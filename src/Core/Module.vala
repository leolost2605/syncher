public abstract class Syncher.Module : Object {
    // public signal void progress (int percentage); // This has to be emitted with 0 on start of import/export and with 100 on finish of import/export
    public signal void error (string msg, string details);
    public signal void fatal_error (string msg, string details = "");

    public string import_label { get; set; }
    public string export_label { get; set; }
    public int progress { get; protected set; default = 0; }
    public string id { get; set; }
    public bool enabled { get; set; default = true; }

    protected Cancellable cancellable;

    construct {
        cancellable = new Cancellable ();

        notify["progress"].connect (() => {
            if (progress == 0) {
                cancellable.reset ();
            }
        });

        fatal_error.connect ((msg, details) => {
            var app = (Application) GLib.Application.get_default ();

            if (!app.is_running_in_background ()) {
                return;
            }

            var notification = new Notification (_("An Error occured"));
            notification.set_body (msg);

            app.send_notification (null, notification);
        });
    }

    public abstract async void import (File file);
    public abstract async void export (File file);

    public void cancel () {
        cancellable.cancel ();
    }
}
