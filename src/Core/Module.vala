public interface Syncher.Module : Object {
    public signal void progress (int percentage);
    public signal void error (string msg, string details);
    public signal void fatal_error (string msg, string details = "");

    public abstract string import_label { get; set; }
    public abstract string export_label { get; set; }
    public abstract string id { get; set; }
    public abstract bool enabled { get; set; }

    public abstract async void import (File file);
    public abstract async void export (File file);
}
