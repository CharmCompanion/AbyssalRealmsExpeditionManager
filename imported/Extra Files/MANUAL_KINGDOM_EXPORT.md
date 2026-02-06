# 🎯 MANUAL KINGDOM SHAPE EXPORT GUIDE

**Problem:** You need the exact kingdom shapes, not rectangles, for perfect overlay alignment.

**Solution:** Export the shapes manually from your SVG - this guarantees perfect results!

## 🔧 **METHOD 1: Using Inkscape (FREE & BEST RESULTS)**

### **Download Inkscape:**
- Get it free: https://inkscape.org/release/
- Install and open `assets/map/Map.svg`

### **Export Process (12 files total):**

**For each kingdom (6 kingdoms × 2 versions = 12 files):**

#### **Kingdom 1: Vylfod_Dominion**
1. **Open Map.svg** in Inkscape
2. **Select the Vylfod_Dominion path** (click on it)
3. **Hide all other elements:** 
   - Select all other paths/elements
   - Press `Ctrl+H` to hide them
4. **Create Highlight version:**
   - With Vylfod_Dominion selected, set fill to **white (#FFFFFF)**
   - Set opacity to **70%**
   - Export as PNG: `kingdom1_highlight.png`
   - Size: **2531 × 1705 pixels** (maintains 843.75:568.5 ratio)
5. **Create Shadow version:**
   - Change fill to **black (#000000)**
   - Set opacity to **50%**
   - Export as PNG: `kingdom1_shadow.png`
   - Size: **2531 × 1705 pixels**

#### **Repeat for all kingdoms:**
- **Kingdom 2:** Rabaric_Republic → `kingdom2_highlight.png` & `kingdom2_shadow.png`
- **Kingdom 3:** Kingdom_of_El_Ruhn → `kingdom3_highlight.png` & `kingdom3_shadow.png`  
- **Kingdom 4:** Kelsin_Federation → `kingdom4_highlight.png` & `kingdom4_shadow.png`
- **Kingdom 5:** Divine_Empire_of_Gosain → `kingdom5_highlight.png` & `kingdom5_shadow.png`
- **Kingdom 6:** Yozuan_Desert → `kingdom6_highlight.png` & `kingdom6_shadow.png`

### **Inkscape Export Settings:**
```
File → Export as PNG
Width: 2531 pixels
Height: 1705 pixels  
DPI: 300
Area: Page
Format: PNG
```

## 🔧 **METHOD 2: Using Adobe Illustrator (If you have it)**

1. **Open Map.svg** in Illustrator
2. **For each kingdom path:**
   - Select the specific kingdom path
   - Copy it (`Ctrl+C`)
   - Create new document (843.75 × 568.5 units)
   - Paste in place (`Ctrl+Shift+V`)
   - Set fill to white/black with transparency
   - Export as PNG at 300% scale

## 🔧 **METHOD 3: Online SVG Editor (Free alternative)**

1. **Go to:** https://editor.method.ac/ 
2. **Upload your Map.svg**
3. **Select each kingdom path individually**
4. **Export with transparency**

---

## 📁 **File Organization**

**Save all 12 files to:**
```
assets/map/kingdoms/
├── kingdom1_highlight.png  ← Vylfod_Dominion (white)
├── kingdom1_shadow.png     ← Vylfod_Dominion (black)  
├── kingdom2_highlight.png  ← Rabaric_Republic (white)
├── kingdom2_shadow.png     ← Rabaric_Republic (black)
├── kingdom3_highlight.png  ← Kingdom_of_El_Ruhn (white)
├── kingdom3_shadow.png     ← Kingdom_of_El_Ruhn (black)
├── kingdom4_highlight.png  ← Kelsin_Federation (white)
├── kingdom4_shadow.png     ← Kelsin_Federation (black)
├── kingdom5_highlight.png  ← Divine_Empire_of_Gosain (white)
├── kingdom5_shadow.png     ← Divine_Empire_of_Gosain (black)
├── kingdom6_highlight.png  ← Yozuan_Desert (white)
└── kingdom6_shadow.png     ← Yozuan_Desert (black)
```

---

## ⚡ **CRITICAL REQUIREMENTS:**

✅ **Exact size:** 2531 × 1705 pixels (maintains SVG aspect ratio)  
✅ **Transparency:** PNG format with transparent background  
✅ **Colors:** White (#FFFFFF) for highlights, Black (#000000) for shadows  
✅ **Opacity:** 70% for highlights, 50% for shadows  
✅ **Exact shapes:** Must be the actual kingdom paths, not rectangles  

---

## 🎯 **Why This Works:**

- **Same source:** Your Map.svg → guarantees perfect alignment
- **Exact shapes:** Real kingdom boundaries, not approximations  
- **Correct coordinate system:** Maintains original SVG proportions
- **Perfect overlay:** Will align pixel-perfectly with your base map

---

## 🔄 **After Export:**

1. **Copy all 12 PNG files** to `assets/map/kingdoms/`
2. **Open Godot** - it will auto-import the textures  
3. **Test CreateCharacter scene** - overlays should be PERFECT shapes
4. **Check alignment** - shapes should match exactly with base map

This manual method **guarantees perfect results** since you're using the exact same source file with the exact same coordinate system!

## 📞 **Need Help?**

If you have issues with any export tool, let me know and I can guide you through the specific software steps!