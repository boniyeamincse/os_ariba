import gi
import subprocess
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Pango

class AribaStore(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ariba Software Center")
        self.set_border_width(10)
        self.set_default_size(800, 600)

        # Main Layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(main_box)

        # Header
        header = Gtk.HeaderBar()
        header.set_show_close_button(True)
        header.props.title = "Software Center"
        self.set_titlebar(header)

        # Search Bar
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.entry = Gtk.SearchEntry()
        self.entry.set_placeholder_text("Search packages or ask AI...")
        self.entry.connect("activate", self.on_search)
        search_box.pack_start(self.entry, True, True, 0)
        main_box.pack_start(search_box, False, False, 0)

        # AI Recommendations Area
        lbl_rec = Gtk.Label(label="<b>AI Recommendations</b>", use_markup=True, xalign=0)
        main_box.pack_start(lbl_rec, False, False, 10)

        self.rec_grid = Gtk.Grid()
        self.rec_grid.set_column_spacing(10)
        self.rec_grid.set_row_spacing(10)
        main_box.pack_start(self.rec_grid, False, False, 0)

        # Content Area (List of Apps)
        self.scroll = Gtk.ScrolledWindow()
        self.scroll.set_vexpand(True)
        main_box.pack_start(self.scroll, True, True, 0)

        self.app_list = Gtk.ListBox()
        self.scroll.add(self.app_list)

        # Populate Mock Data
        self.populate_ai_recommendations()
        self.populate_packages("all")

    def populate_ai_recommendations(self):
        # Mock AI deciding what's good based on user "profile"
        recs = [
            ("VS Code", "Code Editing"),
            ("VLC", "Media Player"),
            ("GIMP", "Image Editor")
        ]
        for i, (name, cat) in enumerate(recs):
            btn = Gtk.Button(label=f"{name}\n<small>{cat}</small>")
            btn.get_child().set_use_markup(True)
            btn.set_size_request(120, 60)
            self.rec_grid.attach(btn, i, 0, 1, 1)

    def populate_packages(self, query):
        # Clear list
        for child in self.app_list.get_children():
            self.app_list.remove(child)

        # Mock Database
        db = {
            "firefox": "Web Browser - Standard",
            "chromium": "Web Browser - Open Source",
            "htop": "System Monitor - Terminal",
            "blender": "3D Creation Suite",
            "python3": "Interpreted Language"
        }

        for name, desc in db.items():
            if query == "all" or query in name or query in desc.lower():
                row = Gtk.ListBoxRow()
                hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
                row.add(hbox)
                
                vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
                lbl_name = Gtk.Label(label=f"<b>{name}</b>", xalign=0, use_markup=True)
                lbl_desc = Gtk.Label(label=desc, xalign=0)
                vbox.pack_start(lbl_name, True, True, 0)
                vbox.pack_start(lbl_desc, True, True, 0)
                
                btn_install = Gtk.Button(label="Install")
                btn_install.connect("clicked", self.on_install_clicked, name)
                
                hbox.pack_start(vbox, True, True, 0)
                hbox.pack_start(btn_install, False, False, 0)
                
                self.app_list.add(row)
        
        self.app_list.show_all()

    def on_search(self, entry):
        text = entry.get_text()
        print(f"Searching for: {text}")
        if text.startswith("ai:"):
            # Mock AI query
            print("Invoking AI...")
        else:
            self.populate_packages(text.lower())

    def on_install_clicked(self, widget, pkg_name):
        print(f"Requesting install: {pkg_name}")
        # Real implementation:
        # subprocess.run(["pkexec", "apt-get", "install", "-y", pkg_name])

win = AribaStore()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
