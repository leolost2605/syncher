public abstract class Syncher.Module : Object {
    public signal void progress (int percentage); // This has to be emitted with 0 on start of import/export and with 100 on finish of import/export
    public signal void error (string msg, string details);
    public signal void fatal_error (string msg, string details = "");

    public string import_label { get; set; }
    public string export_label { get; set; }
    public string id { get; set; }
    public bool enabled { get; set; default = true; }

    protected Cancellable cancellable;

    construct {
        cancellable = new Cancellable ();

        progress.connect ((percentage) => {
            if (percentage == 0) {
                cancellable.reset ();
            }
        });
    }

    public abstract async void import (File file);
    public abstract async void export (File file);

    public void cancel () {
        cancellable.cancel ();
    }
}
