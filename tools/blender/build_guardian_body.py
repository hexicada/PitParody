"""
Clean low-poly Guardian mannequin for Godot — intentional game-placeholder quality.

Why previous versions looked freakish:
  - Dozens of overlapping spheres/cubes joined into one mesh → z-fighting, melted silhouette
  - Bad automatic / height-band weights → stretchy limbs
  - Trying to fake organic flesh with primitives

This version:
  - Articulated ACTION-FIGURE style (like a good greybox hero)
  - Separate rigid pieces, parented to ONE bone each (no soft skinning mess)
  - Standard human proportions (~1.8m, 7.5 heads)
  - Full Destiny-ish armor coverage, sealed helm, short cloak as flat panels
  - Head_FP_Hide for hybrid FPS

Usage:
  blender --background --python tools/blender/build_guardian_body.py
"""

from __future__ import annotations

from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector


def _project_root() -> Path:
    here = Path(__file__).resolve().parent
    root = here.parent.parent
    (root / "res" / "assets" / "characters" / "player").mkdir(parents=True, exist_ok=True)
    return root


ROOT = _project_root()
OUT_GLB = ROOT / "res" / "assets" / "characters" / "player" / "guardian_body.glb"

# Proportions (meters). Total height ~1.80
HEAD_H = 0.24
# Bone joint heights (feet at 0)
ANKLE = 0.08
KNEE = 0.48
HIP = 0.96
SHOULDER = 1.42
NECK = 1.52
HEAD_TOP = 1.80


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
        for block in list(coll):
            coll.remove(block)


def mat(name, rgba, rough=0.55, metal=0.25, emit=None, emit_str=0.0):
    m = bpy.data.materials.new(name=name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    bsdf = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None) if m.node_tree else None
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = rough
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metal
        if emit is not None:
            for k in ("Emission Color", "Emission"):
                if k in bsdf.inputs:
                    bsdf.inputs[k].default_value = (*emit, 1.0)
                    break
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emit_str
    return m


def smooth(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()


def make_box(name, center, size, material):
    """size = full extents (x,y,z). Clean cube, no overlap intent."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = Vector(size)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    return obj


def make_cyl(name, center, radius, height, material, verts=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=height, location=center)
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    smooth(obj)
    return obj


def make_sphere(name, center, radius, material, seg=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(6, seg // 2), radius=radius, location=center)
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    smooth(obj)
    return obj


def create_armature():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm = bpy.context.active_object
    arm.name = "Armature"
    eb = arm.data.edit_bones

    def bone(name, parent, head, tail):
        b = eb.new(name) if name != "Root" else eb[0]
        if name == "Root":
            b.name = "Root"
        b.head = Vector(head)
        b.tail = Vector(tail)
        if parent and name != "Root":
            b.parent = eb[parent]
            b.use_connect = False
        return b

    bone("Root", None, (0, 0, 0), (0, 0, 0.1))
    bone("Hips", "Root", (0, 0, HIP), (0, 0, HIP + 0.12))
    bone("Spine", "Hips", (0, 0, HIP + 0.12), (0, 0, SHOULDER - 0.08))
    bone("Chest", "Spine", (0, 0, SHOULDER - 0.08), (0, 0, SHOULDER + 0.06))
    bone("Neck", "Chest", (0, 0, NECK - 0.04), (0, 0, NECK + 0.06))
    bone("Head", "Neck", (0, 0, NECK + 0.06), (0, 0, HEAD_TOP))
    bone("UpperArm_L", "Chest", (-0.22, 0, SHOULDER), (-0.22, 0.02, 1.12))
    bone("LowerArm_L", "UpperArm_L", (-0.22, 0.02, 1.12), (-0.22, 0.04, 0.88))
    bone("UpperArm_R", "Chest", (0.22, 0, SHOULDER), (0.22, 0.02, 1.12))
    bone("LowerArm_R", "UpperArm_R", (0.22, 0.02, 1.12), (0.22, 0.04, 0.88))
    bone("Thigh_L", "Hips", (-0.11, 0, HIP), (-0.11, 0.02, KNEE))
    bone("Calf_L", "Thigh_L", (-0.11, 0.02, KNEE), (-0.11, 0.04, ANKLE))
    bone("Thigh_R", "Hips", (0.11, 0, HIP), (0.11, 0.02, KNEE))
    bone("Calf_R", "Thigh_R", (0.11, 0.02, KNEE), (0.11, 0.04, ANKLE))
    bone("Cloak", "Chest", (0, -0.12, SHOULDER), (0, -0.18, 1.0))

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def parent_bone(mesh_obj, arm_obj, bone_name):
    """Rigid bind: whole mesh follows one bone. Clean, no freaky weights."""
    mesh_obj.parent = arm_obj
    mesh_obj.parent_type = "BONE"
    mesh_obj.parent_bone = bone_name
    # Blender bone parenting is relative to bone tip in bone space — reset to sit on bone.
    # Clear transform so piece stays where we modeled it in world space by using bone-relative fix.
    # Standard approach: keep world matrix after parenting.
    # Actually after parent_type BONE, location is in bone space from bone head/tail.
    # Easier: use Armature modifier with single-group full weight (still clean).
    mesh_obj.parent = None

    # Armature deform with single bone, weight 1
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type="ARMATURE_NAME")

    while mesh_obj.vertex_groups:
        mesh_obj.vertex_groups.remove(mesh_obj.vertex_groups[0])
    vg = mesh_obj.vertex_groups.new(name=bone_name)
    vg.add([v.index for v in mesh_obj.data.vertices], 1.0, "REPLACE")
    mod = next((m for m in mesh_obj.modifiers if m.type == "ARMATURE"), None)
    if not mod:
        mod = mesh_obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm_obj


def build_parts(mats):
    """Few solid pieces with deliberate gaps — reads as armor mannequin, not melt."""
    plate, dark, suit, cloak, glow, visor, boot = mats
    parts = []  # (object, bone_name, is_head)

    # Legs — cylinders that DON'T dig into hips
    for side, sx, thigh_b, calf_b in (
        ("L", -0.11, "Thigh_L", "Calf_L"),
        ("R", 0.11, "Thigh_R", "Calf_R"),
    ):
        thigh_z = (HIP + KNEE) * 0.5
        thigh_h = (HIP - KNEE) * 0.88
        calf_z = (KNEE + ANKLE) * 0.5 + 0.02
        calf_h = (KNEE - ANKLE) * 0.85
        parts.append((make_cyl(f"Thigh{side}", (sx, 0, thigh_z), 0.09, thigh_h, suit, 12), thigh_b, False))
        parts.append((make_cyl(f"ThighPlate{side}", (sx, 0.04, thigh_z + 0.02), 0.095, thigh_h * 0.55, plate, 12), thigh_b, False))
        parts.append((make_box(f"Knee{side}", (sx, 0.06, KNEE), (0.12, 0.1, 0.1), dark), thigh_b, False))
        parts.append((make_cyl(f"Calf{side}", (sx, 0.02, calf_z), 0.085, calf_h, plate, 12), calf_b, False))
        parts.append((make_box(f"Boot{side}", (sx, 0.08, 0.09), (0.14, 0.28, 0.14), boot), calf_b, False))

    # Hips / pelvis block
    parts.append((make_box("Pelvis", (0, 0, HIP + 0.02), (0.34, 0.18, 0.16), suit), "Hips", False))
    parts.append((make_box("HipPlateL", (-0.14, 0.05, HIP + 0.02), (0.14, 0.12, 0.14), plate), "Hips", False))
    parts.append((make_box("HipPlateR", (0.14, 0.05, HIP + 0.02), (0.14, 0.12, 0.14), plate), "Hips", False))
    parts.append((make_box("Belt", (0, 0.02, HIP + 0.1), (0.36, 0.16, 0.05), dark), "Hips", False))
    parts.append((make_box("BeltLight", (0, 0.1, HIP + 0.1), (0.07, 0.04, 0.04), glow), "Hips", False))

    # Torso
    spine_z = (HIP + SHOULDER) * 0.5
    spine_h = (SHOULDER - HIP) * 0.75
    parts.append((make_cyl("Torso", (0, 0, spine_z + 0.04), 0.14, spine_h, suit, 12), "Spine", False))
    parts.append((make_box("Chest", (0, 0.06, SHOULDER - 0.06), (0.34, 0.16, 0.28), plate), "Chest", False))
    parts.append((make_box("ChestCore", (0, 0.14, SHOULDER - 0.08), (0.08, 0.04, 0.08), glow), "Chest", False))

    # Pauldrons
    parts.append((make_box("PauldronL", (-0.28, 0, SHOULDER + 0.02), (0.18, 0.16, 0.12), plate), "Chest", False))
    parts.append((make_box("PauldronR", (0.28, 0, SHOULDER + 0.02), (0.18, 0.16, 0.12), plate), "Chest", False))

    # Arms
    for side, sx, ub, lb in (
        ("L", -0.28, "UpperArm_L", "LowerArm_L"),
        ("R", 0.28, "UpperArm_R", "LowerArm_R"),
    ):
        upper_z = (SHOULDER + 1.12) * 0.5
        upper_h = abs(SHOULDER - 1.12) * 0.85
        lower_z = (1.12 + 0.9) * 0.5
        lower_h = abs(1.12 - 0.9) * 0.9
        parts.append((make_cyl(f"UpperArm{side}", (sx, 0.01, upper_z), 0.065, upper_h, suit, 10), ub, False))
        parts.append((make_cyl(f"Vambrace{side}", (sx, 0.03, lower_z), 0.07, lower_h, plate, 10), lb, False))
        parts.append((make_box(f"Gauntlet{side}", (sx, 0.05, 0.88), (0.1, 0.1, 0.1), dark), lb, False))

    # Cloak — simple flat panel (not shredded blobs)
    parts.append((make_box("Cloak", (0, -0.16, 1.2), (0.36, 0.06, 0.7), cloak), "Cloak", False))
    parts.append((make_box("CloakCollar", (0, -0.12, SHOULDER + 0.02), (0.38, 0.08, 0.08), cloak), "Chest", False))

    # Neck seal
    parts.append((make_cyl("Neck", (0, 0, NECK), 0.07, 0.08, dark, 10), "Neck", False))

    # HELMET only in head group — sealed, no face
    # Name contains Head_FP_Hide for controller hide
    helm = make_box("Head_FP_Hide", (0, 0.02, NECK + HEAD_H * 0.55), (0.22, 0.24, HEAD_H * 0.95), plate)
    vis = make_box("Visor", (0, 0.13, NECK + HEAD_H * 0.55), (0.16, 0.04, 0.07), visor)
    jaw = make_box("Jaw", (0, 0.08, NECK + 0.08), (0.14, 0.1, 0.08), dark)
    crest = make_box("Crest", (0, -0.02, HEAD_TOP - 0.04), (0.06, 0.12, 0.06), dark)
    # Parent visor/jaw/crest as children of helm for single hide unit — join head pieces
    head_bits = [helm, vis, jaw, crest]
    bpy.ops.object.select_all(action="DESELECT")
    for o in head_bits:
        o.select_set(True)
    bpy.context.view_layer.objects.active = helm
    bpy.ops.object.join()
    head_obj = bpy.context.active_object
    head_obj.name = "Head_FP_Hide"
    parts.append((head_obj, "Head", True))

    return parts


def make_idle(arm_obj):
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    pose = arm_obj.pose
    action = bpy.data.actions.new(name="Idle")
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = action
    scn = bpy.context.scene
    scn.render.fps = 24
    scn.frame_start = 1
    scn.frame_end = 48

    def key(bone, frames):
        if bone not in pose.bones:
            return
        pb = pose.bones[bone]
        pb.rotation_mode = "XYZ"
        for fr, eul in frames:
            scn.frame_set(fr)
            pb.rotation_euler = eul
            pb.keyframe_insert(data_path="rotation_euler", frame=fr)

    # Subtle only — mannequin shouldn't thrash
    key("Chest", [(1, Euler((0, 0, 0))), (24, Euler((0.025, 0, 0))), (48, Euler((0, 0, 0)))])
    key("Cloak", [(1, Euler((0.02, 0, 0))), (24, Euler((-0.03, 0.02, 0))), (48, Euler((0.02, 0, 0)))])
    key("UpperArm_L", [(1, Euler((0.03, 0, 0.02))), (24, Euler((0.04, 0, 0.015))), (48, Euler((0.03, 0, 0.02)))])
    key("UpperArm_R", [(1, Euler((0.03, 0, -0.02))), (24, Euler((0.04, 0, -0.015))), (48, Euler((0.03, 0, -0.02)))])

    if hasattr(action, "use_cyclic"):
        action.use_cyclic = True
    if hasattr(action, "use_frame_range"):
        action.use_frame_range = True
        action.frame_start = 1
        action.frame_end = 48
    bpy.ops.object.mode_set(mode="OBJECT")
    scn.frame_set(1)


def export_glb(path: Path):
    bpy.ops.object.select_all(action="SELECT")
    path.parent.mkdir(parents=True, exist_ok=True)
    kwargs = dict(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_yup=True,
        export_animations=True,
    )
    try:
        bpy.ops.export_scene.gltf(**kwargs, export_anim_single_armature=True)
    except TypeError:
        bpy.ops.export_scene.gltf(**kwargs)
    print("Exported:", path)


def main():
    clear_scene()

    plate = mat("Plate", (0.75, 0.77, 0.80, 1), rough=0.45, metal=0.5)
    dark = mat("PlateDark", (0.25, 0.27, 0.30, 1), rough=0.5, metal=0.45)
    suit = mat("Suit", (0.07, 0.08, 0.09, 1), rough=0.85, metal=0.05)
    cloak = mat("Cloak", (0.12, 0.11, 0.14, 1), rough=0.9, metal=0.0)
    glow = mat("Glow", (0.3, 0.7, 0.95, 1), rough=0.3, metal=0.1, emit=(0.2, 0.6, 1.0), emit_str=1.4)
    visor = mat("Visor", (0.05, 0.15, 0.22, 1), rough=0.15, metal=0.7, emit=(0.15, 0.5, 0.85), emit_str=1.0)
    boot = mat("Boot", (0.1, 0.1, 0.12, 1), rough=0.8, metal=0.2)

    arm = create_armature()
    for obj, bone, _is_head in build_parts((plate, dark, suit, cloak, glow, visor, boot)):
        parent_bone(obj, arm, bone)

    make_idle(arm)
    export_glb(OUT_GLB)
    print("Done: clean mannequin Guardian (rigid pieces, no melt-skin)")


if __name__ == "__main__":
    main()
