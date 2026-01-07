import sys
import os
import subprocess
import threading
import json
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Pango

class AribaInstaller(Gtk.Window):
    def __init__(self):
        super().__init__(title="Install Ariba OS")
        self.set_border_width(0)
        self.set_default_size(900, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(True)
        
        # Data
        self.disk_device = None
        self.install_mode = "auto"
        self.firmware_type = self.detect_firmware()
        self.user_name = ""
        self.user_pass = ""
        self.autologin = False

        self.load_css()
        
        # Main Layout
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        
        # Header
        self.header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.header_box.get_style_context().add_class("header-bar")
        lbl_header = Gtk.Label(label="Ariba OS Installer")
        lbl_header.get_style_context().add_class("header-label")
        self.header_box.pack_start(lbl_header, True, True, 0)
        
        # Firmware Indicator
        lbl_fw = Gtk.Label(label=f"System: {self.firmware_type.upper()}")
        lbl_fw.get_style_context().add_class("dim-label")
        self.header_box.pack_end(lbl_fw, False, False, 0)

        # Pages
        self.create_page_welcome()
        self.create_page_disk_selection()
        self.create_page_user_info()
        self.create_page_installing()
        self.create_page_complete()

        # Nav
        self.nav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.nav_box.get_style_context().add_class("nav-bar")
        self.btn_back = Gtk.Button(label="Back")
        self.btn_back.connect("clicked", self.on_back_clicked)
        self.btn_next = Gtk.Button(label="Next")
        self.btn_next.connect("clicked", self.on_next_clicked)
        self.btn_next.get_style_context().add_class("suggested-action")
        
        self.nav_box.pack_start(self.btn_back, False, False, 10)
        self.nav_box.pack_end(self.btn_next, False, False, 10)

        main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        main_vbox.pack_start(self.header_box, False, False, 0)
        main_vbox.pack_start(self.stack, True, True, 0)
        main_vbox.pack_end(self.nav_box, False, False, 0)
        self.add(main_vbox)

        self.current_step = 0
        self.update_buttons()

    def detect_firmware(self):
        return "efi" if os.path.exists("/sys/firmware/efi") else "bios"

    def load_css(self):
        css = b"""
        window { background-color: #f6f6f6; color: #333; }
        .header-bar { background-color: #ffffff; padding: 15px; border-bottom: 1px solid #ddd; }
        .header-label { font-size: 18px; font-weight: bold; color: #E95420; }
        .dim-label { color: #888; font-size: 12px; }
        .nav-bar { background-color: #ffffff; padding: 15px; border-top: 1px solid #ddd; }
        .page-content { padding: 40px; }
        .title { font-size: 24px; font-weight: bold; margin-bottom: 10px; }
        .subtitle { font-size: 14px; color: #666; margin-bottom: 10px; }
        .card { background-color: white; border-radius: 8px; padding: 10px; border: 1px solid #ddd; }
        entry { padding: 8px; margin-bottom: 10px; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def create_page_welcome(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")
        
        img = Gtk.Image.new_from_icon_name("drive-harddisk", Gtk.IconSize.DIALOG)
        box.pack_start(img, False, False, 20)
        
        lbl_title = Gtk.Label(label="Install Ariba OS")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)

        lbl = Gtk.Label(label="Welcome to the Ariba OS installation wizard.\nWe have detected your system mode as: " + self.firmware_type.upper())
        lbl.set_justify(Gtk.Justification.CENTER)
        box.pack_start(lbl, False, False, 0)

        self.stack.add_named(box, "welcome")

    def create_page_disk_selection(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")
        
        lbl_title = Gtk.Label(label="Select Installation Target")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)
        
        # Mode Selection
        mode_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        mode_box.set_halign(Gtk.Align.CENTER)
        
        rb_auto = Gtk.RadioButton.new_with_label_from_widget(None, "Auto (Erase Disk)")
        rb_auto.connect("toggled", self.on_mode_changed, "auto")
        rb_manual = Gtk.RadioButton.new_with_label_from_widget(rb_auto, "Manual Partitioning")
        rb_manual.connect("toggled", self.on_mode_changed, "manual")
        
        mode_box.pack_start(rb_auto, False, False, 0)
        mode_box.pack_start(rb_manual, False, False, 0)
        box.pack_start(mode_box, False, False, 0)

        # Disk List
        self.disk_store = Gtk.ListStore(str, str, str) # Name, Size, Model
        self.disk_view = Gtk.TreeView(model=self.disk_store)
        
        renderer = Gtk.CellRendererText()
        col1 = Gtk.TreeViewColumn("Device", renderer, text=0)
        col2 = Gtk.TreeViewColumn("Size", renderer, text=1)
        col3 = Gtk.TreeViewColumn("Model", renderer, text=2)
        self.disk_view.append_column(col1)
        self.disk_view.append_column(col2)
        self.disk_view.append_column(col3)
        
        self.disk_view.get_selection().set_mode(Gtk.SelectionMode.SINGLE)
        
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.add(self.disk_view)
        scroll.set_min_content_height(150)
        scroll.get_style_context().add_class("card")
        
        box.pack_start(scroll, True, True, 0)
        
        # Refresh Btn
        btn_refresh = Gtk.Button(label="Refresh Disks")
        btn_refresh.connect("clicked", lambda x: self.refresh_disks())
        box.pack_start(btn_refresh, False, False, 0)
        
        # Initial Refresh
        self.refresh_disks()

        self.stack.add_named(box, "disk")

    def create_page_user_info(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")
        
        lbl_title = Gtk.Label(label="User Information")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)

        # Form
        grid = Gtk.Grid()
        grid.set_column_spacing(10)
        grid.set_row_spacing(10)
        grid.set_halign(Gtk.Align.CENTER)
        
        lbl_user = Gtk.Label(label="Username:")
        lbl_user.set_halign(Gtk.Align.END)
        self.entry_user = Gtk.Entry()
        self.entry_user.set_placeholder_text("ariba")
        
        lbl_pass = Gtk.Label(label="Password:")
        lbl_pass.set_halign(Gtk.Align.END)
        self.entry_pass = Gtk.Entry()
        self.entry_pass.set_visibility(False)
        self.entry_pass.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        
        grid.attach(lbl_user, 0, 0, 1, 1)
        grid.attach(self.entry_user, 1, 0, 1, 1)
        grid.attach(lbl_pass, 0, 1, 1, 1)
        grid.attach(self.entry_pass, 1, 1, 1, 1)

        box.pack_start(grid, False, False, 0)
        
        # Autologin
        self.check_autologin = Gtk.CheckButton(label="Log in automatically")
        self.check_autologin.set_halign(Gtk.Align.CENTER)
        self.check_autologin.set_active(True)
        box.pack_start(self.check_autologin, False, False, 0)

        self.stack.add_named(box, "user")

    def on_mode_changed(self, widget, mode):
        if widget.get_active():
            self.install_mode = mode

    def refresh_disks(self):
        self.disk_store.clear()
        try:
            cmd = ["lsblk", "-d", "-n", "-o", "NAME,SIZE,MODEL,TYPE", "--json"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            data = json.loads(result.stdout)
            
            for device in data.get("blockdevices", []):
                if device.get("type") == "disk":
                    name = f"/dev/{device['name']}"
                    size = device.get("size", "Unknown")
                    model = device.get("model", "Unknown")
                    self.disk_store.append([name, size, model])
                    
        except Exception as e:
            print(f"Error listing disks: {e}")
            self.disk_store.append(["/dev/sda", "500GB", "Virtual Disk (Mock)"])

    def create_page_installing(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")
        
        lbl_title = Gtk.Label(label="Installing...")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)

        self.progress = Gtk.ProgressBar()
        box.pack_start(self.progress, False, False, 0)

        self.console = Gtk.TextView()
        self.console.set_editable(False)
        self.console.get_style_context().add_class("card")
        
        scroll = Gtk.ScrolledWindow()
        scroll.add(self.console)
        scroll.set_vexpand(True)
        
        box.pack_start(scroll, True, True, 0)

        self.stack.add_named(box, "installing")

    def create_page_complete(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.get_style_context().add_class("page-content")
        
        lbl_title = Gtk.Label(label="Installation Complete")
        lbl_title.get_style_context().add_class("title")
        box.pack_start(lbl_title, False, False, 0)
        
        lbl = Gtk.Label(label="Ariba OS has been installed successfully.\nYou can now restart your computer.")
        box.pack_start(lbl, False, False, 0)

        self.stack.add_named(box, "complete")

    def on_next_clicked(self, widget):
        if self.current_step == 0: # Welcome -> Disk
            self.current_step = 1
        elif self.current_step == 1: # Disk -> User
            selection = self.disk_view.get_selection()
            model, treeiter = selection.get_selected()
            if treeiter:
                self.disk_device = model[treeiter][0]
                if self.install_mode == "manual":
                    subprocess.Popen(["gparted", self.disk_device])
                self.current_step = 2
            else:
                self.show_error("Please select a disk to install to.")
                return
        elif self.current_step == 2: # User -> Confirm
            self.user_name = self.entry_user.get_text().strip()
            self.user_pass = self.entry_pass.get_text()
            
            if not self.user_name or not self.user_pass:
                self.show_error("Please enter both a username and password.")
                return
                
            self.confirm_install()
        elif self.current_step == 3: # Installing (No Action)
            return 
        elif self.current_step == 4: # Complete -> Reboot
            subprocess.run(["reboot"])
        
        self.update_view()

    def show_error(self, message):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text="Error"
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def confirm_install(self):
        msg = f"Mode: {self.install_mode.upper()}\nTarget: {self.disk_device}\nFirmware: {self.firmware_type.upper()}\nUser: {self.user_name}"
        if self.install_mode == "auto":
             msg += "\n\nWARNING: The entire disk will be ERASED irreversibly."
             
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.OK_CANCEL,
            text="Confirm Installation"
        )
        dialog.format_secondary_text(msg)
        response = dialog.run()
        dialog.destroy()
        
        if response == Gtk.ResponseType.OK:
            self.current_step = 3
            self.start_install()
            self.update_view()

    def start_install(self):
        self.btn_back.set_sensitive(False)
        self.btn_next.set_sensitive(False)
        thread = threading.Thread(target=self.run_install_script)
        thread.daemon = True
        thread.start()

    def run_install_script(self):
        script_path = "/opt/ariba/installer/install_os.sh"
        if not os.path.exists(script_path):
             script_path = os.path.abspath("src/scripts/install_os.sh")

        # Pass arguments
        self.autologin = self.check_autologin.get_active()
        autologin_str = "true" if self.autologin else "false"

        cmd = ["pkexec", script_path, self.disk_device, 
               "--mode", self.install_mode,
               "--firmware", self.firmware_type, 
               "--user", self.user_name,
               "--password", self.user_pass,
               "--autologin", autologin_str,
               "-y"]
        
        GLib.idle_add(self.update_progress, 0.1, f"Running: install_os.sh ...")

        try:
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )

            for line in process.stdout:
                line = line.strip()
                if line:
                    GLib.idle_add(self.append_log, line)
                    if "Partitioning" in line: GLib.idle_add(self.update_progress, 0.2, "Partitioning...")
                    elif "Formatting" in line: GLib.idle_add(self.update_progress, 0.3, "Formatting...")
                    elif "Copying" in line: GLib.idle_add(self.update_progress, 0.5, "Copying Files...")
                    elif "Configuring User" in line: GLib.idle_add(self.update_progress, 0.8, "Creating User...")
                    elif "Installing Bootloader" in line: GLib.idle_add(self.update_progress, 0.9, "Installing GRUB...")
            
            process.wait()
            
            if process.returncode == 0:
                GLib.idle_add(self.update_progress, 1.0, "Success!")
                GLib.idle_add(self.install_finished)
            else:
                GLib.idle_add(self.append_log, f"Error: Exit Code {process.returncode}")

        except Exception as e:
            GLib.idle_add(self.append_log, f"Exception: {str(e)}")

    def append_log(self, text):
        buf = self.console.get_buffer()
        buf.insert_at_cursor(text + "\n")
        mark = buf.create_mark("end", buf.get_end_iter(), False)
        self.console.scroll_to_mark(mark, 0.05, True, 0.0, 1.0)

    def update_progress(self, fraction, text):
        self.progress.set_fraction(fraction)
        self.progress.set_text(text)

    def install_finished(self):
        self.current_step = 4
        self.update_view()

    def on_back_clicked(self, widget):
        if self.current_step > 0:
            self.current_step -= 1
            self.update_view()

    def update_view(self):
        pages = ["welcome", "disk", "user", "installing", "complete"]
        self.stack.set_visible_child_name(pages[self.current_step])
        self.update_buttons()

    def update_buttons(self):
        self.btn_back.set_sensitive(self.current_step > 0 and self.current_step < 3)
        self.btn_next.set_sensitive(self.current_step != 3)
        
        if self.current_step == 2: # User Page -> Install
            self.btn_next.set_label("Install")
            self.btn_next.get_style_context().remove_class("suggested-action")
            self.btn_next.get_style_context().add_class("destructive-action")
        elif self.current_step == 4: # Complete
            self.btn_next.set_label("Restart Now")
            self.btn_next.get_style_context().add_class("suggested-action")
        else:
            self.btn_next.set_label("Next")
            if self.current_step == 1: # Disk Page
                 self.btn_next.get_style_context().add_class("suggested-action")
                 self.btn_next.get_style_context().remove_class("destructive-action")


if __name__ == "__main__":
    win = AribaInstaller()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
