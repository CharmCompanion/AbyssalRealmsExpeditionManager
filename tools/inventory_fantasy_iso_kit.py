from __future__ import annotations

import json
import os
import re
from collections import Counter, defaultdict
from pathlib import Path

KIT_DEFAULT = Path(
    "imported/Map and Character/Fantasy tileset - 2D Isometric"
)

# Examples in this kit:
#   Ground A10_N.png
#   Wall A3_W.png
#   Roof B12_E.png
#   Chest A2_S.png
#   FirePlace.png
DIR_RE = re.compile(r"_(?P<dir>[ENSW])$")
CODE_RE = re.compile(r"^(?P<prefix>[A-Za-z]+)\s+(?P<code>[A-Z]\d{1,2})_(?P<dir>[ENSW])$")


def first_token(name: str) -> str:
    # Rough category used earlier: first chunk split by space/underscore.
    base = Path(name).stem
    return re.split(r"[ _]", base, maxsplit=1)[0]


def main() -> int:
    root = Path(os.environ.get("FANTASY_ISO_KIT", str(KIT_DEFAULT)))
    if not root.exists():
        raise SystemExit(f"Missing kit dir: {root}")

    pngs = list(root.rglob("*.png"))
    by_folder = Counter()
    by_prefix = Counter()
    by_token = Counter()

    # More structured breakdown for Environment-ish tiles
    by_struct_prefix = Counter()
    by_struct_code = Counter()
    by_struct_dir = Counter()

    # Samples per token/prefix
    token_samples: dict[str, list[str]] = defaultdict(list)
    prefix_samples: dict[str, list[str]] = defaultdict(list)

    for p in pngs:
        rel = p.relative_to(root).as_posix()
        parts = rel.split("/")
        top = parts[0] if parts else "(root)"
        by_folder[top] += 1

        tok = first_token(p.name)
        by_token[tok] += 1
        if len(token_samples[tok]) < 12:
            token_samples[tok].append(rel)

        stem = p.stem
        m = CODE_RE.match(stem)
        if m:
            pref = m.group("prefix")
            code = m.group("code")
            d = m.group("dir")
            by_struct_prefix[pref] += 1
            by_struct_code[f"{pref} {code}"] += 1
            by_struct_dir[d] += 1
            by_prefix[pref] += 1
            if len(prefix_samples[pref]) < 12:
                prefix_samples[pref].append(rel)
        else:
            # still count alpha prefix when present
            alpha = re.match(r"^[A-Za-z]+", stem)
            if alpha:
                by_prefix[alpha.group(0)] += 1

    out_dir = root.parent  # put reports next to the kit folder
    json_path = out_dir / "fantasy_iso_kit_inventory.json"
    md_path = out_dir / "fantasy_iso_kit_inventory.md"

    payload = {
        "kit_root": str(root.as_posix()),
        "png_count": len(pngs),
        "by_top_folder": by_folder.most_common(),
        "by_first_token": by_token.most_common(),
        "by_alpha_prefix": by_prefix.most_common(),
        "structured": {
            "by_prefix": by_struct_prefix.most_common(),
            "by_dir": by_struct_dir.most_common(),
            "top_codes": by_struct_code.most_common(60),
        },
        "samples": {
            "by_first_token": dict(token_samples),
            "by_struct_prefix": dict(prefix_samples),
        },
    }

    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    # Markdown: human-friendly summary
    def md_table(rows: list[tuple[str, int]], title: str, limit: int = 40) -> str:
        lines = [f"## {title}", "", "| Name | Count |", "|---|---:|"]
        for name, count in rows[:limit]:
            lines.append(f"| {name} | {count} |")
        lines.append("")
        return "\n".join(lines)

    md = [
        f"# Fantasy Isometric Kit Inventory\n\nRoot: `{root.as_posix()}`\n\nPNG count: **{len(pngs)}**\n",
        md_table(by_folder.most_common(), "Top-Level Folders", limit=20),
        md_table(by_token.most_common(), "First-Token Categories (rough)", limit=60),
        md_table(by_struct_prefix.most_common(), "Structured Prefixes (e.g., Ground/Wall/Roof)", limit=60),
        "## Structured Direction Suffix\n\n| Dir | Count |\n|---|---:|\n"
        + "\n".join([f"| {d} | {c} |" for d, c in by_struct_dir.most_common()])
        + "\n\n",
        "## Samples (by first token)\n",
    ]

    for tok, _count in by_token.most_common(40):
        md.append(f"### {tok}\n")
        for s in token_samples.get(tok, [])[:10]:
            md.append(f"- `{s}`")
        md.append("")

    md_path.write_text("\n".join(md), encoding="utf-8")

    print(f"Wrote: {json_path}")
    print(f"Wrote: {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
