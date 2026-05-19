# MathQuest Blender Asset Generator - Stage 1 (Pythagoras)
# Run this script in Blender (File > Run Script) to generate Stage 1 assets

import bpy
import math
from mathutils import Vector
import os

OUTPUT_DIR = "//../assets/models"
SCALE_FACTOR = 0.1

def clean_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for collection in bpy.data.collections:
        bpy.data.collections.remove(collection)

def create_material(name, base_color, metallic=0.0, roughness=0.5, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    bsdf.inputs['Base Color'].default_value = (*base_color, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    
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

def create_tetraktys_pyramid():
    """Create the Tetraktys triangle (1+2+3+4=10 spheres)"""
    container = bpy.data.objects.new("TetraktysContainer", None)
    bpy.context.collection.objects.link(container)
    
    sphere_radius = 0.15 * SCALE_FACTOR
    vertical_spacing = 0.35 * SCALE_FACTOR
    horizontal_spacing = 0.35 * SCALE_FACTOR
    
    row = 0
    for count in [1, 2, 3, 4]:
        z_height = row * vertical_spacing
        y_offset = -(count - 1) * horizontal_spacing / 2
        
        for i in range(count):
            x_pos = y_offset + i * horizontal_spacing
            bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=16, 
                                                  radius=sphere_radius,
                                                  location=(x_pos, 0, z_height))
            sphere = bpy.context.active_object
            sphere.name = f"TetraktysSphere_R{row}_C{i}"
            
            # Color based on row (primary colors)
            colors = [(1.0, 0.2, 0.2), (0.2, 0.4, 1.0), (1.0, 0.9, 0.2), (0.3, 0.9, 0.3)]
            sphere_mat = create_material(f"TetraktysMat_R{row}", colors[row], 
                                        metallic=0.3, roughness=0.2, emission_strength=0.8)
            sphere.data.materials[0] = sphere_mat
            
            sphere.parent = container
        
        row += 1
    
    return container

def create_marble_platform():
    """Create floating island platform"""
    bpy.ops.mesh.primitive_cylinder_add(radius=1.5, depth=0.3, location=(0, 0, 0))
    platform = bpy.context.active_object
    platform.name = "MarblePlatform"
    platform.scale = Vector((1, 1, 1)) * SCALE_FACTOR
    bpy.ops.object.transform_apply(scale=True)
    
    plat_mat = create_material("MarbleWhite", (0.95, 0.93, 0.9), metallic=0.05, roughness=0.3)
    platform.data.materials[0] = plat_mat
    
    return platform

def create_geometric_bridge():
    """Create bridge segments that form geometric shapes"""
    bridge_container = bpy.data.objects.new("GeometricBridge", None)
    bpy.context.collection.objects.link(bridge_container)
    
    # Create triangular bridge segments
    for i in range(5):
        x_pos = i * 0.8 * SCALE_FACTOR
        bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.2, radius2=0.15,
                                        depth=0.6, location=(x_pos, 0, 0.3))
        segment = bpy.context.active_object
        segment.name = f"BridgeSegment_{i}"
        segment.scale = Vector((1, 1, 1)) * SCALE_FACTOR
        bpy.ops.object.transform_apply(scale=True)
        
        seg_mat = create_material("BridgeStone", (0.8, 0.75, 0.7), metallic=0.1, roughness=0.5)
        segment.data.materials[0] = seg_mat
        segment.parent = bridge_container
    
    return bridge_container

def create_greek_pillars():
    """Create ancient Greek temple pillars"""
    pillars_container = bpy.data.objects.new("GreekPillars", None)
    bpy.context.collection.objects.link(pillars_container)
    
    positions = [(-2, -1.5), (2, -1.5), (-2, 1.5), (2, 1.5)]
    
    for i, (x, z) in enumerate(positions):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=2.5, 
                                            location=(x, 0, z))
        pillar = bpy.context.active_object
        pillar.name = f"GreekPillar_{i}"
        pillar.scale = Vector((1, 1, 1)) * SCALE_FACTOR
        bpy.ops.object.transform_apply(scale=True)
        
        pillar_mat = create_material("MarblePillar", (0.92, 0.88, 0.85), 
                                    metallic=0.0, roughness=0.4)
        pillar.data.materials[0] = pillar_mat
        pillar.parent = pillars_container
    
    return pillars_container

def setup_lights():
    bpy.ops.object.light_add(type='SUN', location=(5, -5, 8))
    sun = bpy.context.active_object
    sun.name = "SunLight"
    sun.data.energy = 3.0
    sun.data.color = (1.0, 0.98, 0.9)
    sun.rotation_euler = (math.radians(55), math.radians(-35), math.radians(40))
    
    bpy.ops.object.light_add(type='AREA', location=(-4, 3, 3))
    fill = bpy.context.active_object
    fill.name = "FillLight"
    fill.data.energy = 0.6
    fill.data.size = 4.0
    fill.data.color = (0.7, 0.8, 1.0)

def setup_camera():
    bpy.ops.object.camera_add(location=(0, -8, 4))
    cam = bpy.context.active_object
    cam.name = "GameCamera"
    cam.rotation_euler = (math.radians(70), 0, 0)
    cam.data.lens = 35
    bpy.context.scene.camera = cam

def export_glb(filepath):
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        export_selected=True,
        use_selection=True,
        export_apply=True,
        export_animations=True,
        export_cameras=True,
        export_lights=True,
        export_yup=True,
        export_materials='EXPORT',
        export_image_format='WEBP',
        export_texture_size=1024
    )

def main():
    print("=== MathQuest Stage 1 Asset Generator ===")
    clean_scene()
    
    create_marble_platform()
    create_tetraktys_pyramid()
    create_geometric_bridge()
    create_greek_pillars()
    setup_lights()
    setup_camera()
    
    bpy.ops.object.select_all(action='SELECT')
    output_path = os.path.join(bpy.path.abspath(OUTPUT_DIR), "stage1_tetraktys.glb")
    export_glb(output_path)
    print(f"✓ Exported: {output_path}")

if __name__ == "__main__":
    main()
