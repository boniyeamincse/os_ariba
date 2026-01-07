import sys
import os
import subprocess
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, Pango

class AribaWelcomeWizard(Gtk.Window):
    def __init__(self):
        super().__init__(title="Welcome to Ariba OS")
        self.set_border_width(0)
        self.set_default_size(800, 500)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(False)

        # Style
        self.load_css()

        # Main Layout
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(500)

        # Header Bar (Custom)
        self.header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.header_box.get_style_context().add_class("header-bar")
        lbl_header = Gtk.Label(label="Ariba OS Setup")
        lbl_header.get_style_context().add_class("header-label")
        self.header_box.pack_start(lbl_header, True, True, 0)
        
        # Pages
        self.create_page_welcome()
        self.create_page_appearance()
        self.create_page_ready()

        # Navigation Bar
        self.nav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.nav_box.get_style_context().add_class("nav-bar")
        self.btn_back = Gtk.Button(label="Back")
        self.btn_back.connect("clicked", self.on_back_clicked)
        self.btn_next = Gtk.Button(label="Next")
        self.btn_next.connect("clicked", self.on_next_clicked)
        self.btn_next.get_style_context().add_class("suggested-action")
        
        self.nav_box.pack_start(self.btn_back, False, False, 10)
        self.nav_box.pack_end(self.btn_next, False, False, 10)

        # Main Container
        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_vbox.pack_start(self.header_box, False, False, 0)
        main_vbox.pack_start(self.stack, True, True, 0)
        main_vbox.pack_end(self.nav_box, False, False, 0)

        self.add(main_vbox)
        self.current_step = 0
        self.update_buttons()

    def load_css(self):
        css = b"""
        window { background-color: #f6f6f6; color: #333; }
        .header-bar { background-color: #ffffff; padding: 15px; border-bottom: 1px solid #ddd; }
        .header-label { font-size: 18px; font-weight: bold; color: #E95420; } /* Ubuntu Orange-ish */
        .nav-bar { background-color: #ffffff; padding: 15px; border-top: 1px solid #ddd; }
        .page-content { padding: 40px; }
        .title { font-size: 24px; font-weight: bold; margin-bottom: 10px; }
        .subtitle { font-size: 14px; color: #666; margin-bottom: 30px; }
        button { padding: 8px 16px; border-radius: 4px; }
        .suggested-action { background-color: #E95420; color: white; }
        .card { background-color: white; border-radius: 8px; padding: 20px; border: 1px solid #ddd; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def create_page_welcome(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")
        
        lbl_title = Gtk.Label(label="Welcome to Ariba OS")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)

        lbl_sub = Gtk.Label(label="Let's get your system set up.")
        lbl_sub.get_style_context().add_class("subtitle")
        box.pack_start(lbl_sub, False, False, 0)

        # Language Placeholder
        lang_frame = Gtk.Frame(label="Language")
        lang_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        lang_box.set_border_width(15)
        
        # Simple ListStore for languages
        store = Gtk.ListStore(str)
        languages = ["English (US)", "Spanish", "French", "German", "Chinese", "Japanese"]
        for lang in languages:
            store.append([lang])
            
        tree = Gtk.TreeView(model=store)
        renderer = Gtk.CellRendererText()
        column = Gtk.TreeViewColumn("Select Language", renderer, text=0)
        tree.append_column(column)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.add(tree)
        scroll.set_min_content_height(150)
        
        lang_box.pack_start(scroll, True, True, 0)
        lang_frame.add(lang_box)
        box.pack_start(lang_frame, True, True, 0)

        self.stack.add_named(box, "welcome")

    def create_page_appearance(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")

        lbl_title = Gtk.Label(label="Personalize")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)
        
        grid = Gtk.Grid()
        grid.set_column_spacing(20)
        grid.set_halign(Gtk.Align.CENTER)
        
        # Light Mode Button
        btn_light = Gtk.Button(label="Light Mode")
        btn_light.set_size_request(150, 100)
        btn_light.get_style_context().add_class("card")
        btn_light.connect("clicked", lambda x: self.set_theme("Adwaita"))
        grid.attach(btn_light, 0, 0, 1, 1)

        # Dark Mode Button
        btn_dark = Gtk.Button(label="Dark Mode")
        btn_dark.set_size_request(150, 100)
        btn_dark.get_style_context().add_class("card")
        btn_dark.connect("clicked", lambda x: self.set_theme("Adwaita-dark"))
        grid.attach(btn_dark, 1, 0, 1, 1)

        box.pack_start(grid, True, True, 20)
        self.stack.add_named(box, "appearance")

    def create_page_ready(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")

        lbl_title = Gtk.Label(label="You're Ready!")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)

        lbl_desc = Gtk.Label(label="Ariba OS is all set up. Enjoy your new experience.")
        lbl_desc.set_max_width_chars(50)
        lbl_desc.set_line_wrap(True)
        box.pack_start(lbl_desc, False, False, 0)

        # Links
        link_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        
        btn_docs = Gtk.LinkButton(uri="https://github.com/boniyeamincse/os_ariba", label="Open Documentation")
        link_box.pack_start(btn_docs, False, False, 0)
        
        btn_contribute = Gtk.LinkButton(uri="https://github.com/boniyeamincse/os_ariba", label="Contribute to Project")
        link_box.pack_start(btn_contribute, False, False, 0)

        box.pack_start(link_box, False, False, 20)
        
        self.stack.add_named(box, "ready")

    def set_theme(self, theme_name):
        print(f"Setting theme to {theme_name}")
        # In a real session, we'd use xfconf-query
        # subprocess.run(["xfconf-query", "-c", "xsettings", "-p", "/Net/ThemeName", "-s", theme_name])
        # For this demo/first-run, we might just simulate or rely on the user having the themes installed.

    def on_next_clicked(self, widget):
        if self.current_step < 2:
            self.current_step += 1
            self.update_view()
        else:
            Gtk.main_quit()

    def on_back_clicked(self, widget):
        if self.current_step > 0:
            self.current_step -= 1
            self.update_view()

    def update_view(self):
        pages = ["welcome", "appearance", "ready"]
        self.stack.set_visible_child_name(pages[self.current_step])
        self.update_buttons()

    def update_buttons(self):
        self.btn_back.set_sensitive(self.current_step > 0)
        if self.current_step == 2:
            self.btn_next.set_label("Start Using Ariba OS")
            self.btn_next.get_style_context().add_class("suggested-action")
        else:
            self.btn_next.set_label("Next")

if __name__ == "__main__":
    win = AribaWelcomeWizard()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
