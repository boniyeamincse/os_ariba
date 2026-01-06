import subprocess
import crypt
import grp
import spwd
import re

class AIUserManager:
    def __init__(self):
        self.common_weak_passwords = ["password", "123456", "ariba", "root", "admin"]

    def check_password_strength(self, password):
        """Analyzes password strength and returns suggestions."""
        issues = []
        if len(password) < 8:
            issues.append("Password is too short (min 8 chars).")
        if not re.search(r"\d", password):
            issues.append("Add at least one number.")
        if not re.search(r"[A-Z]", password):
            issues.append("Add at least one uppercase letter.")
        if password.lower() in self.common_weak_passwords:
            issues.append("This is a common weak password.")
        
        return issues

    def list_users(self):
        """Lists standard users (UID >= 1000)."""
        users = []
        for user in spwd.getspall():
            if 1000 <= spwd.getspnam(user.sp_namp).sp_uid < 65534:
                users.append(user.sp_namp)
        return users

    def suggest_groups(self, username, user_type="standard"):
        """Suggests groups based on user role."""
        groups = ["users"] # Default
        if user_type == "admin":
            groups.extend(["sudo", "plugdev", "netdev", "adm"])
            return f"Recommendation for Admin '{username}': Add to groups {', '.join(groups)}"
        elif user_type == "dev":
            groups.extend(["docker", "vboxusers"])
            return f"Recommendation for Developer '{username}': Add to groups {', '.join(groups)}"
        else:
            return f"Standard user '{username}': Default groups are sufficient."

    def create_user(self, username, password, user_type="standard"):
        """Creates a user with AI checks."""
        # 1. Check Password
        issues = self.check_password_strength(password)
        if issues:
            return f"Security Alert: Password weak. {' '.join(issues)}"

        # 2. Check Existence
        try:
            subprocess.run(["id", username], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return f"Error: User '{username}' already exists."
        except subprocess.CalledProcessError:
            pass

        # 3. Create
        try:
            # Note: This requires root
            cmd = ["useradd", "-m", "-s", "/bin/bash", username]
            subprocess.run(cmd, check=True)
            
            # Set Password
            proc = subprocess.Popen(["chpasswd"], stdin=subprocess.PIPE)
            proc.communicate(input=f"{username}:{password}".encode())
            
            # 4. Apply Group Suggestions
            if user_type == "admin":
                subprocess.run(["usermod", "-aG", "sudo", username])
            
            return f"User '{username}' created successfully as {user_type}."
            
        except PermissionError:
            return "Error: Permission denied. Must be root."
        except Exception as e:
            return f"Failed to create user: {str(e)}"

if __name__ == "__main__":
    # Test Stub
    manager = AIUserManager()
    print("--- AI User Manager Check ---")
    
    # Test Password Logic
    print("Testing weak password '123456':", manager.check_password_strength("123456"))
    print("Testing good password 'S3cureP@ss':", manager.check_password_strength("S3cureP@ss"))
    
    # Test Group Suggestion
    print(manager.suggest_groups("kali", "admin"))
