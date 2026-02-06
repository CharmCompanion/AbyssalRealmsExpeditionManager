import os
import re
import shutil
from datetime import datetime

# Extensions that commonly contain uid="uid://..."
TEXT_EXTS = {".tscn", ".tres", ".gd", ".cfg", ".import", ".godot", ".scn", ".res", ".gdshader"}

UID_ATTR_RE = re.compile(r'\s+uid="uid://[a-z0-9]+"', re.IGNORECASE)
UID_ANY_RE = re.compile(r'uid://[a-z0-9]+', re.IGNORECASE)

def should_scan(path: str) -> bool:
    _, ext = os.path.splitext(path)
    return ext.lower() in TEXT_EXTS

def is_in_ignored_dir(path: str) -> bool:
    # ignore .godot cache + imports (we don't want to mutate generated/cache stuff)
    parts = path.replace("\\", "/").split("/")
    return ".godot" in parts or "import" in parts

def backup_file(path: str, backup_root: str) -> str:
    rel = os.path.relpath(path, ".")
    dest = os.path.join(backup_root, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(path, dest)
    return dest

def main():
    project_root = os.path.abspath(".")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_root = os.path.join(project_root, "_uid_backup_" + timestamp)

    hits = []
    changed = 0
    scanned = 0

    for root, dirs, files in os.walk(project_root):
        # skip cache/import folders early
        if is_in_ignored_dir(root):
            continue

        for fname in files:
            path = os.path.join(root, fname)
            if not should_scan(path):
                continue

            scanned += 1

            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    text = f.read()
            except Exception:
                continue

            if not UID_ANY_RE.search(text):
                continue

            # record occurrences (for visibility)
            for m in UID_ANY_RE.finditer(text):
                start = max(0, m.start() - 40)
                end = min(len(text), m.end() + 40)
                context = text[start:end].replace("\n", "\\n")
                hits.append((path, m.group(0), context))

            # remove only the attribute form:  uid="uid://xxxx"
            new_text = UID_ATTR_RE.sub("", text)

            if new_text != text:
                backup_file(path, backup_root)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_text)
                changed += 1

    print(f"Scanned files: {scanned}")
    print(f"Files changed (uid attributes removed): {changed}")
    print(f"Backup saved to: {backup_root}")
    print("")
    print("UID hits found (including ones not in attribute form):")
    for path, uid, ctx in hits[:200]:
        print(f"- {path}: {uid} ... {ctx}")
    if len(hits) > 200:
        print(f"... and {len(hits) - 200} more hits")

    print("")
    print("Next steps:")
    print("1) Reopen Godot.")
    print("2) If errors persist, search the printed hit list for uid references that are NOT in uid=\"...\" form.")
    print("   Those need manual fixing (usually an ExtResource referencing a missing resource).")

if __name__ == "__main__":
    main()
