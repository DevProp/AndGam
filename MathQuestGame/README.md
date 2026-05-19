# MathQuest: Realms of Numbers

A production-grade 3D math learning game for Android built with Godot 4.x.

## 🎯 Project Overview

MathQuest is a stage-based 3D linear adventure where mathematics is the core structural puzzle mechanic. Players journey through 5 historical "Math Realms," each governed by an ancient mathematical master.

### Historical Realms
1. **Stage 1: The Isle of Patterns** - Pythagoras (Ancient Greece) - Spatial Reasoning & Cardinality
2. **Stage 2: The Cosmic Gears** - Aryabhata (Ancient India) - Place Value & Fractions
3. **Stage 3: The Oasis of Balance** - Al-Khwarizmi (Islamic Golden Age) - Early Algebra & Balancing Variables ✓ *Vertical Slice*
4. **Stage 4: The Citadel of Fluids** - Archimedes (Ancient Sicily) - Ratios & Volumetric Physics
5. **Stage 5: The Labyrinth of Networks** - Euler & Gauss (Enlightenment) - Graph Theory & Sequential Logic

## 📁 Project Structure

```
MathQuestGame/
├── scripts/
│   ├── autoloads/          # Global singletons
│   │   ├── GameManager.gd      (262 lines)
│   │   ├── AudioManager.gd     (274 lines)
│   │   ├── DifficultyManager.gd (381 lines)
│   │   ├── SaveManager.gd      (287 lines)
│   │   └── NativeBridge.gd     (325 lines)
│   ├── core/
│   │   └── BalanceScale.gd     (459 lines) - Stage 3 vertical slice
│   ├── entities/
│   │   └── WeightBlock.gd
│   └── utils/
│       └── EquationGenerator.gd
├── scenes/
│   ├── Main.tscn               # Entry point scene
│   └── realms/
│       └── Stage3_Balance.tscn # Stage 3 complete scene
├── assets/
│   ├── blender_scripts/        # Python scripts for asset generation
│   │   ├── generate_stage1_assets.py
│   │   └── generate_stage3_assets.py
│   ├── models/                 # .glb files (run Blender scripts to generate)
│   ├── textures/
│   ├── audio/
│   └── icons/
│       └── app_icon.svg
├── android/build/              # Custom Gradle template for Android Studio
│   ├── build.gradle
│   ├── AndroidManifest.xml
│   └── src/main/java/.../MathQuestPlugin.java
├── export_presets/
│   └── export_presets.cfg
└── project.godot
```

## 🚀 Getting Started

### Prerequisites
- Godot 4.2+ (https://godotengine.org/download)
- Blender 3.6+ (for asset generation)
- Android Studio (for native builds)
- JDK 17+

### Step 1: Generate 3D Assets
Open Blender and run the asset generation scripts:

```python
# In Blender: File > Run Script > select generate_stage3_assets.py
# This creates: assets/models/stage3_balance_scale.glb
```

### Step 2: Open in Godot
1. Open Godot 4.2+
2. Import project from `/workspace/MathQuestGame`
3. Godot will automatically import all assets

### Step 3: Install Android Build Template
```bash
cd /workspace/MathQuestGame
godot --install-android-build-template
```

### Step 4: Configure Export
1. Go to Project > Export
2. Add Android preset (configuration already in `export_presets/export_presets.cfg`)
3. Ensure ARM64-v8a architecture is selected
4. Set minimum SDK: 29, target SDK: 34

### Step 5: Build APK
```bash
godot --export-release Android export/android/MathQuest.apk
```

Or open `android/build` in Android Studio for native debugging.

## 🎮 Core Features

### Adaptive Difficulty Engine
- Real-time telemetry collection (time-to-solve, mistake frequency, hint usage)
- Rolling 10-puzzle window analysis
- Invisible parameter adjustment without changing level layout
- Three weighted metrics: Time (35%), Mistakes (40%), Hints (25%)

### Physics-Based Math Puzzles
- Torque simulation for balance scale mechanics
- Equilibrium detection with epsilon threshold (0.5kg)
- Variable X block tracking for algebraic validation
- 120 ticks/sec physics simulation

### Native Android Integration
- Custom Java plugin (`MathQuestPlugin.java`)
- Haptic feedback patterns
- Play Games Services stubs
- Low-level performance profiling hooks

## 🔧 Technical Specifications

### Rendering (Mobile Optimized)
- Renderer: Mobile Vulkan / GLES3 Compatibility
- Shadow Atlas: 1024px
- Texture Compression: ASTC (Android), ETC2 fallback
- MSAA: Disabled for performance
- SSAO/SSIL: Disabled

### Physics
- Ticks per second: 120
- Collision layers: 8 configured (world, player, interactables, platforms, weights, triggers, UI, effects)
- Damping factor: 0.95 for smooth oscillation

### Audio Buses
- Master
- Music (-10dB default)
- SFX (-5dB default)
- Voice

## 📊 Code Statistics

| Component | Lines | Description |
|-----------|-------|-------------|
| BalanceScale.gd | 459 | Physics-based scale simulation |
| DifficultyManager.gd | 381 | Adaptive difficulty engine |
| NativeBridge.gd | 325 | Android JNI interface |
| SaveManager.gd | 287 | JSON serialization + backups |
| AudioManager.gd | 274 | Crossfading + pooling |
| GameManager.gd | 262 | Game state + progression |
| **Total GDScript** | **~2,000** | Strictly typed GDScript 2.0 |

## 🎨 Asset Pipeline

### Blender → Godot Workflow
1. Run Python script in Blender
2. Export as `.glb` (glTF 2.0 binary)
3. Settings: Y-Up, WEBP textures, 1024px max
4. Godot auto-imports with correct scale

### Mobile Optimization Checklist
- Triangle count: ≤5,000 per hero prop
- Bone count: ≤45 per character
- Texture size: 1024×1024 max
- Materials: Unshaded or simple PBR
- Animations: Baked bone transforms

## 📱 Android Configuration

### Permissions
- `android.permission.VIBRATE` - Haptic feedback

### Architectures
- ✅ ARM64-v8a (primary)
- ❌ ARMv7, x86, x86_64 (disabled)

### SDK Versions
- Minimum: 29 (Android 10)
- Target: 34 (Android 14)

## 🧪 Testing the Vertical Slice (Stage 3)

1. Run the project in Godot
2. Click "Begin Journey" on main menu
3. You'll enter Al-Khwarizmi's Oasis of Balance
4. Drag weight blocks onto left/right platforms
5. Solve equations like `3 + X = 8` by placing correct X mass
6. Scale tilts based on mass differential
7. When balanced, solution is validated

## 📄 License

All code and assets are open source under MIT License.

## 👥 Credits

Built with:
- Godot 4.x Engine
- Blender 3D
- Android SDK
- glTF 2.0 format

Historical consultants: Pythagoras, Aryabhata, Al-Khwarizmi, Archimedes, Euler, Gauss
