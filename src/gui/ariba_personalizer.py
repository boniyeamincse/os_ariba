import gi
import subprocess
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

class AI_Personalizer(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ariba AI Personalizer")
        self.set_border_width(15)
        self.set_default_size(700, 500)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Main Layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(main_box)

        # Header
        lbl_head = Gtk.Label(label="<span font='20' weight='bold'>AI Desktop Customization</span>")
        lbl_head.set_use_markup(True)
        main_box.pack_start(lbl_head, False, False, 10)

        lbl_sub = Gtk.Label(label="I will analyze your hardware and preferences to suggest the best experience.")
        main_box.pack_start(lbl_sub, False, False, 5)

        # Suggestions Area
        self.suggestion_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        scrolled = Gtk.ScrolledWindow()
        scrolled.add(self.suggestion_box)
        scrolled.set_vexpand(True)
        main_box.pack_start(scrolled, True, True, 10)

        # Actions
        btn_scan = Gtk.Button(label="Analyze & Suggest")
        btn_scan.get_style_context().add_class("suggested-action")
        btn_scan.connect("clicked", self.on_analyze)
        main_box.pack_start(btn_scan, False, False, 10)

        self.show_all()

    def add_suggestion_card(self, title, desc, action_label, action_callback):
        """Helper to create suggestion cards."""
        card = Gtk.Frame()
        card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        card_box.set_border_width(10)
        card.add(card_box)

        lbl_t = Gtk.Label(label=f"<b>{title}</b>", xalign=0)
        lbl_t.set_use_markup(True)
        lbl_d = Gtk.Label(label=desc, xalign=0, wrap=True)
        
        btn = Gtk.Button(label=action_label)
        btn.connect("clicked", action_callback)
        btn.set_halign(Gtk.Align.END)

        card_box.pack_start(lbl_t, False, False, 0)
        card_box.pack_start(lbl_d, False, False, 0)
        card_box.pack_start(btn, False, False, 5)
        
        self.suggestion_box.pack_start(card, False, False, 0)
        self.suggestion_box.show_all()

    def on_analyze(self, widget):
        # Clear previous
        for child in self.suggestion_box.get_children():
            self.suggestion_box.remove(child)

        # Mock AI Analysis Logic
        # 1. Check Resolution/DPI
        # 2. Check RAM
        # 3. Check specific time of day (Dark Mode)
        
        # Suggestion 1: Theme
        self.add_suggestion_card(
            "Enable Dark Mode",
            "It looks like you are working in a low-light environment. Switching to a dark theme will reduce eye strain.",
            "Apply Dark Theme",
            self.apply_dark_mode
        )

        # Suggestion 2: Effects
        self.add_suggestion_card(
            "Enable Compositing Effects",
            "Your GPU supports hardware acceleration. We can enable transparency and shadows for a modern look.",
            "Enable Effects",
            self.enable_effects
        )

        # Suggestion 3: Layout
        self.add_suggestion_card(
            "Modern Dock Layout",
            "Switch from the traditional panel to a modern, centered dock layout for better productivity.",
            "Switch Layout",
            self.apply_dock_layout
        )

    def apply_dark_mode(self, widget):
        print("Applying Dark Mode...")
        subprocess.run(["xfconf-query", "-c", "xsettings", "-p", "/Net/ThemeName", "-s", "WhiteSur-Dark"])
        subprocess.run(["xfconf-query", "-c", "xfwm4", "-p", "/general/theme", "-s", "WhiteSur-Dark"])

    def enable_effects(self, widget):
        print("Enabling Compositor...")
        subprocess.run(["xfconf-query", "-c", "xfwm4", "-p", "/general/use_compositing", "-s", "true"])

    def apply_dock_layout(self, widget):
        print("Configuring Dock...")
        # In a real scenario, this would configure Plank or xfce4-panel profiles
        pass

if __name__ == "__main__":
    app = AI_Personalizer()
    app.connect("destroy", Gtk.main_quit)
    Gtk.main()
