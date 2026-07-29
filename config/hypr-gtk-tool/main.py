import gi
import subprocess

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

class HyprlandControl(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Hyprland Config Tool")
        self.set_border_width(10)

        button_reload = Gtk.Button(label="Reload Hyprland Config")
        button_reload.connect("clicked", self.reload_config)
        self.add(button_reload)

    def reload_config(self, widget):
        subprocess.run(["hyprctl", "reload"])

win = HyprlandControl()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
