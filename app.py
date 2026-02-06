import os
import markdown
from flask import Flask, render_template, send_from_directory, abort
from pathlib import Path

app = Flask(__name__)

PROJECT_ROOT = Path(".")

EXCLUDED_DIRS = {".git", ".cache", ".local", ".pythonlibs", "__pycache__", "node_modules", "templates", "static"}
EXCLUDED_FILES = {".pyc", ".pyo"}

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".bmp", ".ico"}
CODE_EXTENSIONS = {".gd", ".gdshader", ".py", ".json", ".cfg", ".toml", ".yaml", ".yml",
                   ".csv", ".txt", ".ini", ".godot", ".import", ".tres", ".tscn"}
MD_EXTENSIONS = {".md"}


def is_safe_path(path_str):
    resolved = (PROJECT_ROOT / path_str).resolve()
    return str(resolved).startswith(str(PROJECT_ROOT.resolve()))


def get_tree(directory, prefix=""):
    items = []
    try:
        entries = sorted(directory.iterdir(), key=lambda e: (not e.is_dir(), e.name.lower()))
    except PermissionError:
        return items

    for entry in entries:
        if entry.name in EXCLUDED_DIRS:
            continue
        if entry.suffix in EXCLUDED_FILES:
            continue

        rel_path = entry.relative_to(PROJECT_ROOT)
        if entry.is_dir():
            items.append({"name": entry.name, "path": str(rel_path), "type": "dir"})
        else:
            items.append({"name": entry.name, "path": str(rel_path), "type": "file",
                          "ext": entry.suffix.lower()})
    return items


def count_files_by_type(directory):
    counts = {}
    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]
        for f in files:
            ext = Path(f).suffix.lower()
            if ext:
                counts[ext] = counts.get(ext, 0) + 1
    return dict(sorted(counts.items(), key=lambda x: -x[1]))


@app.route("/")
def index():
    project_name = "Abyssal Realms Expedition Manager"
    godot_version = "4.5"

    readme_content = ""
    readme_path = PROJECT_ROOT / "README.md"
    if readme_path.exists():
        readme_content = markdown.markdown(readme_path.read_text(encoding="utf-8", errors="replace"),
                                           extensions=["tables", "fenced_code"])

    file_counts = count_files_by_type(PROJECT_ROOT)
    scenes = list((PROJECT_ROOT / "scenes").rglob("*.tscn")) if (PROJECT_ROOT / "scenes").exists() else []
    scripts = list(PROJECT_ROOT.rglob("*.gd"))
    scripts = [s for s in scripts if "addons" not in str(s) and ".cache" not in str(s) and ".pythonlibs" not in str(s)]

    docs = []
    for md_file in sorted(PROJECT_ROOT.rglob("*.md")):
        rel = md_file.relative_to(PROJECT_ROOT)
        parts = str(rel).split(os.sep)
        if any(p in EXCLUDED_DIRS for p in parts):
            continue
        if "addons" in parts:
            continue
        docs.append(str(rel))

    return render_template("index.html",
                           project_name=project_name,
                           godot_version=godot_version,
                           readme_content=readme_content,
                           file_counts=file_counts,
                           scenes=[str(s.relative_to(PROJECT_ROOT)) for s in scenes],
                           scripts=[str(s.relative_to(PROJECT_ROOT)) for s in sorted(scripts)],
                           docs=docs)


@app.route("/browse/")
@app.route("/browse/<path:subpath>")
def browse(subpath=""):
    if not is_safe_path(subpath):
        abort(403)

    target = PROJECT_ROOT / subpath
    if not target.exists():
        abort(404)

    if target.is_dir():
        items = get_tree(target)
        parent = str(Path(subpath).parent) if subpath else None
        if parent == ".":
            parent = ""
        return render_template("browse.html", items=items, current_path=subpath, parent=parent)
    else:
        ext = target.suffix.lower()
        content = None
        is_image = ext in IMAGE_EXTENSIONS
        is_markdown = ext in MD_EXTENSIONS
        is_code = ext in CODE_EXTENSIONS or ext == ""

        if is_markdown:
            raw = target.read_text(encoding="utf-8", errors="replace")
            content = markdown.markdown(raw, extensions=["tables", "fenced_code"])
        elif is_code:
            try:
                content = target.read_text(encoding="utf-8", errors="replace")
            except Exception:
                content = "[Unable to read file]"
        elif is_image:
            content = f"/raw/{subpath}"

        parent = str(Path(subpath).parent)
        if parent == ".":
            parent = ""

        return render_template("file_view.html",
                               file_path=subpath,
                               file_name=target.name,
                               content=content,
                               is_image=is_image,
                               is_markdown=is_markdown,
                               is_code=is_code,
                               ext=ext,
                               parent=parent)


@app.route("/raw/<path:subpath>")
def raw_file(subpath):
    if not is_safe_path(subpath):
        abort(403)
    target = PROJECT_ROOT / subpath
    if not target.exists() or not target.is_file():
        abort(404)
    return send_from_directory(str(target.parent.resolve()), target.name)


@app.route("/docs/")
def docs_list():
    docs = []
    for md_file in sorted(PROJECT_ROOT.rglob("*.md")):
        rel = md_file.relative_to(PROJECT_ROOT)
        parts = str(rel).split(os.sep)
        if any(p in EXCLUDED_DIRS for p in parts):
            continue
        if "addons" in parts:
            continue
        docs.append(str(rel))
    return render_template("docs.html", docs=docs)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
