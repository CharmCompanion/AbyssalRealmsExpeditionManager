"""Generate a lightweight HTML gallery for the imported 2D isometric kit.

Goal: visually browse ~3000 PNGs without renaming anything.

Outputs:
  imported/Map and Character/kit_gallery/index.html
  imported/Map and Character/kit_gallery/manifest.json
"""

from __future__ import annotations

import argparse
import json
import os
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from urllib.parse import quote


KIT_DEFAULT = Path("imported/Map and Character/Fantasy tileset - 2D Isometric")
OUT_DEFAULT = Path("imported/Map and Character/kit_gallery")


def first_token(filename: str) -> str:
	stem = Path(filename).stem
	return re.split(r"[ _]", stem, maxsplit=1)[0]


@dataclass(frozen=True)
class Entry:
	rel: str  # relative to kit root (posix)
	name: str
	token: str
	folder: str


def chunked(items: list[Entry], size: int) -> Iterable[list[Entry]]:
	for i in range(0, len(items), size):
		yield items[i : i + size]


def slugify(s: str) -> str:
	return (re.sub(r"[^a-zA-Z0-9_-]+", "_", s).strip("_") or "_")


def write_text(path: Path, content: str) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_text(content, encoding="utf-8")


def page_html(title: str, back_href: str, entries: list[Entry], kit_rel: str) -> str:
	items: list[str] = []
	for e in entries:
		src = quote(f"{kit_rel}/{e.rel}")
		items.append(
			f"<div class='card'>"
			f"<img loading='lazy' src='{src}' alt='{e.name}'>"
			f"<div class='name'>{e.name}</div>"
			f"<div class='path'>{e.rel}</div>"
			f"</div>"
		)
	grid = "\n".join(items)
	return f"""<!doctype html>
<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>
<title>{title}</title>
<style>
body{{font-family:system-ui,Arial,sans-serif;margin:16px}}
a{{color:#0b5fff;text-decoration:none}}a:hover{{text-decoration:underline}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:12px;margin-top:12px}}
.card{{border:1px solid #ddd;border-radius:10px;padding:10px;background:#fff}}
.card img{{width:100%;height:140px;object-fit:contain;background:#f6f6f6;border-radius:6px}}
.name{{margin-top:8px;font-weight:600;font-size:13px}}
.path{{margin-top:4px;font-family:ui-monospace,Menlo,Consolas,monospace;font-size:11px;color:#444;word-break:break-all}}
</style></head>
<body>
<div><a href='{back_href}'>Back</a> · <strong>{title}</strong></div>
<div class='grid'>
{grid}
</div>
</body></html>"""


def index_html(title: str, sections: list[tuple[str, list[tuple[str, str, int]]]]) -> str:
	blocks: list[str] = []
	for sec_title, links in sections:
		lis = "\n".join(
			f"<li><a href='{href}'>{label}</a> <span style='color:#666'>({count})</span></li>"
			for label, href, count in links
		)
		blocks.append(f"<h2>{sec_title}</h2><ul style='columns:2;gap:24px'>{lis}</ul>")
	return f"""<!doctype html>
<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>
<title>{title}</title>
<style>body{{font-family:system-ui,Arial,sans-serif;margin:16px;max-width:980px}}a{{color:#0b5fff;text-decoration:none}}a:hover{{text-decoration:underline}}</style>
</head><body>
<h1>{title}</h1>
<p style='color:#444'>Browse tiles visually and copy the <code>relative path</code> shown under each image. No renaming.</p>
{"".join(blocks)}
</body></html>"""


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--kit", default=str(KIT_DEFAULT))
	ap.add_argument("--out", default=str(OUT_DEFAULT))
	ap.add_argument("--page-size", type=int, default=240)
	args = ap.parse_args()

	kit_root = Path(args.kit)
	out_root = Path(args.out)
	if not kit_root.exists():
		raise SystemExit(f"Missing kit dir: {kit_root}")

	pngs = sorted(kit_root.rglob("*.png"))
	entries: list[Entry] = []
	for p in pngs:
		rel = p.relative_to(kit_root).as_posix()
		folder = rel.split("/")[0] if "/" in rel else "(root)"
		entries.append(Entry(rel=rel, name=p.name, token=first_token(p.name), folder=folder))

	by_folder: dict[str, list[Entry]] = defaultdict(list)
	by_token: dict[str, list[Entry]] = defaultdict(list)
	for e in entries:
		by_folder[e.folder].append(e)
		by_token[e.token].append(e)

	def write_group(group_name: str, groups: dict[str, list[Entry]]) -> list[tuple[str, str, int]]:
		links: list[tuple[str, str, int]] = []
		group_dir = out_root / group_name
		group_dir.mkdir(parents=True, exist_ok=True)
		for key in sorted(groups.keys(), key=lambda s: (s.lower(), s)):
			items = sorted(groups[key], key=lambda e: e.rel)
			parts = list(chunked(items, args.page_size))
			slug = slugify(key)
			for i, part in enumerate(parts, start=1):
				fname = f"{slug}.html" if len(parts) == 1 else f"{slug}_{i:03d}.html"
				page_path = group_dir / fname
				kit_rel = os.path.relpath(kit_root, page_path.parent).replace("\\", "/")
				title = f"{group_name}: {key}" + (f" (page {i}/{len(parts)})" if len(parts) > 1 else "")
				write_text(page_path, page_html(title, "../index.html", part, kit_rel))
			link = f"{group_name}/{slug}.html" if len(parts) == 1 else f"{group_name}/{slug}_001.html"
			links.append((key, link, len(items)))
		return links

	folder_links = write_group("by_folder", by_folder)
	token_links = write_group("by_token", by_token)

	write_text(out_root / "index.html", index_html("Fantasy 2D Isometric Kit Gallery", [
		("Browse by top-level folder", folder_links),
		("Browse by filename token", token_links),
	]))

	manifest = {
		"kit_root": str(kit_root.as_posix()),
		"out_root": str(out_root.as_posix()),
		"png_count": len(entries),
		"page_size": args.page_size,
		"folders": {k: len(v) for k, v in by_folder.items()},
		"tokens": {k: len(v) for k, v in by_token.items()},
	}
	write_text(out_root / "manifest.json", json.dumps(manifest, indent=2))

	print(f"Wrote: {out_root / 'index.html'}")
	print(f"Wrote: {out_root / 'manifest.json'}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())