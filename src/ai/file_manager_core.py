import os
import hashlib
import shutil
from collections import defaultdict

class AIFileManager:
    def __init__(self, root_path):
        self.root_path = root_path
        self.categories = {
            'Images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg'],
            'Documents': ['.pdf', '.docx', '.txt', '.md', '.odt', '.xlsx'],
            'Archives': ['.zip', '.tar', '.gz', '.7z', '.rar'],
            'Code': ['.py', '.c', '.cpp', '.js', '.html', '.css', '.sh'],
            'Audio': ['.mp3', '.wav', '.flac', '.aac'],
            'Video': ['.mp4', '.mkv', '.avi', '.mov']
        }

    def scan_directory(self):
        """Scans the directory and returns a summary."""
        summary = defaultdict(int)
        files = []
        for root, _, filenames in os.walk(self.root_path):
            for f in filenames:
                ext = os.path.splitext(f)[1].lower()
                files.append(os.path.join(root, f))
                found = False
                for cat, exts in self.categories.items():
                    if ext in exts:
                        summary[cat] += 1
                        found = True
                        break
                if not found:
                    summary['Others'] += 1
        return summary, files

    def find_duplicates(self):
        """Finds duplicate files based on content hash."""
        hashes = defaultdict(list)
        duplicates = []
        
        for root, _, filenames in os.walk(self.root_path):
            for f in filenames:
                filepath = os.path.join(root, f)
                try:
                    with open(filepath, "rb") as file_obj:
                        file_hash = hashlib.md5(file_obj.read(4096)).hexdigest()
                        hashes[file_hash].append(filepath)
                except (OSError, PermissionError):
                    continue

        for h, paths in hashes.items():
            if len(paths) > 1:
                duplicates.append(paths)
        
        return duplicates

    def suggest_organization(self):
        """Suggests moving files into category folders."""
        suggestions = []
        for root, _, filenames in os.walk(self.root_path):
            # Skip if we are already in an organized structure to avoid loops
            if any(cat in root for cat in self.categories.keys()):
                continue
                
            for f in filenames:
                ext = os.path.splitext(f)[1].lower()
                for cat, exts in self.categories.items():
                    if ext in exts:
                        suggestions.append(f"Move '{f}' to '{os.path.join(self.root_path, cat)}'")
                        break
        return suggestions

    def organize_files(self, dry_run=True):
        """Executes the organization."""
        actions = []
        if dry_run:
            return self.suggest_organization()

        # Create dirs
        for cat in self.categories:
            cat_path = os.path.join(self.root_path, cat)
            os.makedirs(cat_path, exist_ok=True)

        for root, _, filenames in os.walk(self.root_path):
             if any(cat in root for cat in self.categories.keys()):
                continue

             for f in filenames:
                ext = os.path.splitext(f)[1].lower()
                for cat, exts in self.categories.items():
                    if ext in exts:
                        src = os.path.join(root, f)
                        dst = os.path.join(self.root_path, cat, f)
                        try:
                            shutil.move(src, dst)
                            actions.append(f"Moved {f} -> {cat}/")
                        except Exception as e:
                            actions.append(f"Failed to move {f}: {e}")
        return actions

if __name__ == "__main__":
    import sys
    target_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    manager = AIFileManager(target_dir)
    
    print(f"Scanning {target_dir}...")
    summary, _ = manager.scan_directory()
    print("Summary:", dict(summary))
    
    dupes = manager.find_duplicates()
    if dupes:
        print(f"\nFound {len(dupes)} sets of duplicates.")
    
    print("\nOrganization Suggestions:")
    for sugg in manager.suggest_organization()[:5]: # Show first 5
        print("-", sugg)
    if len(manager.suggest_organization()) > 5:
        print(f"...and {len(manager.suggest_organization()) - 5} more.")
