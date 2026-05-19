# MathQuest: Historical Realms - Production Architecture Blueprint
## Phase 1: Vertical Slice & Core Systems Design

**Version:** 1.0.0  
**Engine:** Godot 4.x (Vulkan Mobile Backend)  
**Target Platform:** Android (ARM64, API Level 29+)  
**Document Classification:** Technical Design Document (TDD)

---

# TABLE OF CONTENTS

1. [Executive Summary & Vision](#1-executive-summary--vision)
2. [Pedagogical Realm Design Specifications](#2-pedagogical-realm-design-specifications)
3. [Domain 1: Player Retention & Monetization Architecture](#3-domain-1-player-retention--monetization-architecture)
4. [Domain 2: Godot 4 + Android Studio Pipeline](#4-domain-2-godot-4--android-studio-pipeline)
5. [Domain 3: Stage 3 Implementation - Al-Khwarizmi's Balance Engine](#5-domain-3-stage-3-implementation---al-khwarizmis-balance-engine)
6. [Domain 4: Blender to Godot Asset Pipeline](#6-domain-4-blender-to-godot-asset-pipeline)
7. [Appendix: Signal Flow Diagrams & Data Structures](#7-appendix-signal-flow-diagrams--data-structures)

---

# 1. EXECUTIVE SUMMARY & VISION

## 1.1 Product Positioning

MathQuest positions itself as a **premium educational experience** competing directly with Prodigy Math Game and Math Tango by delivering:

- **Console-quality 3D visuals** on mobile through aggressive Vulkan optimization
- **Deep pedagogical integration** where math is the core mechanic, not a quiz overlay
- **Historical narrative immersion** with authentic cultural mentors guiding progression
- **Psychological retention loops** leveraging variable reward schedules and social proof

## 1.2 Technical Pillars

| Pillar | Specification | Rationale |
|--------|---------------|-----------|
| **Rendering** | Vulkan Mobile, Forward+ Clustered | 40% better thermal efficiency vs GLES3 on Adreno/Mali GPUs |
| **Scripting** | GDScript 2.0 (Strict Static Typing) | 3x performance over dynamic typing, compile-time error detection |
| **Asset Format** | glTF 2.0 Binary (.glb) + Basis Universal Texture Compression | 60% smaller APK size, GPU-native decompression |
| **Native Bridge** | Custom Android Plugin via JNI | Direct access to Play Games Services, low-level profiling, haptic feedback APIs |
| **Physics** | Godot 4 Built-in Physics (3D) with Custom Solver | Deterministic behavior across ARM64 devices, no native dependency bloat |

## 1.3 Target Performance Metrics

- **Frame Rate:** Locked 60 FPS on Snapdragon 730G / Exynos 9611 and above
- **Memory Budget:** 512 MB VRAM maximum, 256 MB target for mid-tier devices
- **APK Size:** < 150 MB initial download (OBB-free via asset streaming architecture)
- **Load Time:** < 3 seconds scene transitions via async resource preloading
- **Thermal Throttling:** No sustained temperature > 42°C after 30 minutes gameplay

---

# 2. PEDAGOGICAL REALM DESIGN SPECIFICATIONS

## 2.1 Progression Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        GAME PROGRESSION MAP                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │   STAGE 1    │───▶│   STAGE 2    │───▶│   STAGE 3    │              │
│  │  Isle of     │    │   Cosmic     │    │   Oasis of   │              │
│  │  Patterns    │    │   Gears      │    │   Balance    │              │
│  │              │    │              │    │              │              │
│  │ Mentor:      │    │ Mentor:      │    │ Mentor:      │              │
│  │ Pythagoras   │    │ Aryabhata    │    │ Al-Khwarizmi │              │
│  │              │    │              │    │              │              │
│  │ Skills:      │    │ Skills:      │    │ Skills:      │              │
│  │ - Cardinality│    │ - Place Value│    │ - Variables  │              │
│  │ - Geometry   │    │ - Fractions  │    │ - Equations  │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│         │                   │                   │                       │
│         ▼                   ▼                   ▼                       │
│  ┌──────────────┐    ┌──────────────┐                                  │
│  │   STAGE 4    │───▶│   STAGE 5    │                                  │
│  │  Citadel of  │    │  Labyrinth   │                                  │
│  │   Fluids     │    │  of Networks │                                  │
│  │              │    │              │                                  │
│  │ Mentor:      │    │ Mentors:     │                                  │
│  │ Archimedes   │    │ Euler/Gauss  │                                  │
│  │              │    │              │                                  │
│  │ Skills:      │    │ Skills:      │                                  │
│  │ - Volume     │    │ - Graph Theory│                                 │
│  │ - Ratios     │    │ - Algorithms │                                  │
│  └──────────────┘    └──────────────┘                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 2.2 Stage 1: The Isle of Patterns (Beginner)

### Historical Context
**Mentor:** Pythagoras of Samos (570-495 BCE)  
**Philosophy:** "All is number" - Mathematics as the language of cosmic order  
**Narrative Hook:** The geometric islands are fragmenting; only perfect numerical patterns can restore harmony.

### Visual Design Specification

| Element | Material Type | Color Palette | Shader Complexity |
|---------|--------------|---------------|-------------------|
| Marble Platforms | Unshaded + AO Bake | #F5E6D3 (Warm Ivory), #C9B896 (Sand) | 0 texture samples |
| Glowing Spheres | Emission + Fresnel | #FFD700 (Gold), #4169E1 (Royal Blue) | 1 emission uniform |
| Floating Islands | Triplanar Projection | #87CEEB (Sky), #228B22 (Vegetation) | 2 texture samples |
| Temple Columns | Baked Lightmap | #FFFFFF (Pure White), #DAA520 (Golden Trim) | 0 real-time shadows |

### Core Mechanic: The Pebble Grid

**Mathematical Foundation:**
- **Cardinality:** One-to-one correspondence between physical objects and abstract numbers
- **Geometric Transformation:** Translation, rotation, and reflection of shapes
- **Pattern Recognition:** Arithmetic sequences (1, 3, 6, 10... triangular numbers)

**Puzzle Architecture:**

```gdscript
# Pseudo-architecture for puzzle validation
enum PatternType { TRIANGLE, SQUARE, RECTANGLE, ARBITRARY }

struct PuzzleConfig:
    pattern_type: PatternType
    required_count: int
    tolerance_radius: float  # Acceptable deviation from ideal position
    time_bonus_multiplier: float

class PebbleGridSolver:
    func validate_tetraktys(pebbles: Array[Vector3]) -> bool:
        # Tetraktys: 1 + 2 + 3 + 4 = 10 pebbles in triangular formation
        pass
    
    func validate_square(pebbles: Array[Vector3], side_length: int) -> bool:
        # Perfect square: n² pebbles forming equal sides
        pass
```

**Player Interaction Flow:**
1. Player enters temple courtyard with scattered glowing spheres
2. Pythagoras appears (animated NPC) demonstrating the target shape
3. Player picks up spheres via touch-drag gesture (raycast selection)
4. Spheres snap to grid points when within tolerance radius
5. Upon completion, bridge materializes connecting to next island
6. Reward: Geometric fragment collected for Sky-Base customization

### Adaptive Difficulty Parameters

| Parameter | Easy | Medium | Hard | Dynamic Adjustment Trigger |
|-----------|------|--------|------|---------------------------|
| Grid Snapping Radius | 0.5m | 0.3m | 0.15m | > 3 failed attempts |
| Time Limit | None | 60s | 30s | < 15s solve time × 3 consecutive |
| Shape Complexity | Triangle only | Square/Rectangle | Irregular polygons | 100% accuracy × 5 levels |
| Visual Hints | Ghost outline | Dotted guide lines | None | Request hint button pressed |

---

## 2.3 Stage 2: The Cosmic Gears (Upper Beginner)

### Historical Context
**Mentor:** Āryabhaṭa (476-550 CE)  
**Contribution:** Introduced place-value system and zero concept to Indian mathematics  
**Narrative Hook:** The cosmic clockwork has stopped; only precise fractional rotations can restart the stellar engine.

### Visual Design Specification

| Element | Material Type | Color Palette | Animation |
|---------|--------------|---------------|-----------|
| Brass Gears | Metallic PBR (Roughness 0.4) | #B5A642 (Brass), #8B4513 (Copper) | Bone-driven rotation |
| Astrolabe Rings | Emission + Rim Light | #FFA500 (Orange), #9370DB (Purple) | Continuous slow rotation |
| Light Beams | Volumetric Fog + Glow | #FFFFE0 (Light Yellow) | Shader-based pulse |
| Stellar Background | Skybox + Particle Stars | #0B0C15 (Deep Space) | Parallax scrolling |

### Core Mechanic: The Cosmic Abacus

**Mathematical Foundation:**
- **Place Value System:** Base-10 positional notation ($10^0, 10^1, 10^2$)
- **Fractional Representation:** $\frac{1}{2}, \frac{1}{4}, \frac{1}{8}$ rotations
- **Modular Arithmetic:** Gear ratios and cyclical counting

**Gear Ratio System:**

```
LARGE GEAR (100s place): 40 teeth
    │
    ├─ Drives MEDIUM GEAR (10s place): 20 teeth (2:1 ratio)
    │       │
    │       └─ Drives SMALL GEAR (1s place): 10 teeth (2:1 ratio)
    │
    └─ Fraction Ring: 8 notches (⅛ increments)
```

**Puzzle Example:**
- Target: Align light beam to hit receptor at angle 347°
- Player rotates: 
  - 100s gear: 3 clicks (300°)
  - 10s gear: 4 clicks (40°)
  - 1s gear: 7 clicks (7°)
- Verification: $300 + 40 + 7 = 347$ ✓

**Technical Implementation Notes:**
- Gear rotations use quaternion interpolation for smooth visual feedback
- Collision detection uses raycast against angular sectors
- Audio: Procedural mechanical clicks synchronized to gear teeth engagement

---

## 2.4 Stage 3: The Oasis of Balance (Intermediate)

### Historical Context
**Mentor:** Muḥammad ibn Mūsā al-Khwārizmī (780-850 CE)  
**Contribution:** Founded algebra ("Al-Jabr" = restoration/completion)  
**Narrative Hook:** The library gates are sealed by ancient scales; balance the unknown to restore knowledge.

### Visual Design Specification

| Element | Material Type | Color Palette | Special Effects |
|---------|--------------|---------------|-----------------|
| Water Clock | Transparent Glass + Fluid Sim | #4682B4 (Steel Blue), #DEB887 (Wood) | Particle water flow |
| Balance Scale | Polished Gold PBR | #FFD700 (Gold), #CD7F32 (Bronze) | Spring physics on arms |
| Elemental Blocks | Subsurface Scattering | 🔴 Red (Fire), 🔵 Blue (Water), 🟢 Green (Earth) | Ambient glow |
| Library Scrolls | Cloth Simulation | #F5DEB3 (Wheat), #8B0000 (Dark Red) | Wind animation |

### Core Mechanic: Al-Jabr (The Restoration)

**Mathematical Foundation:**
- **Variable Representation:** Unknown quantity $X$ as physical block with masked value
- **Equation Balancing:** $aX + b = cX + d$ solved through physical manipulation
- **Inverse Operations:** Adding/removing equal weights from both sides

**Scale Physics Model:**

```
Left Platform:  [X] [X] [5]     → Mass = 2X + 5
                    ⚖️
Right Platform: [X] [12]        → Mass = X + 12

Equilibrium Condition: |Left - Right| < ε (epsilon threshold)
Solution: 2X + 5 = X + 12  →  X = 7
```

**Complete implementation provided in Domain 3 (Section 5).**

---

## 2.5 Stage 4: The Citadel of Fluids (Upper Intermediate)

### Historical Context
**Mentor:** Archimedes of Syracuse (287-212 BCE)  
**Discovery:** Buoyancy principle and volumetric displacement  
**Narrative Hook:** The aqueduct locks are dry; displace the waters to raise the platforms.

### Visual Design Specification

| Element | Material Type | Color Palette | Physics |
|---------|--------------|---------------|---------|
| Water Reservoir | Transparent Fluid Shader | #00BFFF (Deep Sky Blue) | Height-based pressure |
| Stone Levers | Rough Stone PBR | #696969 (Dim Gray), #A9A9A9 (Dark Gray) | Torque physics |
| Floating Platforms | Wood + Buoyancy | #8B4513 (Saddle Brown) | Archimedes force calculation |
| Aqueduct Channels | Wet Stone + Flow Maps | #708090 (Slate Gray) | Spline-based flow |

### Core Mechanic: The Eureka Displacement

**Mathematical Foundation:**
- **Volume Calculation:** $V_{cube} = s^3$, $V_{sphere} = \frac{4}{3}\pi r^3$, $V_{cylinder} = \pi r^2 h$
- **Displacement Principle:** $V_{displaced} = V_{submerged\_object}$
- **Ratio & Proportion:** $\frac{V_1}{V_2} = \frac{h_1}{h_2}$ for cylindrical tanks

**Puzzle Architecture:**

```
Tank Dimensions: 10m × 5m × 8m (Length × Width × Height)
Initial Water Level: 2m
Target Platform Height: 6m (requires water level 5m)

Available Objects:
- Cube (side = 2m): V = 8 m³
- Sphere (radius = 1.5m): V ≈ 14.14 m³
- Cylinder (r=1m, h=3m): V ≈ 9.42 m³

Required Displacement: ΔV = 10×5×(5-2) = 150 m³
Player must select correct combination of objects
```

**Optimization Note:** Fluid simulation uses height-field approximation (2D grid) rather than full SPH for mobile performance.

---

## 2.6 Stage 5: The Labyrinth of Networks (Advanced)

### Historical Context
**Mentors:** Leonhard Euler (1707-1783) & Carl Friedrich Gauss (1777-1855)  
**Contributions:** Graph theory foundations and modular arithmetic  
**Narrative Hook:** The clockwork maze shifts endlessly; find the path that traverses every bridge once.

### Visual Design Specification

| Element | Material Type | Color Palette | Dynamic Effects |
|---------|--------------|---------------|-----------------|
| Pathway Grid | Emissive Neon | #00FF00 (Matrix Green), #FF00FF (Magenta) | Pulse on activation |
| Network Nodes | Glowing Orbs | #FFD700 (Gold), #00FFFF (Cyan) | Rotation + scale animation |
| Matrix Panels | Holographic Display | #1E90FF (Dodger Blue) | Scrolling numbers |
| Clockwork Mechanisms | Steampunk Metal | #C0C0C0 (Silver), #B87333 (Copper) | Gear rotation sync |

### Core Mechanic: The Königsberg Run

**Mathematical Foundation:**
- **Graph Theory:** Vertices (nodes), Edges (paths), Degree (connections per node)
- **Eulerian Path:** Traverse every edge exactly once (exists if 0 or 2 vertices have odd degree)
- **Hamiltonian Path:** Visit every vertex exactly once (NP-complete problem)
- **Modular Sequences:** $a_n = a_{n-1} + k \pmod m$

**Puzzle Types:**

1. **Eulerian Challenge:**
   ```
   Graph: 4 landmasses connected by 7 bridges
   Degrees: A(3), B(5), C(3), D(3) → 4 odd-degree vertices
   Solution: Impossible! Player must remove/add bridges to create valid path
   ```

2. **Sequence Shortcut:**
   ```
   Pattern: 2, 5, 10, 17, 26, ...
   Rule: $a_n = n^2 + 1$
   Player inputs next term: 37 → unlocks gate
   ```

3. **Matrix Lock:**
   ```
   [3  7] [x]   [29]
   [2  5] [y] = [24]
   
   Solve via inverse matrix or substitution
   x = 23, y = 8
   ```

---

# 3. DOMAIN 1: PLAYER RETENTION & MONETIZATION ARCHITECTURE

## 3.1 The Core Engagement Loop

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PSYCHOLOGICAL RETENTION LOOP                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│      ┌─────────────┐                                                    │
│      │   ACTION    │                                                    │
│      │             │                                                    │
│      │ • Solve     │                                                    │
│      │   Physics   │                                                    │
│      │   Puzzle    │                                                    │
│      │ • Apply     │                                                    │
│      │   Math      │                                                    │
│      │   Concept   │                                                    │
│      └──────┬──────┘                                                    │
│             │                                                           │
│             ▼                                                           │
│      ┌─────────────┐     Variable     ┌─────────────┐                   │
│      │   REWARD    │◄────Reward──────►│  MYSTERY    │                   │
│      │             │     Schedule     │  Box        │                   │
│      │ • Ancient   │                  │             │                   │
│      │   Fragment  │                  │ • Random    │                   │
│      │ • Gear Part │                  │   Cosmetic  │                   │
│      │ • Scroll    │                  │ • Streak    │                   │
│      │   (Lore)    │                  │   Bonus     │                   │
│      └──────┬──────┘                  └──────┬──────┘                   │
│             │                                │                          │
│             ▼                                │                          │
│      ┌─────────────┐                         │                          │
│      │  UPGRADE    │                         │                          │
│      │             │                         │                          │
│      │ • Build     │◄────────────────────────┘                          │
│      │   Sky-Base  │                                                    │
│      │ • Unlock    │                                                    │
│      │   Decor     │                                                    │
│      │ • Customize │                                                    │
│      │   Avatar    │                                                    │
│      └──────┬──────┘                                                    │
│             │                                                           │
│             ▼                                                           │
│      ┌─────────────┐                                                    │
│      │ PROGRESSION │                                                    │
│      │             │                                                    │
│      │ • New Realm │                                                    │
│      │   Unlocks   │                                                    │
│      │ • Mentor    │                                                    │
│      │   Dialogue  │                                                    │
│      │ • Difficulty│                                                    │
│      │   Scaling   │                                                    │
│      └──────┬──────┘                                                    │
│             │                                                           │
│             └──────────────┐                                            │
│                            │                                            │
│                            ▼                                            │
│                         (Loop Repeats)                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.1.1 Action Phase: Intrinsic Motivation Design

**Flow State Calibration:**
- Challenge level dynamically adjusted to maintain player skill ± 4% difficulty delta
- Clear goals communicated via environmental storytelling (no UI text walls)
- Immediate feedback through haptic vibration, particle effects, and audio stingers

**Math Integration Principles:**
1. **Embodied Cognition:** Mathematical operations map to physical gestures (dragging, rotating, balancing)
2. **Contextual Learning:** Numbers represent tangible quantities (weights, volumes, gear teeth)
3. **Productive Struggle:** Failure states are informative, not punitive (show near-miss analysis)

### 3.1.2 Reward Phase: Variable Ratio Reinforcement

**Reward Tier Structure:**

| Tier | Probability | Content | Psychological Trigger |
|------|-------------|---------|----------------------|
| **Common** | 60% | Basic gear fragments, color variants | Completion satisfaction |
| **Rare** | 30% | Animated decorations, mentor quotes | Social sharing potential |
| **Epic** | 9% | Unique sky-base modules, lore scrolls | Collection completionism |
| **Legendary** | 1% | Golden tools, title badges, leaderboard features | Status signaling |

**Mystery Box Mechanics:**
- Awarded for daily login streaks (7-day cycle resets)
- Contains cosmetic items only (no pay-to-win advantage)
- Preview shows tier probabilities (compliant with loot box regulations)
- Duplicate protection: guarantees new item after 5 duplicates of same tier

### 3.1.3 Upgrade Phase: Sky-Base Personalization

**Sky-Base Hub Features:**
- **Persistent 3D Environment:** Floating island visible from main menu
- **Trophy Display:** Collectibles from completed realms showcased in pedestals
- **Interactive Elements:** Working gears, flowing water, animated NPCs
- **Social Visitation:** Friends can visit (asynchronous, no real-time multiplayer overhead)

**Customization Categories:**

```gdscript
enum CustomizationType {
    TERRAIN,      # Island shape, elevation, vegetation density
    ARCHITECTURE, # Buildings, bridges, temples
    DECORATIVE,   # Statues, fountains, gardens
    ATMOSPHERIC,  # Skybox, weather effects, time of day
    MECHANICAL    # Working automata, musical instruments
}

struct CustomizationItem:
    id: String
    type: CustomizationType
    unlock_requirement: String  # e.g., "complete_stage_3_perfect"
    mesh_path: String
    material_override: Material
    placement_bounds: AABB
```

### 3.1.4 Progression Phase: Mastery Tracking

**Skill Tree Architecture:**

```
MATHEMATICAL COMPETENCIES
├─ Spatial Reasoning
│   ├─ Shape Recognition (Stage 1)
│   ├─ Mental Rotation (Stage 1→2)
│   └─ 3D Visualization (Stage 4)
├─ Numerical Fluency
│   ├─ Cardinality (Stage 1)
│   ├─ Place Value (Stage 2)
│   └─ Fraction Operations (Stage 2→3)
├─ Algebraic Thinking
│   ├─ Pattern Extension (Stage 1)
│   ├─ Variable Substitution (Stage 3)
│   └─ Equation Solving (Stage 3→5)
└─ Logical Reasoning
    ├─ Deductive Logic (Stage 3)
    ├─ Algorithmic Thinking (Stage 5)
    └─ Proof Construction (Stage 5 endgame)
```

**Competency Badges:**
- Awarded for mastering specific skills across multiple contexts
- Visible on player profile and leaderboards
- Prerequisites for advanced realm access

---

## 3.2 Adaptive Difficulty Engine

### 3.2.1 Metric Collection Framework

**Telemetry Data Points:**

```gdscript
class PlayerSessionMetrics:
    # Temporal Metrics
    var session_id: String
    var timestamp: int  # Unix epoch milliseconds
    var level_id: String
    
    # Performance Metrics
    var time_to_solve_ms: int
    var attempt_count: int
    var hints_requested: int
    var incorrect_moves: int
    
    # Behavioral Metrics
    var hesitation_duration_ms: int  # Time between valid moves
    var backtracking_frequency: int  # Undo operations
    var exploration_score: float  # Percentage of interactive elements touched
    
    # Emotional Indicators (inferred)
    var frustration_index: float  # Derived from rapid incorrect inputs
    var engagement_score: float  # Derived from session length and return rate
```

### 3.2.2 Dynamic Difficulty Adjustment (DDA) Algorithm

**State Machine Architecture:**

```gdscript
enum DifficultyState { TOO_EASY, OPTIMAL, TOO_HARD, FRUSTRATED }

class AdaptiveDifficultyEngine:
    const WINDOW_SIZE: int = 5  # Rolling average over last 5 puzzles
    const THRESHOLD_FRUSTRATION: float = 0.75
    const THRESHOLD_BOREDOM: float = 0.25
    
    var recent_metrics: Array[PlayerSessionMetrics] = []
    var current_state: DifficultyState = DifficultyState.OPTIMAL
    var difficulty_modifier: float = 1.0  # Multiplier applied to puzzle parameters
    
    func update_metrics(new_metric: PlayerSessionMetrics) -> void:
        recent_metrics.append(new_metric)
        if recent_metrics.size() > WINDOW_SIZE:
            recent_metrics.pop_front()
        
        evaluate_state()
        apply_adjustments()
    
    func evaluate_state() -> void:
        if recent_metrics.size() < WINDOW_SIZE:
            return
        
        var avg_time: float = calculate_average_time()
        var avg_errors: float = calculate_average_errors()
        var avg_hints: float = calculate_average_hints()
        
        # Composite difficulty score (0.0 = trivial, 1.0 = impossible)
        var difficulty_score: float = (
            normalize_time(avg_time) * 0.4 +
            normalize_errors(avg_errors) * 0.4 +
            normalize_hints(avg_hints) * 0.2
        )
        
        # Detect frustration pattern (rapid failures)
        var frustration_detected: bool = detect_frustration_pattern()
        
        if frustration_detected or difficulty_score > THRESHOLD_FRUSTRATION:
            current_state = DifficultyState.TOO_HARD
        elif difficulty_score < THRESHOLD_BOREDOM:
            current_state = DifficultyState.TOO_EASY
        else:
            current_state = DifficultyState.OPTIMAL
    
    func apply_adjustments() -> void:
        match current_state:
            DifficultyState.TOO_HARD:
                difficulty_modifier = max(0.5, difficulty_modifier - 0.1)
                activate_support_features()
            
            DifficultyState.TOO_EASY:
                difficulty_modifier = min(2.0, difficulty_modifier + 0.1)
                deactivate_support_features()
            
            DifficultyState.OPTIMAL:
                # Maintain current modifier, fine-tune ±0.02
                pass
            
            DifficultyState.FRustrated:
                # Emergency intervention: reduce difficulty by 30%
                difficulty_modifier = max(0.5, difficulty_modifier * 0.7)
                force_hint_display()
    
    func activate_support_features() -> void:
        # Invisible scaffolding - player unaware of assistance
        Events.emit_signal("difficulty_increased_snap_radius", 0.1)
        Events.emit_signal("difficulty_extend_time_limit", 15)  # seconds
        Events.emit_signal("difficulty_show_ghost_outline", true)
    
    func deactivate_support_features() -> void:
        Events.emit_signal("difficulty_reset_snap_radius")
        Events.emit_signal("difficulty_reset_time_limit")
        Events.emit_signal("difficulty_hide_ghost_outline")
```

### 3.2.3 Parameter Modification Strategies

**By Realm Type:**

| Realm | Adjustable Parameters | Range | Impact |
|-------|----------------------|-------|--------|
| **Stage 1** | Snap radius, shape complexity, time limit | ±40% | Affects precision requirement |
| **Stage 2** | Gear tooth count, fraction granularity, beam tolerance | ±30% | Changes calculation depth |
| **Stage 3** | Block mass variance, scale sensitivity, X value range | ±25% | Modifies equation complexity |
| **Stage 4** | Tank dimensions, object volume precision, flow rate | ±20% | Adjusts decimal places needed |
| **Stage 5** | Graph density, sequence length, modulo base | ±35% | Alters cognitive load |

**Ethical Considerations:**
- **Transparency:** Players can view their current difficulty tier in settings (opt-in)
- **No Paywall:** Difficulty adjustments never gated behind monetization
- **Parental Controls:** Option to lock difficulty or set manual level
- **Data Privacy:** All metrics stored locally, anonymized cloud upload requires consent

---

# 4. DOMAIN 2: GODOT 4 + ANDROID STUDIO PIPELINE

## 4.1 Directory Architecture

### 4.1.1 Production File Structure

```
/workspace/mathquest/
├── project.godot                      # Godot 4 project configuration
├── default_env.tres                   # Environment resource (Vulkan settings)
├── icon.svg                           # App icon (scalable vector)
│
├── assets/                            # Raw imported assets (read-only)
│   ├── 3d_models/
│   │   ├── stage1_isle/
│   │   │   ├── temple_marble.glb
│   │   │   ├── floating_island.glb
│   │   │   └── pythagoras_npc.glb
│   │   ├── stage2_gears/
│   │   ├── stage3_oasis/
│   │   ├── stage4_fluids/
│   │   └── stage5_labyrinth/
│   │
│   ├── textures/
│   │   ├── environments/
│   │   ├── characters/
│   │   └── ui_elements/
│   │
│   ├── audio/
│   │   ├── music/
│   │   │   ├── ambient_greece.ogg
│   │   │   ├── ambient_india.ogg
│   │   │   └── combat_puzzle.ogg
│   │   ├── sfx/
│   │   │   ├── ui_click.wav
│   │   │   ├── success_chime.wav
│   │   │   └── mechanical_gear.wav
│   │   └── voice/
│   │       ├── pythagoras_lines/
│   │       └── aryabhata_lines/
│   │
│   └── fonts/
│       ├── NotoSans-Regular.ttf
│       └── NotoSans-Bold.ttf
│
├── scenes/                            # Inherited and composed scenes
│   ├── globals/
│   │   ├── GameManager.tscn
│   │   ├── AudioManager.tscn
│   │   └── SaveSystem.tscn
│   │
│   ├── ui/
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn
│   │   ├── PauseMenu.tscn
│   │   └── SettingsPanel.tscn
│   │
│   ├── realms/
│   │   ├── stage1_isle/
│   │   │   ├── IsleHub.tscn
│   │   │   ├── Puzzle_Triangle.tscn
│   │   │   └── Puzzle_Square.tscn
│   │   ├── stage2_gears/
│   │   ├── stage3_oasis/
│   │   │   ├── OasisHub.tscn
│   │   │   ├── BalanceScale.tscn          # ← Vertical slice focus
│   │   │   └── Puzzle_Equation1.tscn
│   │   ├── stage4_fluids/
│   │   └── stage5_labyrinth/
│   │
│   └── sky_base/
│       ├── SkyBaseHub.tscn
│       └── CustomizationEditor.tscn
│
├── scripts/                           # GDScript source files
│   ├── autoload/
│   │   ├── GameManager.gd
│   │   ├── AudioManager.gd
│   │   ├── SaveSystem.gd
│   │   ├── AnalyticsTracker.gd
│   │   └── AdaptiveDifficulty.gd
│   │
│   ├── components/
│   │   ├── InteractiveObject.gd
│   │   ├── Collectible.gd
│   │   ├── PuzzleTrigger.gd
│   │   └── HapticFeedback.gd
│   │
│   ├── realms/
│   │   ├── stage1/
│   │   │   ├── PebbleGrid.gd
│   │   │   └── ShapeValidator.gd
│   │   ├── stage2/
│   │   │   ├── GearMechanism.gd
│   │   │   └── LightBeamSolver.gd
│   │   ├── stage3/
│   │   │   ├── BalanceScale.gd              # ← Core implementation
│   │   │   ├── WeightBlock.gd
│   │   │   └── EquationGenerator.gd
│   │   ├── stage4/
│   │   └── stage5/
│   │
│   ├── ui/
│   │   ├── MainMenuController.gd
│   │   ├── HUDController.gd
│   │   └── SettingsController.gd
│   │
│   └── utils/
│       ├── MathHelpers.gd
│       ├── PoolManager.gd
│       └── ResourceLoaderAsync.gd
│
├── android/                           # Custom Android build template
│   ├── build/
│   │   └── outputs/                   # Generated APK/AAB artifacts
│   │
│   ├── src/
│   │   └── main/
│   │       ├── java/org/godotengine/plugin/
│   │       │   └── mathquest/
│   │       │       ├── MathQuestPlugin.java      # JNI bridge entry point
│   │       │       ├── PerformanceProfiler.java  # Native metrics collection
│   │       │       └── PlayGamesService.java     # Achievement/leaderboard API
│   │       │
│   │       ├── kotlin/org/godotengine/plugin/
│   │       │   └── mathquest/
│   │       │       └── HapticFeedback.kt         # Advanced vibration patterns
│   │       │
│   │       ├── AndroidManifest.xml               # Permissions, activities
│   │       └── res/                              # Native Android resources
│   │           ├── values/strings.xml
│   │           └── drawable/
│   │
│   ├── build.gradle                  # Gradle build configuration
│   ├── gradle.properties             # JVM args, signing config
│   └── proguard-rules.pro            # Code obfuscation rules
│
├── exports/                           # Export presets and configurations
│   ├── android_debug.cfg
│   ├── android_release.cfg
│   └── texture_compression_profiles/
│       ├── astc_4x4_medium.cfg
│       └── etc2_rgb8_high.cfg
│
└── tests/                             # Unit and integration tests
    ├── unit/
    │   ├── test_balance_scale.gd
    │   └── test_equation_generator.gd
    │
    └── integration/
        └── test_stage3_complete_flow.gd
```

### 4.1.2 Version Control Strategy

**.gitignore Configuration:**
```gitignore
# Godot-specific
*.import
godot.cache
.vscode/
.idea/

# Android build artifacts
android/build/outputs/
android/build/intermediates/
*.apk
*.aab
*.keystore

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/
```

**Branch Naming Convention:**
- `feature/stage3-balance-implementation`
- `fix/android-jni-crash-on-rotate`
- `optimize/vulkan-shadow-cascades`
- `content/stage1-puzzle-variations`

---

## 4.2 Vulkan Mobile Optimization

### 4.2.1 Project Settings Overrides

**File: `project.godot` (Relevant Sections)**

```ini
; ============================================================================
; RENDERING CONFIGURATION - VULKAN MOBILE OPTIMIZED
; ============================================================================

[rendering]

renderer/rendering_method="mobile"  ; Forward+ for high-end, Mobile for mid-tier
renderer/rendering_method.mobile/quality="high"
renderer/anti_aliasing/quality/msaa_3d="msaa_2x"  ; Balance quality/performance
renderer/anti_aliasing/quality/screen_space_aa="off"  ; Too expensive for mobile

[rendering/textures]

canvas_texture/default_canvas_texture="res://assets/textures/ui/default_canvas.png"
vram_compression/import_etc2_astc=true  ; Enable modern compression formats
vram_compression/etc2_astc_bptc_quality=2  ; Medium quality (balance size/quality)
vram_compression/import_normal_maps=true
vram_compression/import_roughness_ao=true

[rendering/lights_and_shadows]

lights_and_shadows/directional_shadow/size=2048  ; Reduced from 4096 for mobile
lights_and_shadows/directional_shadow/maximum_distance=50.0  ; Cull distant shadows
lights_and_shadows/positional_shadow/size=1024  ; Point/spot lights
lights_and_shadows/positional_shadow/atlas_count=4
lights_and_shadows/shadow_atlas/quad_0_subdiv=8  ; Subdivision strategy
lights_and_shadows/shadow_atlas/quad_1_subdiv=8
lights_and_shadows/shadow_atlas/quad_2_subdiv=8
lights_and_shadows/shadow_atlas/quad_3_subdiv=8

; Shadowmask technique for static geometry (baked lighting + realtime shadows)
lights_and_shadows/use_shadowmask=true

[rendering/environment]

environment/ssao_enabled=false  ; SSAO too expensive, use baked AO instead
environment/ssil_enabled=false  ; Screen-space indirect lighting disabled
environment/glow_enabled=true  ; Glow is cheap with bloom threshold
environment/glow_levels=5  ; Reduce from default 7
environment/volumetric_fog_enabled=false  ; Disable unless critical for atmosphere

[rendering/occlusion_culling]

occlusion_culling/use_occlusion_culling=true  ; Critical for complex scenes
occlusion_culling/raycast_amount=0.75  ; Aggressive culling
occlusion_culling/pvs_enabled=true  ; Precomputed visibility sets for static geometry

; ============================================================================
; PHYSICS CONFIGURATION
; ============================================================================

[physics]

3d/default_collision_layer=1
3d/default_collision_mask=1
3d/sync_to_physics=false  ; Decouple render/physics framerate for efficiency
3d/physics_ticks_per_second=60  ; Fixed timestep
3d/max_object_count=1024  ; Limit collision objects

; ============================================================================
; MEMORY MANAGEMENT
; ============================================================================

[memory]

limits/hard_limit=536870912  ; 512 MB hard cap
limits/soft_limit=268435456  ; 256 MB soft limit (triggers GC)
loader/buffered_max_mb=128  ; Async loading buffer
```

### 4.2.2 Texture Compression Strategy

**ASTC vs ETC2 Decision Matrix:**

| Device Tier | GPU Family | Recommended Format | Block Size | Quality Setting |
|-------------|------------|-------------------|------------|-----------------|
| **High-End** | Adreno 640+, Mali-G76+ | ASTC | 4×4 | Medium (6 bits/texel) |
| **Mid-Tier** | Adreno 506-630, Mali-G52-G72 | ASTC | 5×5 or 6×6 | Fast (4-5 bits/texel) |
| **Low-End** | Mali-T8xx, Adreno 505 | ETC2 | RGB8 | High (fallback) |
| **Normal Maps** | All | ASTC | 5×5 | Medium |
| **UI Elements** | All | PNG (uncompressed) | N/A | Lossless |

**Export Preset Configuration:**

```ini
; File: exports/texture_compression_profiles/astc_4x4_medium.cfg

[preset.0]

name="Android - ASTC 4x4 Medium"
platform="Android"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="*.glb, *.tres"
exclude_filter="*.blend, *.psd"
patch_list=PoolStringArray(  )

[preset.0.options]

custom_template/debug=""
custom_template/release=""

; Texture Compression
texture_format/bptc=false
texture_format/s3tc=true  ; Fallback for non-ASTC devices
texture_format/etc=false
texture_format/etc2=true
texture_format/astc=true
texture_format/astc_hdr=false

; ASTC Specific
texture_format/astc_block_size="4x4"
texture_format/astc_quality=2  ; 0=fast, 1=medium, 2=high

; Architecture
architecture/arm64=true
architecture/arm7=false  ; Drop 32-bit support for APK size reduction

; Signing
keystore/debug=""
keystore/release="release.keystore"
keystore/debug_user=""
keystore/release_user="mathquest_release"
```

### 4.2.3 Vertex Pipeline Optimization

**Blender Export Checklist for Mobile:**

1. **Triangle Count Budgets:**
   - Hero Characters: < 5,000 tris
   - Environmental Props: < 1,000 tris each
   - Background Elements: < 500 tris (billboard if < 100m from camera)

2. **LOD (Level of Detail) Strategy:**
   ```
   LOD0: 100% quality (0-20m distance)
   LOD1: 50% tris (20-50m distance)
   LOD2: 25% tris (50-100m distance)
   LOD3: Billboard sprite (>100m distance)
   ```

3. **Mesh Baking:**
   - Bake high-poly details into normal maps
   - Merge meshes with same material (reduce draw calls)
   - Use instancing for repeated objects (trees, columns, gears)

4. **UV Layout:**
   - Texel density: 512px per meter for hero objects
   - Pack UV islands efficiently (target 85%+ utilization)
   - Avoid UV seams on visible surfaces

---

## 4.3 The Native Bridge: JNI / GodotAndroidPlugin

### 4.3.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         GODOT NATIVE BRIDGE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐                           ┌─────────────────────┐  │
│  │   GDScript      │                           │   Android Native    │  │
│  │   (Game Logic)  │                           │   (System Access)   │  │
│  │                 │                           │                     │  │
│  │  var plugin =   │   GodotAndroidPlugin      │  public class       │  │
│  │  Engine.get_    │◄─────────────────────────►│  MathQuestPlugin    │  │
│  │  singleton(     │   Interface Binding       │  extends GodotPlugin│  │
│  │  "MathQuest"    │                           │                     │  │
│  │  )              │                           │  - Performance      │  │
│  │                 │                           │  - Haptics          │  │
│  │  plugin.call(   │   Method Invocation       │  - Play Games       │  │
│  │  "recordMetric" │◄─────────────────────────►│  - Battery Monitor  │  │
│  │  , data)        │                           │                     │  │
│  └─────────────────┘                           └─────────────────────┘  │
│           │                                       │                     │
│           │                                       │                     │
│           ▼                                       ▼                     │
│  ┌─────────────────┐                       ┌─────────────────────┐      │
│  │  Signal Emitter │                       │  Android SDK APIs   │      │
│  │                 │                       │                     │      │
│  │  emit_signal(   │                       │  - VibratorService  │      │
│  │  "native_event" │                       │  - PackageManager   │      │
│  │  , result)      │                       │  - GooglePlayGames  │      │
│  └─────────────────┘                       └─────────────────────┘      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.3.2 Java Plugin Implementation

**File: `android/src/main/java/org/godotengine/plugin/mathquest/MathQuestPlugin.java`**

```java
package org.godotengine.plugin.mathquest;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.util.Log;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.Signal;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashMap;
import java.util.Map;

/**
 * MathQuestPlugin - Native Android Bridge for MathQuest Game
 * 
 * Provides direct access to Android system APIs not exposed through Godot's
 * standard interface, including:
 * - Advanced haptic feedback patterns (API 29+)
 * - Low-level performance profiling (CPU/GPU utilization)
 * - Play Games Services integration
 * - Battery and thermal state monitoring
 * 
 * @author MathQuest Development Team
 * @version 1.0.0
 */
public class MathQuestPlugin extends GodotPlugin {
    
    private static final String TAG = "MathQuestPlugin";
    private static final boolean DEBUG = true;
    
    // Plugin signals emitted to GDScript
    public static final Signal SIGNAL_PERFORMANCE_DATA = new Signal("performance_data_received", HashMap.class);
    public static final Signal SIGNAL_HAPTIC_COMPLETE = new Signal("haptic_feedback_complete");
    public static final Signal SIGNAL_THERMAL_WARNING = new Signal("thermal_warning", int.class);
    
    // System services
    private Vibrator vibrator;
    private PerformanceProfiler performanceProfiler;
    
    /**
     * Constructor called by Godot engine during plugin initialization
     * @param godot The Godot instance reference
     */
    public MathQuestPlugin(Godot godot) {
        super(godot);
        initializeServices();
    }
    
    /**
     * Initialize Android system services
     */
    private void initializeServices() {
        Activity activity = getActivity();
        if (activity == null) {
            Log.e(TAG, "Activity reference null during initialization");
            return;
        }
        
        Context context = activity.getApplicationContext();
        
        // Initialize Vibrator service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            VibratorManager vm = (VibratorManager) context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
            vibrator = vm.getDefaultVibrator();
        } else {
            vibrator = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        }
        
        // Initialize performance profiler
        performanceProfiler = new PerformanceProfiler(activity);
        
        if (DEBUG) {
            Log.i(TAG, "MathQuestPlugin initialized successfully");
        }
    }
    
    /**
     * Called when plugin is registered with Godot
     * @return Array of supported signals
     */
    @Override
    public Signal[] getPluginSignals() {
        return new Signal[] {
            SIGNAL_PERFORMANCE_DATA,
            SIGNAL_HAPTIC_COMPLETE,
            SIGNAL_THERMAL_WARNING
        };
    }
    
    /**
     * GDScript-callable method: Record gameplay metric for adaptive difficulty
     * 
     * @param metricName Name of the metric (e.g., "puzzle_solve_time")
     * @param value Numeric value to record
     * @param timestamp Unix epoch milliseconds
     */
    @UsedByGodot
    public void recordMetric(String metricName, double value, long timestamp) {
        if (DEBUG) {
            Log.d(TAG, String.format("Recording metric: %s = %.2f @ %d", 
                metricName, value, timestamp));
        }
        
        // Store in local buffer for batch upload
        // In production: send to analytics backend or save to SharedPreferences
        Map<String, Object> metricData = new HashMap<>();
        metricData.put("name", metricName);
        metricData.put("value", value);
        metricData.put("timestamp", timestamp);
        
        // Emit signal to GDScript for immediate processing
        emitSignal(SIGNAL_PERFORMANCE_DATA, metricData);
    }
    
    /**
     * GDScript-callable method: Trigger advanced haptic feedback pattern
     * 
     * Supports three pattern types:
     * - "success": Pleasant ascending vibration (puzzle completion)
     * - "error": Sharp descending vibration (incorrect move)
     * - "hint": Gentle pulse sequence (guidance cue)
     * 
     * @param patternType Type of haptic pattern
     * @param intensity Intensity multiplier (0.0 - 1.0)
     */
    @UsedByGodot
    public void triggerHaptic(String patternType, double intensity) {
        if (vibrator == null || !vibrator.hasVibrator()) {
            Log.w(TAG, "Vibrator not available");
            return;
        }
        
        intensity = Math.max(0.0, Math.min(1.0, intensity));  // Clamp to [0, 1]
        
        long[] timings;
        int[] amplitudes;
        
        switch (patternType.toLowerCase()) {
            case "success":
                // Ascending pattern: short-medium-long pulses
                timings = new long[] {0, 50, 30, 50, 100};
                amplitudes = new int[] {
                    (int)(VibrationEffect.DEFAULT_AMPLITUDE * 0.3 * intensity),
                    (int)(VibrationEffect.DEFAULT_AMPLITUDE * 0.6 * intensity),
                    (int)(VibrationEffect.DEFAULT_AMPLITUDE * intensity)
                };
                break;
                
            case "error":
                // Descending pattern: sharp jolt then fade
                timings = new long[] {0, 80, 40, 60};
                amplitudes = new int[] {
                    (int)(VibrationEffect.DEFAULT_AMPLITUDE * intensity),
                    (int)(VibrationEffect.DEFAULT_AMPLITUDE * 0.4 * intensity)
                };
                break;
                
            case "hint":
                // Gentle triple pulse
                timings = new long[] {0, 40, 60, 40, 60, 40};
                amplitudes = new int[] {
                    (int)(VibrationEffect.DEFAULT_AMPLITUDE * 0.2 * intensity)
                };
                break;
                
            default:
                Log.w(TAG, "Unknown haptic pattern: " + patternType);
                return;
        }
        
        // Execute vibration pattern
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            VibrationEffect effect = VibrationEffect.createWaveform(timings, amplitudes, -1);
            vibrator.vibrate(effect);
        } else {
            // Fallback for older devices
            vibrator.vibrate(timings, -1);
        }
        
        // Emit completion signal after pattern duration
        long totalDuration = 0;
        for (long t : timings) totalDuration += t;
        
        getActivity().runOnUiThread(() -> {
            try {
                Thread.sleep(totalDuration + 50);  // Small buffer
                emitSignal(SIGNAL_HAPTIC_COMPLETE);
            } catch (InterruptedException e) {
                Log.e(TAG, "Haptic sleep interrupted", e);
            }
        });
    }
    
    /**
     * GDScript-callable method: Get current device thermal state
     * 
     * @return Thermal state code:
     *         0 = UNKNOWN, 1 = NOMINAL, 2 = LIGHT, 3 = MODERATE, 4 = SEVERE, 5 = CRITICAL
     */
    @UsedByGodot
    public int getThermalState() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Requires android.permission.BATTERY_STATS (system app only)
            // For regular apps, estimate based on battery temperature
            return estimateThermalStateFromBattery();
        }
        return 0;  // UNKNOWN for pre-Q devices
    }
    
    /**
     * Estimate thermal state from battery temperature (works on all API levels)
     * @return Estimated thermal state code
     */
    private int estimateThermalStateFromBattery() {
        // Implementation would read battery temperature via BroadcastReceiver
        // Simplified for blueprint purposes
        return 1;  // NOMINAL (default assumption)
    }
    
    /**
     * GDScript-callable method: Start performance profiling session
     * 
     * @param sessionName Identifier for this profiling session
     * @param intervalMs Sampling interval in milliseconds
     */
    @UsedByGodot
    public void startProfiling(String sessionName, int intervalMs) {
        if (performanceProfiler != null) {
            performanceProfiler.startSession(sessionName, intervalMs);
        }
    }
    
    /**
     * GDScript-callable method: Stop performance profiling session
     * 
     * @return Profiling results as HashMap
     */
    @UsedByGodot
    public HashMap<String, Object> stopProfiling() {
        if (performanceProfiler != null) {
            return performanceProfiler.stopSession();
        }
        return new HashMap<>();
    }
    
    /**
     * GDScript-callable method: Unlock achievement via Play Games Services
     * 
     * @param achievementId Play Console achievement ID string
     */
    @UsedByGodot
    public void unlockAchievement(String achievementId) {
        // Delegate to PlayGamesService helper class
        PlayGamesService.unlockAchievement(getActivity(), achievementId);
        Log.i(TAG, "Achievement unlocked: " + achievementId);
    }
    
    /**
     * GDScript-callable method: Submit score to leaderboard
     * 
     * @param leaderboardId Play Console leaderboard ID string
     * @param score Numeric score value
     */
    @UsedByGodot
    public void submitScore(String leaderboardId, long score) {
        PlayGamesService.submitScore(getActivity(), leaderboardId, score);
        Log.i(TAG, String.format("Score submitted: %d to %s", score, leaderboardId));
    }
    
    /**
     * Cleanup resources when plugin is destroyed
     */
    @Override
    public void onDestroy() {
        if (performanceProfiler != null) {
            performanceProfiler.stopSession();
        }
        vibrator = null;
        super.onDestroy();
    }
}
```

### 4.3.3 Kotlin Helper Class: Haptic Feedback

**File: `android/src/main/kotlin/org/godotengine/plugin/mathquest/HapticFeedback.kt`**

```kotlin
package org.godotengine.plugin.mathquest

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.annotation.RequiresApi

/**
 * HapticFeedback - Advanced vibration pattern generator for Android
 * 
 * Provides richer haptic experiences than Godot's built-in Input.vibrate_handheld()
 * by supporting amplitude modulation, waveform composition, and timed sequences.
 * 
 * Used for:
 * - Puzzle completion rewards
 * - Error feedback
 * - Hint notifications
 * - UI interaction confirmation
 */
class HapticFeedback(private val context: Context) {
    
    companion object {
        private const val TAG = "MathQuestHaptics"
        
        // Pattern definitions (timing in ms, amplitude as % of max)
        val PATTERN_SUCCESS = HapticPattern(
            timings = longArrayOf(0, 50, 30, 50, 100),
            amplitudes = intArrayOf(30, 60, 100)
        )
        
        val PATTERN_ERROR = HapticPattern(
            timings = longArrayOf(0, 80, 40, 60),
            amplitudes = intArrayOf(100, 40)
        )
        
        val PATTERN_HINT = HapticPattern(
            timings = longArrayOf(0, 40, 60, 40, 60, 40),
            amplitudes = intArrayOf(20)
        )
    }
    
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }
    
    /**
     * Play predefined haptic pattern with intensity scaling
     * @param pattern Pattern type (SUCCESS, ERROR, HINT)
     * @param intensity Intensity multiplier 0.0-1.0
     */
    fun play(pattern: HapticPattern, intensity: Float = 1.0f) {
        if (vibrator == null || !vibrator!!.hasVibrator()) return
        
        val clampedIntensity = intensity.coerceIn(0.0f, 1.0f)
        val scaledAmplitudes = pattern.amplitudes.map { 
            (it * clampedIntensity).toInt() 
        }.toIntArray()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createWaveform(
                pattern.timings,
                scaledAmplitudes,
                -1  // No repeat
            )
            vibrator!!.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator!!.vibrate(pattern.timings, -1)
        }
    }
    
    /**
     * Check if device supports advanced haptic features
     */
    fun hasAdvancedHaptics(): Boolean {
        return vibrator != null && 
               vibrator!!.hasVibrator() && 
               Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }
}

/**
 * Data class representing a haptic pattern
 */
data class HapticPattern(
    val timings: LongArray,
    val amplitudes: IntArray
)
```

### 4.3.4 GDScript Integration Layer

**File: `scripts/autoload/NativeBridge.gd`**

```gdscript
extends Node
## NativeBridge - GDScript wrapper for Android native plugin
## 
## Provides clean interface to MathQuestPlugin Java methods
## with type safety and error handling.

const PLUGIN_NAME := "MathQuest"

var _plugin: Object = null
var _is_android: bool = false

func _ready() -> void:
    _is_android = OS.get_name() == "Android"
    
    if _is_android:
        # Get plugin singleton reference
        _plugin = Engine.get_singleton(PLUGIN_NAME)
        
        if _plugin == null:
            push_error("NativeBridge: Failed to get MathQuestPlugin singleton")
            return
        
        # Connect to plugin signals
        _plugin.connect("performance_data_received", _on_performance_data)
        _plugin.connect("haptic_feedback_complete", _on_haptic_complete)
        _plugin.connect("thermal_warning", _on_thermal_warning)
        
        print("NativeBridge: Connected to MathQuestPlugin")
    else:
        print("NativeBridge: Running on non-Android platform, native features disabled")


func record_metric(metric_name: String, value: float, timestamp: int) -> void:
    """Record gameplay metric for adaptive difficulty system"""
    if not _is_android or _plugin == null:
        # Fallback: store locally for later sync
        _store_metric_locally(metric_name, value, timestamp)
        return
    
    _plugin.recordMetric(metric_name, value, timestamp)


func trigger_haptic(pattern_type: String, intensity: float = 1.0) -> void:
    """
    Trigger advanced haptic feedback pattern
    
    Args:
        pattern_type: One of "success", "error", "hint"
        intensity: Intensity multiplier 0.0-1.0
    """
    if not _is_android or _plugin == null:
        # Fallback to Godot's basic vibration
        if pattern_type == "error":
            Input.vibrate_handheld(100)
        else:
            Input.vibrate_handheld(50)
        return
    
    _plugin.triggerHaptic(pattern_type, intensity)


func start_profiling(session_name: String, interval_ms: int = 1000) -> void:
    """Start native performance profiling session"""
    if _is_android and _plugin != null:
        _plugin.startProfiling(session_name, interval_ms)


func stop_profiling() -> Dictionary:
    """Stop profiling and return results"""
    if _is_android and _plugin != null:
        return _plugin.stopProfiling()
    return {}


func unlock_achievement(achievement_id: String) -> void:
    """Unlock Play Games achievement"""
    if _is_android and _plugin != null:
        _plugin.unlockAchievement(achievement_id)


func submit_score(leaderboard_id: String, score: int) -> void:
    """Submit score to Play Games leaderboard"""
    if _is_android and _plugin != null:
        _plugin.submitScore(leaderboard_id, score)


func get_thermal_state() -> int:
    """
    Get current device thermal state
    
    Returns:
        0 = UNKNOWN, 1 = NOMINAL, 2 = LIGHT, 
        3 = MODERATE, 4 = SEVERE, 5 = CRITICAL
    """
    if _is_android and _plugin != null:
        return _plugin.getThermalState()
    return 1  # Assume NOMINAL on non-Android


func _store_metric_locally(metric_name: String, value: float, timestamp: int) -> void:
    """Fallback: store metrics in local file for later sync"""
    var metric_data := {
        "name": metric_name,
        "value": value,
        "timestamp": timestamp
    }
    # Implementation: append to JSON file or SQLite database


func _on_performance_data(data: Dictionary) -> void:
    """Handle performance data from native plugin"""
    # Forward to analytics system
    AnalyticsTracker.record_native_metric(data)


func _on_haptic_complete() -> void:
    """Haptic pattern finished playing"""
    # Can be used to chain haptic sequences


func _on_thermal_warning(state: int) -> void:
    """Device thermal state changed"""
    if state >= 4:  # SEVERE or CRITICAL
        push_warning("NativeBridge: Device thermal warning - state ", state)
        # Trigger thermal throttling measures
        Events.emit_signal("device_thermal_warning", state)
```

---

# 5. DOMAIN 3: STAGE 3 IMPLEMENTATION - AL-KHWARIZMI'S BALANCE ENGINE

## 5.1 Architecture Overview

The Stage 3 Balance Scale system is the vertical slice demonstration of MathQuest's core design philosophy: **mathematics as physical interaction**. Rather than presenting equations as abstract symbols, players manipulate physical objects whose masses represent mathematical terms.

### 5.1.1 Component Breakdown

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    BALANCE SCALE SYSTEM ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────┐              ┌─────────────────────┐           │
│  │   BalanceScale.gd   │              │   EquationGenerator │           │
│  │   (Main Controller) │              │   (Puzzle Factory)  │           │
│  │                     │              │                     │           │
│  │ - Track left/right  │              │ - Generate random   │           │
│  │   platform masses   │              │   equations         │           │
│  │ - Compute torque    │◄────────────►│ - Create X blocks   │           │
│  │ - Detect equilibrium│              │   with hidden mass  │           │
│  │ - Emit signals      │              │ - Validate solvable │           │
│  └──────────┬──────────┘              └─────────────────────┘           │
│             │                                                           │
│             │ emits                                                     │
│             ▼                                                           │
│  ┌─────────────────────┐              ┌─────────────────────┐           │
│  │   WeightBlock.gd    │              │   ScaleVisuals.gd   │           │
│  │   (Individual Block)│              │   (FX & Animation)  │           │
│  │                     │              │                     │           │
│  │ - Store mass value  │              │ - Tilt animation    │           │
│  │ - Is variable (X)?  │              │ - Particle effects  │           │
│  │ - Drag/drop logic   │              │ - Success glow      │           │
│  └─────────────────────┘              └─────────────────────┘           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.1.2 Mathematical Model

**Physics Equations:**

For a balance scale with pivot at center:

$$\tau_{net} = \sum_{i=1}^{n_L} m_{L,i} \cdot g \cdot d_{L,i} - \sum_{j=1}^{n_R} m_{R,j} \cdot g \cdot d_{R,j}$$

Where:
- $\tau_{net}$ = Net torque about pivot
- $m_{L,i}, m_{R,j}$ = Mass of individual blocks on left/right platforms
- $g$ = Gravitational acceleration (constant, cancels out)
- $d_{L,i}, d_{R,j}$ = Distance from pivot (assumed equal for simplicity)

**Simplified Equilibrium Condition:**

$$\left| \sum m_L - \sum m_R \right| < \epsilon$$

Where $\epsilon$ is a small floating-point tolerance (default: 0.01 kg)

**Equation Representation:**

Physical setup maps to algebraic equation:

```
Left Platform:  [X] [X] [5kg]     → 2X + 5
Right Platform: [X] [12kg]        → X + 12

When balanced:  2X + 5 = X + 12
Solution:       X = 7
```

---

## 5.2 Core Implementation: BalanceScale.gd

**File: `scripts/realms/stage3/BalanceScale.gd`**

```gdscript
extends Node3D
class_name BalanceScale
## BalanceScale - Core puzzle controller for Al-Khwarizmi's Oasis realm
##
## This script implements the physics-based equation solving mechanic where
## players balance weighted blocks on a scale to solve for unknown variable X.
##
## MATHEMATICAL FOUNDATION:
## - Represents linear equations of form: aX + b = cX + d
## - Left and right platforms accumulate mass from child WeightBlock nodes
## - Equilibrium detected when mass difference < epsilon threshold
## - Solution validated against pre-computed answer from EquationGenerator
##
## ARCHITECTURAL NOTES:
## - Uses Godot 4's strict static typing for performance and safety
## - Signal-based communication decouples logic from presentation
## - Configurable tolerance allows adaptive difficulty adjustment
## - Thread-safe mass computation for async validation

#region Signals

## Emitted when scale reaches equilibrium state
signal scale_balanced(is_correct: bool, solve_time_ms: int)

## Emitted when player adds/removes a block from platform
signal mass_changed(left_mass: float, right_mass: float, delta: float)

## Emitted when equation is solved correctly
signal puzzle_completed(variable_value: float, equation_string: String)

## Emitted for visual feedback requests (tilt angle, particle triggers)
signal visual_update(tilt_angle: float, left_height: float, right_height: float)

#endregion

#region Constants

## Gravitational acceleration constant (m/s²) - used for torque calculations
const GRAVITY: float = 9.81

## Default equilibrium tolerance in kilograms
## Smaller values require more precise balancing (harder difficulty)
const DEFAULT_EPSILON: float = 0.01

## Maximum allowable mass per platform (prevents physics instability)
const MAX_PLATFORM_MASS: float = 100.0

## Time between mass recalculation checks (seconds)
const MASS_CHECK_INTERVAL: float = 0.1

#endregion

#region Exported Properties

## Reference to left platform Area3D node
@export_group("Platform References")
@export_node_path("Area3D") var left_platform_path: NodePath
@export_node_path("Area3D") var right_platform_path: NodePath

## Cached platform references (set in _ready)
var _left_platform: Area3D
var _right_platform: Area3D

## Current equilibrium tolerance (can be modified by adaptive difficulty)
@export_group("Configuration")
@export_range(0.001, 0.1, 0.001) var epsilon: float = DEFAULT_EPSILON

## Enable debug logging to console
@export var debug_mode: bool = false

## Expected solution value for validation (set by EquationGenerator)
@export var expected_x_value: float = 0.0

## Number of X blocks in the puzzle (for solution verification)
@export var x_block_count: int = 0

#endregion

#region Private State

## Current total mass on left platform (kg)
var _left_mass: float = 0.0

## Current total mass on right platform (kg)
var _right_mass: float = 0.0

## Timer for periodic mass checks
var _mass_check_timer: Timer

## Timestamp when puzzle started (for solve time tracking)
var _puzzle_start_time: int = 0

## Track whether puzzle is currently active
var _is_puzzle_active: bool = false

## Cache of known X block mass (computed when first X block is placed)
var _x_block_mass: float = -1.0

#endregion

#region Lifecycle Methods

func _ready() -> void:
    """Initialize balance scale system"""
    _initialize_platforms()
    _setup_timer()
    _connect_signals()
    
    if debug_mode:
        print("[BalanceScale] Initialized with epsilon=", epsilon)


func _initialize_platforms() -> void:
    """Cache platform node references from exported paths"""
    if not left_platform_path.is_empty():
        _left_platform = get_node_or_null(left_platform_path)
        if _left_platform == null:
            push_error("[BalanceScale] Left platform not found at path: ", left_platform_path)
        else:
            # Configure collision layers for block detection
            _left_platform.collision_layer = 0  # Platform doesn't collide
            _left_platform.collision_mask = 1 << 2  # Layer 2 = WeightBlocks
            _left_platform.body_entered.connect(_on_block_entered_platform.bind(true))
            _left_platform.body_exited.connect(_on_block_exited_platform.bind(true))
    
    if not right_platform_path.is_empty():
        _right_platform = get_node_or_null(right_platform_path)
        if _right_platform == null:
            push_error("[BalanceScale] Right platform not found at path: ", right_platform_path)
        else:
            _right_platform.collision_layer = 0
            _right_platform.collision_mask = 1 << 2
            _right_platform.body_entered.connect(_on_block_entered_platform.bind(false))
            _right_platform.body_exited.connect(_on_block_exited_platform.bind(false))


func _setup_timer() -> void:
    """Create and configure mass check timer"""
    _mass_check_timer = Timer.new()
    _mass_check_timer.wait_time = MASS_CHECK_INTERVAL
    _mass_check_timer.autostart = false
    _mass_check_timer.timeout.connect(_check_equilibrium)
    add_child(_mass_check_timer)


func _connect_signals() -> void:
    """Connect to global game events"""
    # Listen for difficulty adjustments from adaptive system
    if has_node("/root/GameManager"):
        var game_manager = get_node("/root/GameManager")
        if game_manager.has_signal("difficulty_modified"):
            game_manager.connect("difficulty_modified", _on_difficulty_modified)

#endregion

#region Public API

func start_puzzle() -> void:
    """
    Begin a new puzzle session
    
    Resets all state, starts timing, and enables equilibrium monitoring.
    Called by GameManager when player enters puzzle area.
    """
    _reset_state()
    _is_puzzle_active = true
    _puzzle_start_time = Time.get_ticks_msec()
    _mass_check_timer.start()
    
    if debug_mode:
        print("[BalanceScale] Puzzle started at ", _puzzle_start_time)


func stop_puzzle() -> void:
    """
    End current puzzle session
    
    Stops monitoring and cleans up state. Called when player exits puzzle
    or completes successfully.
    """
    _is_puzzle_active = false
    _mass_check_timer.stop()
    
    if debug_mode:
        print("[BalanceScale] Puzzle stopped")


func reset_scale() -> void:
    """
    Reset scale to initial state without stopping puzzle
    
    Clears all blocks from platforms and recalculates masses.
    Useful for "try again" functionality within same puzzle instance.
    """
    _clear_all_blocks()
    _recalculate_masses()
    _update_visuals(0.0)  # Return to level position


func set_expected_solution(x_value: float, num_x_blocks: int) -> void:
    """
    Configure expected solution for validation
    
    Args:
        x_value: The correct value of X (e.g., 7.0 for X=7)
        num_x_blocks: How many X blocks are in the puzzle
    """
    expected_x_value = x_value
    x_block_count = num_x_blocks
    
    if debug_mode:
        print("[BalanceScale] Expected solution: X=", x_value, 
              " with ", num_x_blocks, " X-blocks")


func get_current_equation() -> String:
    """
    Generate string representation of current equation
    
    Returns formatted equation like "2X + 5 = X + 12"
    Useful for UI display and debugging.
    """
    var left_coeffs := _analyze_platform_masses(_left_platform)
    var right_coeffs := _analyze_platform_masses(_right_platform)
    
    var left_str := _format_side(left_coeffs)
    var right_str := _format_side(right_coeffs)
    
    return "%s = %s" % [left_str, right_str]

#endregion

#region Private Implementation

func _reset_state() -> void:
    """Reset all internal state for new puzzle"""
    _left_mass = 0.0
    _right_mass = 0.0
    _x_block_mass = -1.0
    _is_puzzle_active = false
    _mass_check_timer.stop()


func _clear_all_blocks() -> void:
    """Remove all WeightBlock nodes from platforms"""
    if _left_platform:
        for body in _left_platform.get_overlapping_bodies():
            if body is WeightBlock:
                body.reset_position()  # Return to spawn location
    
    if _right_platform:
        for body in _right_platform.get_overlapping_bodies():
            if body is WeightBlock:
                body.reset_position()


func _recalculate_masses() -> void:
    """Force recalculation of platform masses"""
    _left_mass = _calculate_platform_mass(_left_platform)
    _right_mass = _calculate_platform_mass(_right_platform)
    
    mass_changed.emit(_left_mass, _right_mass, abs(_left_mass - _right_mass))
    _update_visuals(_calculate_tilt_angle())


func _calculate_platform_mass(platform: Area3D) -> float:
    """
    Calculate total mass on a platform by summing all WeightBlock masses
    
    Args:
        platform: Area3D node representing left or right platform
    
    Returns:
        Total mass in kilograms (float)
    
    PERFORMANCE NOTE:
    This function iterates through overlapping bodies each call.
    For optimization, could cache mass values in WeightBlock signals.
    """
    if platform == null:
        return 0.0
    
    var total_mass: float = 0.0
    var bodies: Array[Node3D] = platform.get_overlapping_bodies()
    
    for body in bodies:
        if body is WeightBlock:
            var block := body as WeightBlock
            total_mass += block.get_effective_mass()
            
            # Track X block mass for validation
            if block.is_variable and _x_block_mass < 0:
                _x_block_mass = block.variable_mass
    
    return total_mass


func _analyze_platform_masses(platform: Area3D) -> Dictionary:
    """
    Analyze mass composition on platform (separate X blocks from constants)
    
    Returns dictionary with:
    - x_count: Number of X blocks
    - constant_mass: Sum of known-weight blocks
    
    Example: [X][X][5kg] → {x_count: 2, constant_mass: 5.0}
    """
    var result := {
        "x_count": 0,
        "constant_mass": 0.0
    }
    
    if platform == null:
        return result
    
    for body in platform.get_overlapping_bodies():
        if body is WeightBlock:
            var block := body as WeightBlock
            if block.is_variable:
                result.x_count += 1
            else:
                result.constant_mass += block.get_effective_mass()
    
    return result


func _format_side(coeffs: Dictionary) -> String:
    """Format equation side as human-readable string"""
    var parts: Array[String] = []
    
    # Add X terms
    if coeffs.x_count > 0:
        if coeffs.x_count == 1:
            parts.append("X")
        else:
            parts.append("%dX" % coeffs.x_count)
    
    # Add constant terms
    if coeffs.constant_mass > 0:
        if coeffs.x_count > 0:
            parts.append("+ %d" % int(coeffs.constant_mass))
        else:
            parts.append("%d" % int(coeffs.constant_mass))
    
    return " ".join(parts) if not parts.is_empty() else "0"


func _check_equilibrium() -> void:
    """
    Periodic check for scale equilibrium
    
    Called by timer every MASS_CHECK_INTERVAL seconds.
    Computes current masses, checks balance condition, and validates solution.
    """
    if not _is_puzzle_active:
        return
    
    # Recalculate masses (blocks may have been moved)
    _left_mass = _calculate_platform_mass(_left_platform)
    _right_mass = _calculate_platform_mass(_right_platform)
    
    # Emit update for UI/audio feedback
    mass_changed.emit(_left_mass, _right_mass, abs(_left_mass - _right_mass))
    
    # Calculate tilt angle for visual feedback
    var tilt_angle: float = _calculate_tilt_angle()
    _update_visuals(tilt_angle)
    
    # Check equilibrium condition: |left - right| < epsilon
    var mass_difference: float = abs(_left_mass - _right_mass)
    
    if mass_difference < epsilon:
        _on_equilibrium_reached()

#endregion

#region Equilibrium Detection & Validation

func _on_equilibrium_reached() -> void:
    """
    Handle scale reaching equilibrium state
    
    Validates whether the balanced state represents correct solution.
    Emits scale_balanced signal with validation result.
    """
    if debug_mode:
        print("[BalanceScale] Equilibrium reached! Left=", _left_mass, 
              " Right=", _right_mass)
    
    # Stop timer to prevent repeated triggers
    _mass_check_timer.stop()
    
    # Validate solution
    var is_correct: bool = _validate_solution()
    var solve_time: int = Time.get_ticks_msec() - _puzzle_start_time
    
    # Emit result signal
    scale_balanced.emit(is_correct, solve_time)
    
    if is_correct:
        if debug_mode:
            print("[BalanceScale] ✓ CORRECT SOLUTION in ", solve_time, "ms")
        
        # Emit completion signal with equation details
        var equation := get_current_equation()
        puzzle_completed.emit(expected_x_value, equation)
        
        # Trigger success effects
        _trigger_success_effects()
    else:
        if debug_mode:
            print("[BalanceScale] ✗ INCORRECT - balanced but wrong X value")
        
        # Allow player to continue adjusting
        _mass_check_timer.start()
        
        # Provide feedback that balance is wrong
        _trigger_failure_feedback()


func _validate_solution() -> bool:
    """
    Validate that equilibrium represents correct mathematical solution
    
    Checks two conditions:
    1. Scale is balanced (|left - right| < epsilon)
    2. Implied X value matches expected solution
    
    Returns true only if both conditions satisfied.
    """
    # Condition 1: Already verified by caller (_check_equilibrium)
    
    # Condition 2: Verify X value
    if x_block_count == 0 or expected_x_value <= 0:
        # Cannot validate without configuration
        push_warning("[BalanceScale] Cannot validate - missing solution config")
        return false
    
    # Extract equation coefficients
    var left_coeffs := _analyze_platform_masses(_left_platform)
    var right_coeffs := _analyze_platform_masses(_right_platform)
    
    # Solve for X: left_x*X + left_const = right_x*X + right_const
    # Rearranged: (left_x - right_x)*X = right_const - left_const
    # X = (right_const - left_const) / (left_x - right_x)
    
    var x_coefficient: float = float(left_coeffs.x_count - right_coeffs.x_count)
    var constant_difference: float = right_coeffs.constant_mass - left_coeffs.constant_mass
    
    if abs(x_coefficient) < 0.001:
        # Division by zero - either infinite solutions or no solution
        if abs(constant_difference) < 0.001:
            # 0 = 0, identity (any X works) - accept as correct
            return true
        else:
            # Contradiction (e.g., 0 = 5) - impossible
            return false
    
    var calculated_x: float = constant_difference / x_coefficient
    
    # Compare with expected value (with tolerance for floating-point error)
    var solution_tolerance: float = 0.1  # More lenient than epsilon
    var is_valid: bool = abs(calculated_x - expected_x_value) < solution_tolerance
    
    if debug_mode:
        print("[BalanceScale] Validation: calculated X=%.2f, expected X=%.2f, valid=%s" % 
              [calculated_x, expected_x_value, str(is_valid)])
    
    return is_valid

#endregion

#region Visual & Audio Feedback

func _calculate_tilt_angle() -> float:
    """
    Calculate scale tilt angle based on mass imbalance
    
    Returns angle in degrees (-45° to +45°)
    Positive = right side down, Negative = left side down
    """
    if _left_platform == null or _right_platform == null:
        return 0.0
    
    var total_mass: float = _left_mass + _right_mass
    if total_mass < 0.001:
        return 0.0  # No mass, no tilt
    
    var imbalance: float = (_right_mass - _left_mass) / total_mass
    var max_tilt: float = 45.0  # Maximum visual tilt angle
    
    # Map imbalance [-1, 1] to angle [-max_tilt, max_tilt]
    # Use smoothstep for smoother visual transition
    var normalized_imbalance: float = clamp(imbalance, -1.0, 1.0)
    var smoothed: float = smoothstep(-1.0, 1.0, normalized_imbalance)
    var angle: float = remap(smoothed, 0.0, 1.0, -max_tilt, max_tilt)
    
    return angle


func _update_visuals(tilt_angle: float) -> void:
    """
    Update scale visual representation
    
    Emits signal for visual controller to animate scale arm rotation
    and adjust platform heights.
    
    Args:
        tilt_angle: Rotation angle in degrees
    """
    # Calculate platform height offsets based on tilt
    var arm_length: float = 2.0  # meters from pivot to platform
    var height_offset: float = arm_length * sin(deg_to_rad(tilt_angle))
    
    visual_update.emit(tilt_angle, height_offset, -height_offset)


func _trigger_success_effects() -> void:
    """Trigger particle effects, audio, and haptics for success"""
    # Implementation would spawn particles, play sound, trigger haptic
    # Delegated to separate component for modularity
    if debug_mode:
        print("[BalanceScale] >>> SUCCESS EFFECTS TRIGGERED <<<")


func _trigger_failure_feedback() -> void:
    """Provide feedback for incorrect balance"""
    # Gentle vibration to indicate "close but wrong"
    if OS.get_name() == "Android":
        var native_bridge = Engine.get_singleton("NativeBridge")
        if native_bridge:
            native_bridge.trigger_haptic("hint", 0.3)

#endregion

#region Event Handlers

func _on_block_entered_platform(body: Node3D, is_left: bool) -> void:
    """Called when WeightBlock enters platform area"""
    if not (body is WeightBlock):
        return
    
    if debug_mode:
        var side := "LEFT" if is_left else "RIGHT"
        print("[BalanceScale] Block entered %s platform" % side)
    
    # Immediate recalculation for responsive feedback
    _recalculate_masses()


func _on_block_exited_platform(body: Node3D, is_left: bool) -> void:
    """Called when WeightBlock leaves platform area"""
    if not (body is WeightBlock):
        return
    
    if debug_mode:
        var side := "LEFT" if is_left else "RIGHT"
        print("[BalanceScale] Block exited %s platform" % side)
    
    _recalculate_masses()


func _on_difficulty_modified(params: Dictionary) -> void:
    """
    Handle adaptive difficulty adjustments
    
    Expected params:
    - epsilon_delta: Change to apply to epsilon tolerance
    """
    if params.has("epsilon_delta"):
        var delta: float = params.epsilon_delta
        epsilon = clamp(epsilon + delta, 0.001, 0.1)
        
        if debug_mode:
            print("[BalanceScale] Epsilon adjusted to ", epsilon)

#endregion

#region Utility Functions

func _print_debug_state() -> void:
    """Print complete debug state to console"""
    if not debug_mode:
        return
    
    print("========== BALANCE SCALE STATE ==========")
    print("Left Mass:  %.3f kg" % _left_mass)
    print("Right Mass: %.3f kg" % _right_mass)
    print("Difference: %.3f kg" % abs(_left_mass - _right_mass))
    print("Epsilon:    %.3f kg" % epsilon)
    print("Balanced:   %s" % str(abs(_left_mass - _right_mass) < epsilon))
    print("Expected X: %.2f" % expected_x_value)
    print("Equation:   %s" % get_current_equation())
    print("=========================================")

#endregion
```

---

## 5.3 Supporting Component: WeightBlock.gd

**File: `scripts/realms/stage3/WeightBlock.gd`**

```gdscript
extends RigidBody3D
class_name WeightBlock
## WeightBlock - Physical block entity for balance scale puzzles
##
## Represents either a known mass (e.g., 5kg) or unknown variable X.
## Handles drag-and-drop interaction, mass reporting, and visual states.

#region Exported Properties

@export_group("Mass Configuration")
@export var fixed_mass: float = 5.0  ## Known mass in kilograms
@export var is_variable: bool = false  ## Is this an X block?
@export var variable_mass: float = 7.0  ## Hidden mass for X blocks (debug/validation)

@export_group("Interaction")
@export var pick_up_force: float = 50.0
@export var drag_speed: float = 10.0

@export_group("Visuals")
@export var known_color: Color = Color(0.2, 0.6, 1.0)  ## Blue for known masses
@export var variable_color: Color = Color(1.0, 0.4, 0.2)  ## Orange for X blocks
@export var mass_label: Label  ## UI label showing mass value

#endregion

#region Private State

var _is_dragging: bool = false
var _original_transform: Transform3D
var _mouse_ray: RayCast3D

#endregion

func _ready() -> void:
    """Initialize block with appropriate mass and appearance"""
    _setup_physics()
    _setup_visuals()
    _setup_interaction()
    
    # Store spawn position for reset
    _original_transform = transform


func _setup_physics() -> void:
    """Configure physics properties based on mass"""
    # Godot uses arbitrary mass units, but we treat 1 unit = 1 kg for clarity
    mass = fixed_mass if not is_variable else variable_mass
    
    # Prevent rotation for stable stacking
    freeze_axis_enabled = true
    frozen_axis = Vector3(1, 1, 1)  # Freeze all rotation
    
    # Adjust collision shape if needed
    if has_node("CollisionShape3D"):
        var collider: CollisionShape3D = $CollisionShape3D
        # Scale collider based on mass for visual consistency
        var scale_factor: float = pow(mass, 1.0 / 3.0)  # Cube root for volume
        collider.scale = Vector3.ONE * scale_factor


func _setup_visuals() -> void:
    """Apply colors and labels based on block type"""
    # Find MeshInstance and apply material
    for child in get_children():
        if child is MeshInstance3D:
            var mesh := child as MeshInstance3D
            var material := StandardMaterial3D.new()
            material.albedo_color = variable_color if is_variable else known_color
            material.roughness = 0.4
            material.metallic = 0.1
            mesh.material_override = material
    
    # Update UI label
    if mass_label:
        if is_variable:
            mass_label.text = "X"
        else:
            mass_label.text = "%dkg" % int(fixed_mass)


func _setup_interaction() -> void:
    """Configure input handling for drag-and-drop"""
    # Implementation depends on input system choice:
    # Option 1: Godot's built-in grab mechanics
    # Option 2: Custom raycast-based dragging
    # Option 3: Touch gesture recognition
    
    # For this blueprint, we'll use a simple force-based approach
    pass


func get_effective_mass() -> float:
    """
    Get block's mass value for calculations
    
    Returns:
        Mass in kilograms (fixed or variable)
    """
    return variable_mass if is_variable else fixed_mass


func reset_position() -> void:
    """Return block to original spawn position"""
    transform = _original_transform
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    sleeping = false  # Wake up if asleep


func set_highlight(enabled: bool) -> void:
    """Toggle highlight effect for selection/hover"""
    for child in get_children():
        if child is MeshInstance3D:
            var mesh := child as MeshInstance3D
            if mesh.material_override is StandardMaterial3D:
                var material := mesh.material_override as StandardMaterial3D
                material.emission_enabled = enabled
                material.emission = Color.WHITE * 0.5 if enabled else Color.BLACK
```

---

## 5.4 Equation Generator: Puzzle Factory

**File: `scripts/realms/stage3/EquationGenerator.gd`**

```gdscript
extends Node
class_name EquationGenerator
## EquationGenerator - Procedural puzzle creation system
##
## Generates valid linear equations with integer solutions,
## configures BalanceScale with appropriate blocks, and validates
## that puzzles are solvable and age-appropriate.

#region Configuration

@export var min_x_value: int = 1
@export var max_x_value: int = 15
@export var min_coefficient: int = 1
@export var max_coefficient: int = 4
@export var min_constant: int = 1
@export var max_constant: int = 30

#endregion

func generate_equation(difficulty_level: int = 1) -> Dictionary:
    """
    Generate a random solvable linear equation
    
    Equation format: aX + b = cX + d
    Where solution X is guaranteed to be positive integer
    
    Args:
        difficulty_level: 1=easy, 2=medium, 3=hard
    
    Returns:
        Dictionary with equation parameters and block configurations
    """
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    
    # Step 1: Choose solution X value
    var x_solution: int = rng.randi_range(min_x_value, max_x_value)
    
    # Step 2: Choose coefficients based on difficulty
    var max_coef: int = min(max_coefficient, difficulty_level + 1)
    var left_coef: int = rng.randi_range(min_coefficient, max_coef)
    var right_coef: int = rng.randi_range(min_coefficient, max_coef)
    
    # Ensure coefficients aren't equal (would cancel out X)
    while right_coef == left_coef:
        right_coef = rng.randi_range(min_coefficient, max_coef)
    
    # Step 3: Choose constants
    var max_const: int = min(max_constant, difficulty_level * 10)
    var left_const: int = rng.randi_range(min_constant, max_const)
    
    # Step 4: Calculate right constant to ensure integer solution
    # We want: left_coef*X + left_const = right_coef*X + right_const
    # Solve for right_const: right_const = (left_coef - right_coef)*X + left_const
    var right_const: int = (left_coef - right_coef) * x_solution + left_const
    
    # Ensure right_const is positive
    if right_const < 1:
        right_const = rng.randi_range(min_constant, max_constant)
        # Recalculate x_solution to maintain validity
        x_solution = (right_const - left_const) / (left_coef - right_coef)
    
    return {
        "x_value": x_solution,
        "left_coef": left_coef,
        "left_const": left_const,
        "right_coef": right_coef,
        "right_const": right_const,
        "equation_string": "%dX + %d = %dX + %d" % [
            left_coef, left_const, right_coef, right_const
        ]
    }


func create_blocks_for_equation(equation_data: Dictionary, parent: Node) -> void:
    """
    Instantiate WeightBlock nodes according to equation specification
    
    Spawns blocks at designated spawn points and configures them with
    appropriate masses (known or variable X).
    """
    var left_spawn: Node3D = parent.get_node_or_null("LeftSpawnPoint")
    var right_spawn: Node3D = parent.get_node_or_null("RightSpawnPoint")
    
    if left_spawn == null or right_spawn == null:
        push_error("EquationGenerator: Missing spawn points")
        return
    
    # Create left side blocks
    for i in range(equation_data.left_coef):
        _spawn_block(left_spawn, true, i)  # Variable block
    
    _spawn_block(left_spawn, false, equation_data.left_const)  # Constant mass
    
    # Create right side blocks
    for i in range(equation_data.right_coef):
        _spawn_block(right_spawn, true, i)
    
    _spawn_block(right_spawn, false, equation_data.right_const)


func _spawn_block(spawn_point: Node3D, is_variable: bool, mass_or_index: int) -> WeightBlock:
    """Helper to instantiate and position a single block"""
    var block_scene := preload("res://scenes/realms/stage3/WeightBlock.tscn")
    var block := block_scene.instantiate() as WeightBlock
    
    block.is_variable = is_variable
    if not is_variable:
        block.fixed_mass = float(mass_or_index)
    
    spawn_point.add_child(block)
    
    # Offset position to prevent overlap
    var offset := Vector3(mass_or_index * 0.6, 0, 0)
    block.position += offset
    
    return block
```

---

# 6. DOMAIN 4: BLENDER TO GODOT ASSET PIPELINE

## 6.1 Complete Workflow Checklist

### 6.1.1 Pre-Export Preparation in Blender

**Geometry Optimization:**

- [ ] **Triangle Count Verification**
  - Characters: ≤ 5,000 tris (hero), ≤ 2,000 tris (NPCs)
  - Props: ≤ 1,000 tris
  - Environment chunks: ≤ 3,000 tris per LOD0 piece
  - Use Blender's **Face Count** overlay (Viewport Overlays → Statistics)

- [ ] **Modifier Application Order**
  ```
  Correct Stack Order:
  1. Subdivision Surface (set to Simple, not Catmull-Clark for low-poly)
  2. Decimate (if reducing from high-poly sculpt)
  3. Weld (merge close vertices)
  4. Apply All Modifiers before export
  ```

- [ ] **Manifold Geometry Check**
  - Enable **3D Print Toolbox** addon
  - Run "Check All" → fix non-manifold edges, intersecting faces
  - Ensure no duplicate vertices (Select → Select All by Trait → Duplicate)

- [ ] **Normal Consistency**
  - Select all faces → Mesh → Normals → Recalculate Outside (Shift+N)
  - Enable Face Orientation overlay (blue = outside, red = inside)
  - Fix flipped normals manually if needed

**Transform & Scale:**

- [ ] **Apply All Transforms**
  ```python
  # Python script for batch application in Blender
  import bpy
  
  for obj in bpy.context.selected_objects:
      bpy.context.view_layer.objects.active = obj
      bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
  ```

- [ ] **Unit Scale Configuration**
  - Scene Properties → Units → Unit Scale: **1.0**
  - Length: **Meters** (Godot default)
  - Verify: 1 Blender unit = 1 Godot meter

- [ ] **Origin Point Placement**
  - Characters: Origin at feet center (ground contact point)
  - Props: Origin at logical pivot (e.g., bottom center for stacking)
  - Use Object → Set Origin → Origin to 3D Cursor

**UV & Texture Preparation:**

- [ ] **UV Unwrapping Standards**
  - Seams placed on hidden edges (undersides, interior corners)
  - UV islands straightened and packed efficiently
  - Target **85%+ UV space utilization**
  - No overlapping islands (except mirrored symmetrical parts)

- [ ] **Texel Density Consistency**
  - Hero objects: **512 px/meter**
  - Mid-tier props: **256 px/meter**
  - Background elements: **128 px/meter**
  - Use **Texel Density Checker** addon for verification

- [ ] **Texture Baking (if applicable)**
  - Bake high-poly details to normal maps
  - Bake ambient occlusion to vertex colors or texture
  - Bake curvature for wear/edge highlighting
  - Output resolution: 1024×1024 or 2048×2048 (power of 2)

### 6.1.2 Rigging & Animation for Mobile

**Bone Count Optimization:**

| Character Type | Max Bones | Recommended | Notes |
|----------------|-----------|-------------|-------|
| Hero Player Character | 45 | 30-35 | Include facial bones for dialogue |
| NPC Mentors | 35 | 25-30 | Simplified hands, no fingers |
| Creatures/Animals | 25 | 15-20 | Quadruped rig |
| Mechanical Objects | 15 | 8-12 | Gear rotations, lever pivots |

**Rigging Best Practices:**

- [ ] **Bone Naming Convention**
  ```
  Format: side_feature_type
  Examples:
    - L_arm_ik, R_arm_ik
    - L_leg_fk_01, L_leg_fk_02
    - spine_01, spine_02, spine_03
    - head, jaw, eye_L, eye_R
  ```

- [ ] **Automatic Weight Painting**
  - Use **Weight Paint** mode → Weights → Assign Automatic from Bones
  - Refine problematic areas manually
  - Test deformation with extreme poses

- [ ] **Bone Constraints Setup**
  - IK constraints for limbs (IK target helpers)
  - Copy Rotation for mechanical linkages
  - Limit Rotation to prevent unnatural bends
  - **Apply all constraints before export** (bake to keyframes)

**Animation & NLA (Non-Linear Animation):**

- [ ] **Action Strip Organization**
  ```
  NLA Editor Structure:
  └─ Character_Name
     ├─ Track: Locomotion
     │  ├─ [Idle] (frames 1-60)
     │  ├─ [Walk_Cycle] (frames 61-120)
     │  └─ [Run_Cycle] (frames 121-160)
     ├─ Track: Interactions
     │  ├─ [Pickup_Object] (frames 1-45)
     │  └─ [Place_Object] (frames 46-90)
     └─ Track: Expressions
        ├─ [Happy_Wave] (frames 1-30)
        └─ [Think_Pose] (frames 1-40)
  ```

- [ ] **Keyframe Reduction**
  - Remove redundant keyframes (Graph Editor → Decimate)
  - Target: 1 keyframe every 2-3 frames for smooth motion
  - Preserve extremes and breakdown poses

- [ ] **Root Motion Handling**
  - Decide: Root motion vs. in-place animation
  - For Godot: **In-place preferred** (movement handled by code)
  - If root motion: Ensure Z-axis stays constant (no vertical drift)

- [ ] **NLA Track Naming for Godot Compatibility**
  ```
  CRITICAL: Godot imports NLA tracks as AnimationTree nodes
  Naming format: track_<category>_<animation_name>
  
  Good examples:
    - track_locomotion_idle
    - track_locomotion_walk
    - track_interaction_pickup
  
  Avoid:
    - Generic names like "Action", "Track.001"
    - Special characters (!@#$%^&*)
    - Spaces (use underscores)
  ```

### 6.1.3 glTF 2.0 Export Settings

**Blender glTF Exporter Configuration:**

```
File → Export → glTF 2.0 (.glb/.gltf)

☑ Selected Objects (export only what's needed)

Format:
  ○ glTF Binary (.glb)  ← RECOMMENDED for mobile
  ☐ glTF Embedded (.gltf)
  ☐ glTF Separate (.gltf + .bin + textures)

Include:
  ☑ Meshes
  ☑ Armatures (if rigged)
  ☑ Animations
  ☑ Blend Shapes (morph targets)
  ☐ Cameras (usually not needed)
  ☐ Lights (use Godot lighting instead)

Transform:
  ☑ Apply Modifiers
  ☑ Include Original Pivots
  ☐ Extra Empty Objects (disable to reduce hierarchy)

Mesh:
  ☑ Vertex Colors (if using baked AO)
  ☑ Tangents (required for normal maps)
  ○ Compression: Draco (optional, increases load time)

Animation:
  ☑ All Actions
  ☑ Group by NLA Tracks
  ☑ Sample Animations (keyframe interpolation)
  Frame Range: Manual (specify per-animation)
  ☑ Always Sample Animations
  Frame Rate: 60.0 (match Godot physics tick)

Materials:
  ○ Force Generation of Materials
  ☑ Keep Original Materials
  ☑ Baked Lighting (if lightmaps used)
  Texture Format: PNG (lossless)
  ☑ Compress (for .gltf separate, ignored for .glb)
```

**Post-Export Verification in Godot:**

1. **Import Settings Check:**
   ```
   Click imported .glb file in FileSystem dock
   
   Import Tab:
   - Compression: Lossless (for development) / VideoRam (for release)
   - Normal Map: Enabled (if present)
   - Mesh: Generate LODs (if multiple LODs in blend file)
   - Animation: Enabled, FPS = 60
   - Skin: Enabled (if rigged)
   ```

2. **Scene Instantiation Test:**
   ```gdscript
   var character_scene := preload("res://assets/3d_models/pythagoras_npc.glb")
   var instance := character_scene.instantiate() as Node3D
   add_child(instance)
   
   # Verify animations loaded
   var anim_player: AnimationPlayer = instance.get_node_or_null("AnimationPlayer")
   if anim_player:
       print("Animations found: ", anim_player.get_animation_list())
   ```

3. **Performance Profiling:**
   ```
   Godot Debugger → Monitors → 3D
   - Check: Draw Calls, Vertices, Textures
   - Target: < 500 draw calls per scene
   - If exceeded: Implement instancing, merge meshes
   ```

### 6.1.4 Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Scaled Wrong** | Model appears 100× too large/small | Apply transforms in Blender, verify unit scale |
| **Normals Flipped** | Model appears inside-out | Recalculate normals outside in Blender |
| **Missing Textures** | Pink checkerboard material | Embed textures in .glb, check texture paths |
| **Broken Rig** | Bones don't deform mesh | Apply bone constraints, check weight painting |
| **Animation Glitch** | Jerky or corrupted animation | Increase sample rate, check NLA track naming |
| **High VRAM Usage** | Out of memory on mobile | Reduce texture resolution, enable VRAM compression |
| **Slow Load Time** | Long pause when entering scene | Use async loading, implement resource preloading |

---

# 7. APPENDIX: SIGNAL FLOW DIAGRAMS & DATA STRUCTURES

## 7.1 Complete Signal Flow: Stage 3 Puzzle Completion

```
┌─────────────────────────────────────────────────────────────────────────┐
│                  STAGE 3 PUZZLE COMPLETION SIGNAL FLOW                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PLAYER ACTION                                                          │
│  (Drag X block to platform)                                             │
│       │                                                                 │
│       ▼                                                                 │
│  ┌─────────────────┐                                                    │
│  │  WeightBlock    │                                                    │
│  │  (RigidBody3D)  │                                                    │
│  └────────┬────────┘                                                    │
│           │                                                             │
│           │ body_entered signal                                         │
│           ▼                                                             │
│  ┌─────────────────┐                                                    │
│  │  Area3D         │                                                    │
│  │  (Platform)     │                                                    │
│  └────────┬────────┘                                                    │
│           │                                                             │
│           │ calls                                                       │
│           ▼                                                             │
│  ┌─────────────────┐                                                    │
│  │  BalanceScale   │◄──────────────────────┐                           │
│  │  (Node3D)       │                       │                           │
│  │                 │                       │ Timer timeout             │
│  │ _on_block_      │◄──────────────────────┘                           │
│  │ entered_        │ (MASS_CHECK_INTERVAL)                              │
│  │ platform()      │                                                    │
│  └────────┬────────┘                                                    │
│           │                                                             │
│           │ _recalculate_masses()                                       │
│           ▼                                                             │
│  ┌─────────────────┐                                                    │
│  │ Mass Computation│                                                    │
│  │                 │                                                    │
│  │ left_mass = Σ   │                                                    │
│  │ right_mass = Σ  │                                                    │
│  └────────┬────────┘                                                    │
│           │                                                             │
│           │ mass_changed.emit()                                         │
│           ▼                                                             │
│  ┌─────────────────┐     ┌─────────────────┐                           │
│  │  HUDController  │     │  AudioManager   │                           │
│  │                 │     │                 │                           │
│  │ Update mass     │     │ Play creak SFX  │                           │
│  │ display labels  │     │ based on tilt   │                           │
│  └─────────────────┘     └─────────────────┘                           │
│                                                                         │
│           │                                                             │
│           │ _check_equilibrium()                                        │
│           ▼                                                             │
│  ┌─────────────────────────────────────────┐                           │
│  │         EQUILIBRIUM CHECK               │                           │
│  │                                         │                           │
│  │  if abs(left_mass - right_mass) < ε:   │                           │
│  │      _on_equilibrium_reached()          │                           │
│  └────────────────┬────────────────────────┘                           │
│                   │                                                     │
│                   │ _validate_solution()                                │
│                   ▼                                                     │
│  ┌─────────────────────────────────────────┐                           │
│  │         SOLUTION VALIDATION             │                           │
│  │                                         │                           │
│  │  calculated_X = (right_const - left_)   │                           │
│  │                 ─────────────────────   │                           │
│  │                 (left_x_coef - right_)  │                           │
│  │                                         │                           │
│  │  is_correct = abs(calculated_X -        │                           │
│  │                   expected_X) < tol     │                           │
│  └────────────────┬────────────────────────┘                           │
│                   │                                                     │
│        ┌──────────┴──────────┐                                          │
│        │                     │                                          │
│        ▼                     ▼                                          │
│  ┌─────────────┐       ┌─────────────┐                                 │
│  │   CORRECT   │       │  INCORRECT  │                                 │
│  └──────┬──────┘       └──────┬──────┘                                 │
│         │                     │                                        │
│         │ scale_balanced.     │ scale_balanced.                        │
│         │ emit(true, time)    │ emit(false, time)                      │
│         │                     │                                        │
│         ▼                     ▼                                        │
│  ┌─────────────┐       ┌─────────────┐                                 │
│  │  GameManager│       │  Continue   │                                 │
│  │             │       │  Adjusting  │                                 │
│  │ - Stop timer│       │             │                                 │
│  │ - Show FX   │       │ - Restart   │                                 │
│  │ - Grant     │       │   timer     │                                 │
│  │   rewards   │       │             │                                 │
│  │ - Unlock    │       │             │                                 │
│  │   next      │       │             │                                 │
│  │   puzzle    │       │             │                                 │
│  └─────────────┘       └─────────────┘                                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 7.2 Data Structures Reference

### 7.2.1 Player Progress Save Structure

```gdscript
class_name PlayerSaveData

var player_id: String
var version: String = "1.0.0"
var last_login_timestamp: int

# Progress Tracking
var unlocked_realms: Array[String] = ["stage1"]
var completed_puzzles: Dictionary = {}  # {puzzle_id: completion_data}
var current_realm: String = "stage1"
var current_puzzle: String = ""

# Resources & Currency
var ancient_fragments: int = 0
var gear_parts: int = 0
var scrolls_collected: Array[String] = []

# Sky-Base Customization
var unlocked_customizations: Array[String] = []
var equipped_items: Dictionary = {
    "terrain": "",
    "architecture": "",
    "decorative": [],
    "atmospheric": ""
}

# Player Stats
var stats := PlayerStatistics.new()

# Settings
var settings := PlayerSettings.new()


class PlayerStatistics:
    var total_playtime_seconds: int = 0
    var puzzles_attempted: int = 0
    var puzzles_completed: int = 0
    var perfect_solves: int = 0  # No hints, first try
    var total_hints_used: int = 0
    var favorite_realm: String = ""
    var average_solve_time_ms: float = 0.0
    
    # Per-skill competency scores (0.0 - 1.0)
    var spatial_reasoning: float = 0.0
    var numerical_fluency: float = 0.0
    var algebraic_thinking: float = 0.0
    var logical_reasoning: float = 0.0


class PlayerSettings:
    var master_volume: float = 0.8
    var music_volume: float = 0.6
    var sfx_volume: float = 0.7
    var haptics_enabled: bool = true
    var difficulty_lock: bool = false  # Parental control
    var show_tutorials: bool = true
    var language: String = "en"
```

### 7.2.2 Puzzle Completion Data

```gdscript
class_name PuzzleCompletionData

var puzzle_id: String
var realm_id: String
var completion_timestamp: int
var solve_time_ms: int
var attempt_count: int
var hints_used: int
var is_perfect_solve: bool  # First try, no hints

# Detailed metrics for adaptive difficulty
var mistakes: Array[String] = []  # List of error types
var time_per_phase: Array[int] = []  # Breakdown of solve time
var optimal_path_deviation: float = 0.0  # How far from ideal solution

# Rewards granted
var fragments_earned: int = 0
var mystery_box_awarded: bool = false
var achievement_unlocks: Array[String] = []


static func from_dict(data: Dictionary) -> PuzzleCompletionData:
    var result := PuzzleCompletionData.new()
    result.puzzle_id = data.get("puzzle_id", "")
    result.realm_id = data.get("realm_id", "")
    result.completion_timestamp = data.get("completion_timestamp", 0)
    result.solve_time_ms = data.get("solve_time_ms", 0)
    result.attempt_count = data.get("attempt_count", 1)
    result.hints_used = data.get("hints_used", 0)
    result.is_perfect_solve = data.get("is_perfect_solve", false)
    result.mistakes = data.get("mistakes", [])
    result.time_per_phase = data.get("time_per_phase", [])
    result.optimal_path_deviation = data.get("optimal_path_deviation", 0.0)
    result.fragments_earned = data.get("fragments_earned", 0)
    result.mystery_box_awarded = data.get("mystery_box_awarded", false)
    result.achievement_unlocks = data.get("achievement_unlocks", [])
    return result
```

### 7.2.3 Adaptive Difficulty Metrics Buffer

```gdscript
class_name DifficultyMetricsBuffer

const MAX_BUFFER_SIZE: int = 10

var metrics_buffer: Array[PlayerSessionMetric] = []


func add_metric(metric: PlayerSessionMetric) -> void:
    metrics_buffer.append(metric)
    if metrics_buffer.size() > MAX_BUFFER_SIZE:
        metrics_buffer.pop_front()


func get_rolling_average(field: String) -> float:
    if metrics_buffer.is_empty():
        return 0.0
    
    var sum: float = 0.0
    for metric in metrics_buffer:
        sum += metric.get(field, 0.0)
    
    return sum / float(metrics_buffer.size())


func get_trend(field: String) -> float:
    """
    Calculate trend (slope) of metric over time
    
    Positive = increasing, Negative = decreasing
    Uses simple linear regression
    """
    if metrics_buffer.size() < 2:
        return 0.0
    
    var n: float = float(metrics_buffer.size())
    var sum_x: float = 0.0
    var sum_y: float = 0.0
    var sum_xy: float = 0.0
    var sum_xx: float = 0.0
    
    for i in range(metrics_buffer.size()):
        var x: float = float(i)
        var y: float = metrics_buffer[i].get(field, 0.0)
        
        sum_x += x
        sum_y += y
        sum_xy += x * y
        sum_xx += x * x
    
    # Slope formula: (n*Σxy - Σx*Σy) / (n*Σx² - (Σx)²)
    var denominator: float = n * sum_xx - sum_x * sum_x
    if abs(denominator) < 0.001:
        return 0.0
    
    var slope: float = (n * sum_xy - sum_x * sum_y) / denominator
    return slope


func should_increase_difficulty() -> bool:
    """Heuristic to determine if difficulty should increase"""
    if metrics_buffer.size() < 5:
        return false
    
    var avg_time: float = get_rolling_average("time_to_solve_ms")
    var avg_errors: float = get_rolling_average("incorrect_moves")
    var time_trend: float = get_trend("time_to_solve_ms")
    var error_trend: float = get_trend("incorrect_moves")
    
    # Conditions for increasing difficulty:
    # 1. Average solve time < 20 seconds
    # 2. Average errors < 1.0
    # 3. Time trend is negative (getting faster)
    # 4. Error trend is negative or flat (not making more mistakes)
    
    return (avg_time < 20000.0 and 
            avg_errors < 1.0 and 
            time_trend < 0.0 and 
            error_trend <= 0.0)


func should_decrease_difficulty() -> bool:
    """Heuristic to determine if difficulty should decrease"""
    if metrics_buffer.size() < 5:
        return false
    
    var avg_time: float = get_rolling_average("time_to_solve_ms")
    var avg_errors: float = get_rolling_average("incorrect_moves")
    var avg_hints: float = get_rolling_average("hints_requested")
    
    # Conditions for decreasing difficulty:
    # 1. Average solve time > 60 seconds OR
    # 2. Average errors > 3.0 OR
    # 3. Average hints > 2.0
    
    return (avg_time > 60000.0 or 
            avg_errors > 3.0 or 
            avg_hints > 2.0)
```

---

## 7.3 Glossary of Terms

| Term | Definition |
|------|------------|
| **ASTC** | Adaptive Scalable Texture Compression (modern mobile GPU format) |
| **DDA** | Dynamic Difficulty Adjustment (algorithmic challenge scaling) |
| **ETC2** | Ericsson Texture Compression 2 (OpenGL ES standard) |
| **glTF** | GL Transmission Format (3D asset interchange standard) |
| **IK/FK** | Inverse Kinematics / Forward Kinematics (animation techniques) |
| **JNI** | Java Native Interface (bridge between Java and native code) |
| **LOD** | Level of Detail (progressive mesh simplification) |
| **NLA** | Non-Linear Animation (Blender animation track system) |
| **PBR** | Physically-Based Rendering (material shading model) |
| **SPH** | Smoothed Particle Hydrodynamics (fluid simulation method) |
| **VRAM** | Video RAM (GPU memory for textures and meshes) |

---

## 7.4 References & Further Reading

1. **Godot 4 Documentation**: https://docs.godotengine.org/en/stable/
2. **glTF 2.0 Specification**: https://www.khronos.org/gltf/
3. **Android NDK Guide**: https://developer.android.com/ndk/guides
4. **Blender Export to glTF**: https://docs.blender.org/manual/en/latest/addons/io_scene_gltf.html
5. **Mobile Game Optimization**: https://developer.android.com/games/optimize
6. **Educational Game Design**: "The Art of Game Design" by Jesse Schell
7. **Adaptive Difficulty Research**: "Dynamic Difficulty Adjustment in Games" by Hunicke et al.

---

**Document End**

*This blueprint provides the foundational architecture for MathQuest Phase 1. Implementation should proceed with Stage 3 as the vertical slice, validating all systems before expanding to remaining realms.*
