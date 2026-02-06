"""
Kit-bash S13 City Builder 8-bit assets into medieval building sprites.
Scale up 4x with nearest neighbor, apply warm medieval palette shift.
"""
from PIL import Image
import os, shutil

S13_BASE = "imported/UI Assets/City Builder/S13_city_builder_8bits_assets/spring"
OUT_DIR = "web_game/static/images/buildings"
os.makedirs(OUT_DIR, exist_ok=True)

SCALE = 4

BUILDING_MAP = {
    "house": {
        "1x1": f"{S13_BASE}/buildings/house_red_1x1.png",
        "1x2": f"{S13_BASE}/buildings/house_red_1x2.png",
        "2x1": f"{S13_BASE}/buildings/house_red_2x1.png",
        "2x2": f"{S13_BASE}/buildings/house_red_2x2.png",
        "grid_w": 1, "grid_h": 1,
    },
    "cottage": {
        "1x1": f"{S13_BASE}/buildings/house_blue_1x1.png",
        "1x2": f"{S13_BASE}/buildings/house_blue_1x2.png",
        "2x1": f"{S13_BASE}/buildings/house_blue_2x1.png",
        "2x2": f"{S13_BASE}/buildings/house_blue_2x2.png",
        "grid_w": 1, "grid_h": 1,
    },
    "estate": {
        "1x1": f"{S13_BASE}/buildings/apartment_1x1.png",
        "1x2": f"{S13_BASE}/buildings/apartment_1x2.png",
        "2x1": f"{S13_BASE}/buildings/apartment_2x1.png",
        "2x2": f"{S13_BASE}/buildings/apartment_2x2.png",
        "grid_w": 2, "grid_h": 2,
    },
    "bank": {
        "1x1": f"{S13_BASE}/buildings/storage_1x1.png",
        "2x2": f"{S13_BASE}/buildings/storage_2x2.png",
        "grid_w": 2, "grid_h": 2,
    },
    "guild": {
        "1x1": f"{S13_BASE}/buildings/shop_1x1.png",
        "1x2": f"{S13_BASE}/buildings/shop_1x2.png",
        "2x1": f"{S13_BASE}/buildings/shop_2x1.png",
        "2x2": f"{S13_BASE}/buildings/shop_2x2.png",
        "grid_w": 2, "grid_h": 2,
    },
    "school": {
        "1x1": f"{S13_BASE}/buildings/education_school_1x1.png",
        "2x2": f"{S13_BASE}/buildings/education_highschool_2x2.png",
        "grid_w": 2, "grid_h": 2,
    },
    "temple": {
        "1x1": f"{S13_BASE}/buildings/administration_1x1.png",
        "2x2": f"{S13_BASE}/buildings/administration_tribunal_2x2.png",
        "grid_w": 2, "grid_h": 2,
    },
    "manor": {
        "1x1": f"{S13_BASE}/buildings/administration_prison_3x2.png",
        "2x2": f"{S13_BASE}/buildings/education_university_3x2.png",
        "grid_w": 3, "grid_h": 2,
    },
}

def medieval_palette_shift(img):
    """Shift modern colors toward warm medieval tones."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 10:
                continue

            r_f, g_f, b_f = r / 255.0, g / 255.0, b / 255.0

            if b_f > 0.5 and r_f < 0.4 and g_f < 0.4:
                r = min(255, int(b * 0.5 + 60))
                g = min(255, int(b * 0.35 + 40))
                b = min(255, int(b * 0.25 + 30))
            elif b_f > 0.4 and g_f > 0.4 and r_f < 0.5:
                r = min(255, int((r + g) * 0.4 + 40))
                g = min(255, int(g * 0.6 + 30))
                b = min(255, int(b * 0.3 + 20))
            elif g_f > 0.6 and r_f < 0.5 and b_f < 0.4:
                pass
            else:
                warmth = 0.12
                r = min(255, int(r * (1 + warmth)))
                g = min(255, int(g * (1 + warmth * 0.3)))
                b = max(0, int(b * (1 - warmth * 0.5)))

            pixels[x, y] = (r, g, b, a)

    return img


def process_building(name, config):
    """Process a building: scale up and apply medieval palette."""
    print(f"Processing {name}...")

    for size_key, src_path in config.items():
        if size_key in ("grid_w", "grid_h"):
            continue
        if not os.path.exists(src_path):
            print(f"  Skipping {size_key} - file not found: {src_path}")
            continue

        img = Image.open(src_path).convert("RGBA")
        img_medieval = medieval_palette_shift(img)
        w, h = img_medieval.size
        img_scaled = img_medieval.resize((w * SCALE, h * SCALE), Image.NEAREST)

        out_name = f"{name}_{size_key}.png"
        out_path = os.path.join(OUT_DIR, out_name)
        img_scaled.save(out_path)
        print(f"  Saved {out_name} ({w*SCALE}x{h*SCALE})")

        if size_key == "1x1":
            img_flipped = img_scaled.transpose(Image.FLIP_LEFT_RIGHT)
            flip_name = f"{name}_1x1_flip.png"
            img_flipped.save(os.path.join(OUT_DIR, flip_name))
            print(f"  Saved {flip_name} (flipped)")


TILE_MAP = {
    "grass": f"{S13_BASE}/tilesets/grass.png",
    "trees_rocks": f"{S13_BASE}/tilesets/trees_rocks.png",
    "water": f"{S13_BASE}/tilesets/water.png",
    "roads": f"{S13_BASE}/tilesets/roads_rails_godot_autotile.png",
}


def process_tilesets():
    """Scale up tilesets for the town map ground."""
    print("\nProcessing tilesets...")
    for name, src_path in TILE_MAP.items():
        if not os.path.exists(src_path):
            print(f"  Skipping {name}")
            continue

        img = Image.open(src_path).convert("RGBA")
        if name != "grass":
            img = medieval_palette_shift(img)
        w, h = img.size
        img_scaled = img.resize((w * SCALE, h * SCALE), Image.NEAREST)
        out_path = os.path.join(OUT_DIR, f"tile_{name}.png")
        img_scaled.save(out_path)
        print(f"  Saved tile_{name}.png ({w*SCALE}x{h*SCALE})")


def extract_grass_tile():
    """Extract a single grass tile from the tileset for use as grid background."""
    src = f"{S13_BASE}/tilesets/grass.png"
    if not os.path.exists(src):
        return
    img = Image.open(src).convert("RGBA")
    tile = img.crop((0, 0, 16, 16))
    tile_scaled = tile.resize((16 * SCALE, 16 * SCALE), Image.NEAREST)
    tile_scaled.save(os.path.join(OUT_DIR, "grass_single.png"))
    print("  Saved grass_single.png")


if __name__ == "__main__":
    for name, config in BUILDING_MAP.items():
        process_building(name, config)
    process_tilesets()
    extract_grass_tile()
    print("\nDone! All assets processed.")
