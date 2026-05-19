# MathQuest Blender Asset Generator
# Run this script in Blender (File > Run Script) to generate all Stage 3 assets
# Exports optimized .glb files ready for Godot 4 import

import bpy
import bmesh
import math
from mathutils import Vector, Matrix
import os

# Configuration
OUTPUT_DIR = "//../assets/models"  # Relative to .blend file
SCALE_FACTOR = 0.1  # Blender units (meters) to Godot units
FPS = 60

def clean_scene():
    """Remove all existing objects"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Clear collections
    for collection in bpy.data.collections:
        bpy.data.collections.remove(collection)

def create_material(name, base_color, metallic=0.0, roughness=0.5, emission_strength=0.0):
    """Create PBR material optimized for mobile"""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    # Clear default nodes
    nodes.clear()
    
    # Create principled BSDF
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    bsdf.inputs['Base Color'].default_value = (*base_color, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    
    # Emission for glowing elements
    if emission_strength > 0:
        emission = nodes.new(type='ShaderNodeEmission')
        emission.inputs['Color'].default_value = (*base_color, 1.0)
        emission.inputs['Strength'].default_value = emission_strength
        
        mix = nodes.new(type='ShaderNodeMixShader')
        mix.location = (200, 0)
        mix.inputs['Fac'].default_value = 0.5
        
        links.new(emission.outputs['Emission'], mix.inputs[1])
        links.new(bsdf.outputs['BSDF'], mix.inputs[2])
        output = nodes.new(type='ShaderNodeOutputMaterial')
        output.location = (400, 0)
        links.new(mix.outputs['Shader'], output.inputs['Surface'])
    else:
        output = nodes.new(type='ShaderNodeOutputMaterial')
        output.location = (200, 0)
        links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    
    return mat

def create_scale_base():
    """Create the main balance scale structure (Al-Khwarizmi style)"""
    # Base platform
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=(0, 0, 0))
    base = bpy.context.active_object
    base.name = "ScaleBase"
    base.scale = (3.0, 1.5, 0.3) * SCALE_FACTOR
    
    # Apply modifier
    bpy.ops.object.transform_apply(scale=True)
    
    # Assign material
    base_mat = create_material("MarbleBase", (0.95, 0.92, 0.88), metallic=0.1, roughness=0.4)
    if base.data.materials:
        base.data.materials[0] = base_mat
    else:
        base.data.materials.append(base_mat)
    
    return base

def create_scale_arm():
    """Create the horizontal balance arm with pivot"""
    # Central pivot
    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=0.3, location=(0, 0, 0.8))
    pivot = bpy.context.active_object
    pivot.name = "ScalePivot"
    pivot.scale = Vector((1, 1, 1)) * SCALE_FACTOR
    bpy.ops.object.transform_apply(scale=True)
    
    pivot_mat = create_material("BrassPivot", (0.8, 0.65, 0.2), metallic=0.9, roughness=0.2)
    pivot.data.materials[0] = pivot_mat
    
    # Horizontal arm
    bpy.ops.mesh.primitive_cube_add(size=0.2, location=(0, 0, 0.95))
    arm = bpy.context.active_object
    arm.name = "ScaleArm"
    arm.scale = (4.0, 0.15, 0.25) * SCALE_FACTOR
    bpy.ops.object.transform_apply(scale=True)
    
    arm_mat = create_material("WoodenArm", (0.55, 0.35, 0.2), metallic=0.0, roughness=0.7)
    arm.data.materials[0] = arm_mat
    
    # Parent arm to pivot
    arm.parent = pivot
    
    return pivot, arm

def create_platform(side="left"):
    """Create hanging platform for weights"""
    x_offset = 1.5 if side == "left" else -1.5
    
    # Hanging chains (simplified as cylinders)
    chain_left = None
    chain_right = None
    
    for i, x_off in enumerate([-0.08, 0.08]):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.02, depth=0.6, 
                                           location=(x_offset + x_off, 0, 0.65))
        chain = bpy.context.active_object
        chain.name = f"Chain_{side}_{i}"
        chain.scale = Vector((1, 1, 1)) * SCALE_FACTOR
        bpy.ops.object.transform_apply(scale=True)
        
        chain_mat = create_material("Chain", (0.3, 0.3, 0.3), metallic=0.8, roughness=0.3)
        chain.data.materials[0] = chain_mat
        
        if i == 0:
            chain_left = chain
        else:
            chain_right = chain
    
    # Platform plate
    bpy.ops.mesh.primitive_cylinder_add(radius=0.4, depth=0.05, 
                                       location=(x_offset, 0, 0.35))
    platform = bpy.context.active_object
    platform.name = f"Platform_{side.capitalize()}"
    platform.scale = Vector((1, 1, 1)) * SCALE_FACTOR
    bpy.ops.object.transform_apply(scale=True)
    
    plat_mat = create_material("PlatformPlate", (0.7, 0.5, 0.3), metallic=0.3, roughness=0.5)
    platform.data.materials[0] = plat_mat
    
    # Parent chains and platform to a container
    container = bpy.data.objects.new(f"PlatformContainer_{side.capitalize()}", None)
    bpy.context.collection.objects.link(container)
    container.location = (0, 0, 0)
    
    platform.parent = container
    if chain_left:
        chain_left.parent = container
    if chain_right:
        chain_right.parent = container
    
    return container

def create_weight_block(weight_type="number", value=1, is_variable=False):
    """Create individual weight blocks (1kg, 5kg, 10kg, X variable)"""
    # Determine size based on weight
    if is_variable:
        size = 0.35
        color = (0.9, 0.2, 0.2, 1.0)  # Red for X
        name = "WeightBlock_X"
    else:
        size = 0.25 + (value * 0.03)
        if value <= 3:
            color = (0.3, 0.6, 0.9, 1.0)  # Blue for small
        elif value <= 7:
            color = (0.9, 0.7, 0.2, 1.0)  # Gold for medium
        else:
            color = (0.4, 0.8, 0.4, 1.0)  # Green for large
        name = f"WeightBlock_{value}"
    
    # Create block with beveled edges
    bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, 0))
    block = bpy.context.active_object
    block.name = name
    block.scale = Vector((1, 1, 1)) * SCALE_FACTOR
    bpy.ops.object.transform_apply(scale=True)
    
    # Add bevel modifier for smooth edges
    bevel_mod = block.modifiers.new(name="Bevel", type='BEVEL')
    bevel_mod.width = 0.02
    bevel_mod.segments = 3
    bpy.ops.object.modifier_apply(modifier=bevel_mod.name)
    
    # Assign material
    block_mat = create_material(name.replace("WeightBlock_", "Weight_"), 
                               color[:3], metallic=0.4, roughness=0.3,
                               emission_strength=0.3 if is_variable else 0.0)
    block.data.materials[0] = block_mat
    
    # Add socket marker (small depression on bottom)
    # This helps with snap points in Godot
    
    return block

def create_decorative_elements():
    """Create Islamic Golden Age decorative elements for the scene"""
    # Ornate pillars
    for i, angle in enumerate([0, 90, 180, 270]):
        rad = math.radians(angle)
        x = math.cos(rad) * 2.5
        z = math.sin(rad) * 2.5
        
        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=2.0, 
                                           location=(x, 0, z))
        pillar = bpy.context.active_object
        pillar.name = f"DecorativePillar_{i}"
        pillar.scale = Vector((1, 1, 1)) * SCALE_FACTOR
        bpy.ops.object.transform_apply(scale=True)
        
        pillar_mat = create_material("SandstonePillar", (0.85, 0.75, 0.6), 
                                    metallic=0.0, roughness=0.8)
        pillar.data.materials[0] = pillar_mat
    
    # Floating geometric patterns (Islamic star patterns)
    bpy.ops.mesh.primitive_circle_add(vertices=8, radius=0.8, location=(0, 2.5, 1.5))
    pattern = bpy.context.active_object
    pattern.name = "GeometricPattern"
    pattern.scale = Vector((1, 1, 1)) * SCALE_FACTOR
    
    pattern_mat = create_material("GlowingPattern", (0.4, 0.8, 1.0), 
                                 metallic=0.2, roughness=0.2, 
                                 emission_strength=1.5)
    pattern.data.materials[0] = pattern_mat

def setup_rigging():
    """Add armature for scale animation"""
    bpy.ops.object.armature_add(location=(0, 0, 0))
    armature = bpy.context.active_object
    armature.name = "ScaleRig"
    
    # Enter edit mode
    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = armature.data.edit_bones
    
    # Create pivot bone
    bone = edit_bones.new("PivotBone")
    bone.head = (0, 0, 0.8 * SCALE_FACTOR)
    bone.tail = (0, 0, 1.0 * SCALE_FACTOR)
    
    # Create left platform bone
    left_bone = edit_bones.new("LeftPlatformBone")
    left_bone.head = (-1.5 * SCALE_FACTOR, 0, 0.65 * SCALE_FACTOR)
    left_bone.tail = (-1.5 * SCALE_FACTOR, 0, 0.35 * SCALE_FACTOR)
    left_bone.parent = bone
    
    # Create right platform bone
    right_bone = edit_bones.new("RightPlatformBone")
    right_bone.head = (1.5 * SCALE_FACTOR, 0, 0.65 * SCALE_FACTOR)
    right_bone.tail = (1.5 * SCALE_FACTOR, 0, 0.35 * SCALE_FACTOR)
    right_bone.parent = bone
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    return armature

def setup_lights():
    """Create mobile-optimized lighting"""
    # Key light (sun)
    bpy.ops.object.light_add(type='SUN', location=(5, -3, 8))
    sun = bpy.context.active_object
    sun.name = "SunLight"
    sun.data.energy = 2.5
    sun.data.color = (1.0, 0.95, 0.85)
    sun.rotation_euler = (math.radians(60), math.radians(-30), math.radians(45))
    
    # Fill light
    bpy.ops.object.light_add(type='AREA', location=(-3, 2, 4))
    fill = bpy.context.active_object
    fill.name = "FillLight"
    fill.data.energy = 0.8
    fill.data.size = 3.0
    fill.data.color = (0.8, 0.9, 1.0)
    
    # Rim light for depth
    bpy.ops.object.light_add(type='POINT', location=(0, -4, 2))
    rim = bpy.context.active_object
    rim.name = "RimLight"
    rim.data.energy = 1.2
    rim.data.color = (1.0, 0.7, 0.5)

def setup_camera():
    """Position camera for optimal gameplay view"""
    bpy.ops.object.camera_add(location=(0, -6, 3))
    cam = bpy.context.active_object
    cam.name = "GameCamera"
    cam.rotation_euler = (math.radians(75), 0, 0)
    cam.data.lens = 35
    cam.data.clip_end = 50.0
    
    bpy.context.scene.camera = cam

def create_animation():
    """Create simple idle animation for the scale"""
    # Ensure we have an action
    if not bpy.context.object.animation_data:
        bpy.context.object.animation_data_create()
    
    action = bpy.data.actions.new(name="ScaleIdle")
    bpy.context.object.animation_data.action = action
    
    # Animate slight wobble (will be controlled by physics in Godot)
    # This is just for visual reference
    
    fcurve = action.fcurves.new(data_path="rotation_euler", index=2)
    for frame in range(0, 120, 10):
        fcurve.keyframe_points.insert(frame, math.sin(frame * 0.1) * 0.02)

def export_glb(filepath):
    """Export to glTF 2.0 binary format optimized for Godot"""
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        export_selected=True,
        use_selection=True,
        export_apply=True,
        export_animations=True,
        export_morph=True,
        export_cameras=True,
        export_lights=True,
        export_yup=True,  # Godot uses Y-up
        export_skins=True,
        export_all_influences=True,
        export_original_specular=True,
        export_image_format='WEBP',
        export_texture_size=1024,
        export_materials='EXPORT',
        export_colors=True,
        export_extras=True,
        optimize_animation_size=True,
        export_frame_range=(1, 120) if bpy.context.scene.frame_end > 1 else (1, 1)
    )

def main():
    """Main execution function"""
    print("=== MathQuest Asset Generator ===")
    print("Creating Stage 3: Al-Khwarizmi's Balance Scale")
    
    # Clean scene
    clean_scene()
    print("✓ Scene cleaned")
    
    # Create materials first
    print("Creating materials...")
    
    # Build scale structure
    base = create_scale_base()
    print("✓ Scale base created")
    
    pivot, arm = create_scale_arm()
    print("✓ Scale arm and pivot created")
    
    left_platform = create_platform("left")
    right_platform = create_platform("right")
    print("✓ Platforms created")
    
    # Create sample weight blocks
    weights = []
    for val in [1, 2, 5]:
        weights.append(create_weight_block(value=val))
    weights.append(create_weight_block(is_variable=True))
    print("✓ Weight blocks created")
    
    # Add decorations
    create_decorative_elements()
    print("✓ Decorative elements added")
    
    # Setup rigging
    armature = setup_rigging()
    print("✓ Rigging setup complete")
    
    # Lighting and camera
    setup_lights()
    setup_camera()
    print("✓ Lights and camera configured")
    
    # Select all for export
    bpy.ops.object.select_all(action='SELECT')
    
    # Export
    output_path = os.path.join(bpy.path.abspath(OUTPUT_DIR), "stage3_balance_scale.glb")
    export_glb(output_path)
    print(f"✓ Exported to: {output_path}")
    
    # Also export individual components as separate files if needed
    # (for modular loading in Godot)
    
    print("\n=== Generation Complete ===")
    print("Import stage3_balance_scale.glb into Godot 4.x")
    print("Ensure 'Y Up' is enabled in Godot import settings")

if __name__ == "__main__":
    main()
