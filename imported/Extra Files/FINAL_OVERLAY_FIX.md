# 🔧 FINAL FIX: Manual PNG Overlay Setup

**The overlays are misaligned because the SVG runtime system uses wrong coordinates.**  
**Your manually created PNGs will fix this completely!**

## 🎯 **Quick Setup to Fix Overlay Alignment:**

### **Step 1: Add Manual Overlay Node to Scene**

1. **Open CreateCharacter.tscn** in Godot
2. **Navigate to:** `PageContainer/RightPage/RightPageContent/MapSection/MapContainer`
3. **Right-click MapContainer** → Add Child
4. **Add a Control node** named `ManualKingdomOverlays`
5. **Attach script:** `res://scripts/ui/ManualKingdomOverlays.gd`
6. **Set anchors:** Full Rect (0,0,1,1) so it covers the entire map area

### **Step 2: Fix City Dot Size**

The city dot is probably a ColorRect that's too large. In the scene:

1. **Find:** `MapContainer/CityDot/DotSprite` (ColorRect)
2. **Set size to:** 6x6 pixels instead of 12x12
3. **Or change to:** A small TextureRect with a 6x6 red dot image

## ✅ **What This Fixes:**

### **Overlay Alignment Issue:**
- ❌ **Old system:** Runtime SVG with wrong viewBox (`1000x600` vs actual `843.75x568.5`)
- ✅ **New system:** Your manually created PNGs with exact same artboard = perfect alignment

### **City Dot Size Issue:**
- ❌ **Old:** Large 12x12 dot or oversized ColorRect
- ✅ **New:** Small 6x6 dot centered properly

## 🎮 **Expected Results After Setup:**

✅ **Perfect overlay alignment** - your PNG shapes will match exactly  
✅ **Small red dot** - 6x6 pixel dot in kingdom centers  
✅ **No more coordinate mismatches** - everything uses same source  
✅ **Professional appearance** - clean, precise highlighting  

## 🚨 **If Still Having Issues:**

### **Dot Still Too Large:**
- Check `CityDot` node size in scene
- Make sure it's 6x6 pixels, not percentage-based sizing
- Consider using a small PNG image instead of ColorRect

### **Overlays Still Wrong:**
- Verify ManualKingdomOverlays node is added correctly
- Check that PNG files are imported with transparency
- Ensure all PNG files have same dimensions (your artboard size)

Your manually created kingdom shapes are the **perfect solution** - they'll align exactly because they came from the same source as your base map! 🎯