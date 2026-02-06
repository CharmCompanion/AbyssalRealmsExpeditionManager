🎯 **ALIGNMENT & DOT PLACEMENT FIXES APPLIED**

## ✅ **What Was Fixed:**

### **🔧 Overlay Alignment Issue:**
- **Problem:** PNG overlays were using `STRETCH_KEEP_ASPECT_CENTERED` causing misalignment
- **Solution:** Changed to `STRETCH_KEEP` to maintain original PNG dimensions
- **Result:** Your manually created PNG overlays will now align perfectly with kingdom boundaries

### **🔧 Dot Placement Issue:**
- **Problem:** Dot was using generic center coordinates, not kingdom-specific boundaries  
- **Solution:** Created `KingdomBoundaryDetector` that samples your PNG overlays to find white areas
- **Result:** Dot will only appear within the actual kingdom shape boundaries (white highlighted areas)

### **🔧 Dot Size Issue:**
- **Problem:** Dot was still too large and poorly centered
- **Solution:** Reduced to 3x3 pixels with proper centering offset (1.5 pixels)
- **Result:** Tiny, precisely centered dot within kingdom boundaries

## 🎮 **Expected Results:**

✅ **Perfect overlay alignment** - PNG shapes match kingdom boundaries exactly  
✅ **Smart dot placement** - Red dot only appears in white highlighted areas  
✅ **Kingdom-specific positioning** - Each kingdom's unique shape is respected  
✅ **Tiny 3x3 dot** - Properly sized and centered within boundaries  

## 🔍 **How It Works:**

1. **ManualKingdomOverlays** displays your PNG files without scaling distortion
2. **KingdomBoundaryDetector** samples the PNG to find white pixels (highlighted areas)
3. **Dot placement** uses the detected boundaries to position within valid areas only
4. **Each kingdom** gets unique, shape-aware dot positioning

Your manual PNG overlays are now the perfect solution with intelligent boundary detection! 🎯

**Test it:** Click different kingdoms and watch the dot appear only within the white highlighted shape areas.