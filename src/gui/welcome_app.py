import sys
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class AribaWelcome(Gtk.Window):
    def __init__(self):
        super().__init__(title="Welcome to Ariba OS")
        self.set_border_width(20)
        self.set_default_size(600, 400)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Header
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        self.add(vbox)

        label_title = Gtk.Label()
        label_title.set_markup("<span font='24' weight='bold'>Welcome to Ariba OS</span>")
        vbox.pack_start(label_title, False, False, 10)

        label_desc = Gtk.Label(label="A modern, AI-assisted Linux experience.")
        vbox.pack_start(label_desc, False, False, 5)

        # Buttons
        grid = Gtk.Grid()
        grid.set_column_spacing(20)
        grid.set_row_spacing(20)
        grid.set_halign(Gtk.Align.CENTER)
        vbox.pack_start(grid, True, True, 20)

        btn_tute = Gtk.Button(label="AI Tutorial")
        btn_tute.connect("clicked", self.on_tutorial_clicked)
        btn_tute.set_size_request(150, 50)
        grid.attach(btn_tute, 0, 0, 1, 1)

        btn_cust = Gtk.Button(label="Customize Look")
        btn_cust.connect("clicked", self.on_customize_clicked)
        btn_cust.set_size_request(150, 50)
        grid.attach(btn_cust, 1, 0, 1, 1)

        btn_docs = Gtk.Button(label="Read Docs")
        btn_docs.connect("clicked", self.on_docs_clicked)
        btn_docs.set_size_request(150, 50)
        grid.attach(btn_docs, 0, 1, 1, 1)

        btn_close = Gtk.Button(label="Get Started")
        btn_close.connect("clicked", Gtk.main_quit)
        btn_close.set_size_request(150, 50)
        grid.attach(btn_close, 1, 1, 1, 1)

    def on_tutorial_clicked(self, widget):
        print("Launching AI Tutorial...")
        # In real OS: subprocess.Popen(["ariba-ai", "--tutorial"])

    def on_customize_clicked(self, widget):
        print("Opening Appearance Settings...")
        # In real OS: subprocess.Popen(["xfce4-appearance-settings"])

    def on_docs_clicked(self, widget):
        print("Opening Documentation...")
        # In real OS: subprocess.Popen(["xdg-open", "/usr/share/doc/ariba/README"])

win = AribaWelcome()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
