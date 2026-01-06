import os
import sys
import subprocess
import shutil
import json

class AribaAI:
    def __init__(self):
        self.name = "Ariba Assistant"
        self.config_path = "/etc/ariba/ai_config.json"
        
    def system_check(self):
        """Performs a basic system health check."""
        issues = []
        
        # Check Disk Usage
        total, used, free = shutil.disk_usage("/")
        if (used / total) > 0.9:
            issues.append(f"Critical: Disk usage is over 90% ({used // (2**30)}GB used).")
            
        # Check Load
        load = os.getloadavg()
        if load[0] > 4.0:
            issues.append(f"Warning: High System Load detected ({load[0]}).")
            
        return issues if issues else ["System is healthy."]

    def suggest_optimization(self):
        """Analyzes the system and suggests standard Linux optimizations."""
        suggestions = []
        
        # Check for unused packages (apt)
        try:
            res = subprocess.run(["apt", "autoremove", "--simulate"], capture_output=True, text=True)
            if "0 to remove" not in res.stdout:
                suggestions.append("Run 'sudo apt autoremove' to clear unused packages.")
        except FileNotFoundError:
            pass # apt not installed?

        # Check /tmp size
        tmp_size = subprocess.run(["du", "-sh", "/tmp"], capture_output=True, text=True).stdout.split()[0]
        suggestions.append(f"Temporary files are using {tmp_size}. Consider clearing if space is low.")
        
        return suggestions

    def execute_command(self, user_input):
        """Parses natural language commands."""
        user_input = user_input.lower()
        
        if "status" in user_input or "health" in user_input:
            return "\n".join(self.system_check())
        
        elif "optimize" in user_input or "clean" in user_input:
            suggestions = self.suggest_optimization()
            return "Optimization Suggestions:\n" + "\n- ".join(suggestions)
        
        elif "net" in user_input or "ip" in user_input:
            # Simple IP check
            ip = subprocess.run(["hostname", "-I"], capture_output=True, text=True).stdout.strip()
            return f"Current IP Address: {ip}"
            
        elif "help" in user_input:
            return "I can help with: 'system status', 'optimize system', 'check network', or 'list files'."
            
        else:
            return f"I'm sorry, I don't understand '{user_input}'. Try asking for 'help'."

if __name__ == "__main__":
    agent = AribaAI()
    if len(sys.argv) > 1:
        # CLI usage
        print(agent.execute_command(" ".join(sys.argv[1:])))
    else:
        # Interactive mode
        print(f"Welcome to {agent.name}. Type 'exit' to quit.")
        while True:
            try:
                cmd = input("ariba-ai> ")
                if cmd.lower() in ["exit", "quit"]:
                    break
                print(agent.execute_command(cmd))
            except KeyboardInterrupt:
                break
