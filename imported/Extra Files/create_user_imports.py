"""
Generate Godot .import files for the user's actual kingdom overlay textures
Uses their exact filenames with proper naming
"""

import os

def create_import_file(filename, uid_base):
    """Create a .import file for a PNG texture"""
    
    uid = f"uid://b{uid_base}kingdom_overlay"
    hash_id = f"{uid_base}kingdom{len(filename)}overlay"
    
    import_content = f'''[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{filename}-{hash_id}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/map/kingdoms/{filename}"
dest_files=["res://.godot/imported/{filename}-{hash_id}.ctex"]

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
    
    import_path = f"assets/map/kingdoms/{filename}.import"
    with open(import_path, 'w') as f:
        f.write(import_content)
    
    print(f"✓ Generated {import_path}")

def main():
    print("Creating .import files for your kingdom overlay textures...")
    
    # Kingdom overlay files (your actual filenames)
    kingdom_files = [
        "VylfodDominionHighlight.png",
        "VylfodDominionShadow.png",
        "RabaricRepublicHighlight.png", 
        "RabaricRepublicShadow.png",
        "KingdomofElRuhnHighlight.png",
        "KingdomofElRuhnShadow.png",
        "KelsinFederationHighlight.png",
        "KelsinFederationShadow.png",
        "DivineEmpireofGosainHighlight.png",
        "DivineEmpireofGosainShadow.png",
        "YozuanDesertHighlight.png",
        "YozuanDesertShadow.png"
    ]
    
    # Optional: Base kingdom images and extras
    extra_files = [
        "VylfodDominion.png",
        "RabaricRepublic.png", 
        "KingdomofElRuhn.png",
        "KelsinFederation.png",
        "DivineEmpireofGosain.png",
        "YozuanDesert.png",
        "BiomeDrt.png",
        "BiomeFst.png",
        "BiomeIce.png", 
        "BiomeJgl.png",
        "BiomeMtn.png",
        "BiomePln.png",
        "BoarderLines.png",
        "Names.png",
        "Water.png"
    ]
    
    # Create import files for all kingdom overlays
    for i, filename in enumerate(kingdom_files):
        file_path = f"assets/map/kingdoms/{filename}"
        if os.path.exists(file_path):
            create_import_file(filename, f"{i+1:02d}")
        else:
            print(f"⚠ File not found: {filename}")
    
    # Create import files for extra assets
    for i, filename in enumerate(extra_files):
        file_path = f"assets/map/kingdoms/{filename}"  
        if os.path.exists(file_path):
            create_import_file(filename, f"x{i+1:02d}")
    
    print(f"\n✅ Import files created for your kingdom textures!")
    print("✅ These use your exact filenames and proper transparency settings")
    print("\nNext steps:")
    print("1. Open Godot - textures will import automatically")
    print("2. Test CreateCharacter scene - your exact shapes should overlay perfectly!")
    print("3. Check that overlays align with your base map")

if __name__ == "__main__":
    main()