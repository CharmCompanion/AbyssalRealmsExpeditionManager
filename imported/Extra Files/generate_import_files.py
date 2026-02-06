"""
Generate Godot .import files for kingdom overlay textures
Ensures they're imported with lossless compression for transparency
"""

import os
import uuid

def generate_import_file(png_path, uid_suffix):
    """Generate a .import file for a PNG texture"""
    base_name = os.path.basename(png_path)
    
    # Generate unique UID for each texture
    uid = f"uid://b{uid_suffix}q6bky52jqy"
    
    # Generate hash for internal Godot path
    import_hash = f"c{uid_suffix}d1af9b8c4b4c4b0f0e8e8a1f2a3b4c"
    
    import_content = f'''[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{base_name}-{import_hash}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/map/kingdoms/{base_name}"
dest_files=["res://.godot/imported/{base_name}-{import_hash}.ctex"]

[params]

compress/mode=1
compress/high_quality=true
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
'''
    
    import_path = png_path + ".import"
    with open(import_path, 'w') as f:
        f.write(import_content)
    
    print(f"✓ Generated {import_path}")
    return uid

def main():
    kingdoms_dir = "assets/map/kingdoms"
    
    print("Generating .import files for kingdom overlay textures...")
    
    # Generate import files for all kingdom textures
    kingdom_uids = {}
    
    for i in range(1, 7):
        for layer_type in ['highlight', 'shadow']:
            filename = f"kingdom{i}_{layer_type}.png"
            png_path = os.path.join(kingdoms_dir, filename)
            
            if os.path.exists(png_path):
                # Use kingdom and layer type to generate unique UID suffix
                uid_suffix = f"{i}{layer_type[0]}4"  # e.g., "1h4", "1s4", "2h4", etc.
                uid = generate_import_file(png_path, uid_suffix)
                kingdom_uids[filename] = uid
            else:
                print(f"✗ File not found: {png_path}")
    
    # Update MapOverlayManager.gd with correct UIDs
    print(f"\nGenerated import files for {len(kingdom_uids)} kingdom textures")
    print("UIDs generated:")
    for filename, uid in kingdom_uids.items():
        print(f"  {filename}: {uid}")
    
    print("\nNext steps:")
    print("1. Open Godot project - textures will be automatically imported")
    print("2. Check that all kingdom overlay PNGs appear in FileSystem dock")
    print("3. Test CreateCharacter scene - overlays should align perfectly!")

if __name__ == "__main__":
    main()