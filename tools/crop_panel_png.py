from __future__ import annotations

from pathlib import Path

from PIL import Image


def crop_to_alpha_bbox(src: Path) -> Image.Image:
    img = Image.open(src).convert("RGBA")
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"No non-transparent pixels found in {src}")
    return img.crop(bbox)


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    src = repo_root / "assets" / "ui" / "panel" / "Panel.png"

    if not src.exists():
        raise SystemExit(f"Missing: {src}")

    backup = src.with_suffix(src.suffix + ".bak")
    if not backup.exists():
        backup.write_bytes(src.read_bytes())

    cropped = crop_to_alpha_bbox(src)
    cropped.save(src)

    print("Cropped Panel.png")
    print("  backup:", backup)
    print("  new size:", cropped.size)


if __name__ == "__main__":
    main()
