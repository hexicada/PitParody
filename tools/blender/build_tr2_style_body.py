"""
Build a low-poly Tomb Raider 2–inspired adventure heroine for Godot (hybrid FP ready).

Visual tier: "readable PS1 hero" — not boxes, not high-poly.
- Better athletic proportions, waist pinch, tank straps, boot soles
- Smooth-shaded mid-poly spheres/cylinders
- Multi-bone skinning by height bands
- Looping Idle + Head_FP_Hide for hybrid FPS

Usage:
  blender --background --python tools/blender/build_tr2_style_body.py
"""

from __future__ import annotations

from pathlib import Path

import bpy
from mathutils import Euler, Vector


def _project_root() -> Path:
    here = Path(__file__).resolve().parent
    root = here.parent.parent
    (root / "res" / "assets" / "characters" / "player").mkdir(parents=True, exist_ok=True)
    return root


ROOT = _project_root()
OUT_GLB = ROOT / "res" / "assets" / "characters" / "player" / "tr2_style_body.glb"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.actions):
        for block in list(coll):
            coll.remove(block)


def mat(
    name: str,
    color: tuple[float, float, float, float],
    rough: float = 0.75,
    metallic: float = 0.0,
    sss: float = 0.0,
) -> bpy.types.Material:
    m = bpy.data.materials.new(name=name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree
    if nt:
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf:
            bsdf.inputs["Base Color"].default_value = color
            if "Roughness" in bsdf.inputs:
                bsdf.inputs["Roughness"].default_value = rough
            for key in ("Metallic",):
                if key in bsdf.inputs:
                    bsdf.inputs[key].default_value = metallic
            # Soft skin-ish response when supported
            for key in ("Subsurface Weight", "Subsurface"):
                if key in bsdf.inputs and sss > 0.0:
                    bsdf.inputs[key].default_value = sss
                    break
            for key in ("Specular IOR Level", "Specular"):
                if key in bsdf.inputs:
                    bsdf.inputs[key].default_value = 0.35
                    break
    return m


def shade_smooth(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()
    # Auto smooth where available
    if hasattr(obj.data, "use_auto_smooth"):
        obj.data.use_auto_smooth = True
        obj.data.auto_smooth_angle = 0.785  # ~45 deg


def add_cube(name: str, loc: Vector, scale: Vector, material: bpy.types.Material, smooth: bool = False):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if smooth:
        shade_smooth(obj)
    return obj


def add_sphere(
    name: str,
    loc: Vector,
    scale: Vector,
    material: bpy.types.Material,
    seg: int = 16,
    rings: int = 10,
):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=0.5, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    shade_smooth(obj)
    return obj


def add_cyl(
    name: str,
    loc: Vector,
    scale: Vector,
    material: bpy.types.Material,
    verts: int = 16,
    rot: Euler | None = None,
):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=0.5, depth=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    if rot is not None:
        obj.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(material)
    shade_smooth(obj)
    return obj


def add_cone(name: str, loc: Vector, scale: Vector, material: bpy.types.Material, verts: int = 12):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=0.5, radius2=0.0, depth=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    shade_smooth(obj)
    return obj


def join_named(objects: list[bpy.types.Object], name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    joined = bpy.context.active_object
    joined.name = name
    shade_smooth(joined)
    return joined


def build_meshes() -> tuple[bpy.types.Object, bpy.types.Object]:
    # Palette — slightly richer TR2-ish read
    skin = mat("Skin", (0.90, 0.72, 0.58, 1.0), rough=0.55, sss=0.12)
    skin_shadow = mat("SkinShadow", (0.78, 0.58, 0.48, 1.0), rough=0.65, sss=0.08)
    hair = mat("Hair", (0.18, 0.09, 0.04, 1.0), rough=0.9)
    teal = mat("TankTeal", (0.12, 0.58, 0.62, 1.0), rough=0.45)
    teal_dark = mat("TankDark", (0.08, 0.38, 0.42, 1.0), rough=0.5)
    shorts = mat("Shorts", (0.32, 0.18, 0.10, 1.0), rough=0.82)
    boots = mat("Boots", (0.14, 0.09, 0.06, 1.0), rough=0.7)
    boot_sole = mat("BootSole", (0.08, 0.07, 0.06, 1.0), rough=0.95)
    belt = mat("Belt", (0.42, 0.28, 0.12, 1.0), rough=0.55, metallic=0.15)
    metal = mat("Metal", (0.55, 0.52, 0.45, 1.0), rough=0.35, metallic=0.65)
    pack = mat("Pack", (0.25, 0.18, 0.10, 1.0), rough=0.85)
    eye_w = mat("EyeWhite", (0.95, 0.95, 0.94, 1.0), rough=0.25)
    eye_i = mat("Iris", (0.18, 0.42, 0.62, 1.0), rough=0.2)

    body: list[bpy.types.Object] = []
    head: list[bpy.types.Object] = []

    # --- Legs: longer, tapered athletic ---
    body += [
        add_cyl("ThighL", Vector((-0.11, 0.0, 0.78)), Vector((0.15, 0.15, 0.48)), skin, 18),
        add_cyl("ThighR", Vector((0.11, 0.0, 0.78)), Vector((0.15, 0.15, 0.48)), skin, 18),
        add_sphere("KneeL", Vector((-0.11, 0.03, 0.52)), Vector((0.11, 0.1, 0.1)), skin_shadow, 12, 8),
        add_sphere("KneeR", Vector((0.11, 0.03, 0.52)), Vector((0.11, 0.1, 0.1)), skin_shadow, 12, 8),
        add_cyl("ShinL", Vector((-0.11, 0.03, 0.32)), Vector((0.105, 0.105, 0.36)), skin, 16),
        add_cyl("ShinR", Vector((0.11, 0.03, 0.32)), Vector((0.105, 0.105, 0.36)), skin, 16),
        # Boots with sole plate + cuff
        add_cube("BootL", Vector((-0.11, 0.07, 0.1)), Vector((0.15, 0.3, 0.14)), boots),
        add_cube("BootR", Vector((0.11, 0.07, 0.1)), Vector((0.15, 0.3, 0.14)), boots),
        add_cube("SoleL", Vector((-0.11, 0.08, 0.03)), Vector((0.16, 0.32, 0.04)), boot_sole),
        add_cube("SoleR", Vector((0.11, 0.08, 0.03)), Vector((0.16, 0.32, 0.04)), boot_sole),
        add_cyl("CuffL", Vector((-0.11, 0.01, 0.2)), Vector((0.13, 0.13, 0.1)), boots, 14),
        add_cyl("CuffR", Vector((0.11, 0.01, 0.2)), Vector((0.13, 0.13, 0.1)), boots, 14),
    ]

    # --- Hips / shorts (shorter, more defined) ---
    body += [
        add_sphere("Pelvis", Vector((0.0, 0.0, 1.02)), Vector((0.34, 0.22, 0.2)), shorts, 14, 10),
        add_cube("ShortL", Vector((-0.11, 0.0, 0.95)), Vector((0.17, 0.17, 0.14)), shorts),
        add_cube("ShortR", Vector((0.11, 0.0, 0.95)), Vector((0.17, 0.17, 0.14)), shorts),
        add_cyl("Belt", Vector((0.0, 0.0, 1.1)), Vector((0.36, 0.22, 0.06)), belt, 16),
        add_cube("Buckle", Vector((0.0, 0.12, 1.1)), Vector((0.08, 0.04, 0.06)), metal),
        add_cube("Holster", Vector((0.2, 0.04, 1.02)), Vector((0.07, 0.1, 0.18)), pack),
        add_cube("HolsterStrap", Vector((0.18, 0.0, 1.12)), Vector((0.04, 0.08, 0.12)), belt),
    ]

    # --- Midriff skin + teal tank (TR silhouette) ---
    body += [
        add_cyl("Waist", Vector((0.0, 0.0, 1.18)), Vector((0.24, 0.16, 0.12)), skin, 16),
        add_sphere("TorsoCore", Vector((0.0, 0.01, 1.38)), Vector((0.32, 0.2, 0.36)), teal, 16, 12),
        add_sphere("Chest", Vector((0.0, 0.05, 1.48)), Vector((0.34, 0.18, 0.22)), teal, 14, 10),
        add_cube("TankHem", Vector((0.0, 0.02, 1.24)), Vector((0.3, 0.18, 0.05)), teal_dark),
        # Straps over shoulders
        add_cube("StrapL", Vector((-0.12, 0.02, 1.58)), Vector((0.06, 0.08, 0.2)), teal_dark),
        add_cube("StrapR", Vector((0.12, 0.02, 1.58)), Vector((0.06, 0.08, 0.2)), teal_dark),
        add_sphere("ShoulderL", Vector((-0.22, 0.0, 1.56)), Vector((0.13, 0.12, 0.11)), skin, 12, 8),
        add_sphere("ShoulderR", Vector((0.22, 0.0, 1.56)), Vector((0.13, 0.12, 0.11)), skin, 12, 8),
    ]

    # --- Arms ---
    body += [
        add_cyl("UpperArmL", Vector((-0.3, 0.0, 1.36)), Vector((0.085, 0.085, 0.3)), skin, 14),
        add_cyl("UpperArmR", Vector((0.3, 0.0, 1.36)), Vector((0.085, 0.085, 0.3)), skin, 14),
        add_sphere("ElbowL", Vector((-0.33, 0.03, 1.18)), Vector((0.08, 0.08, 0.08)), skin_shadow, 10, 6),
        add_sphere("ElbowR", Vector((0.33, 0.03, 1.18)), Vector((0.08, 0.08, 0.08)), skin_shadow, 10, 6),
        add_cyl("ForeArmL", Vector((-0.35, 0.05, 1.02)), Vector((0.07, 0.07, 0.26)), skin, 14),
        add_cyl("ForeArmR", Vector((0.35, 0.05, 1.02)), Vector((0.07, 0.07, 0.26)), skin, 14),
        add_sphere("HandL", Vector((-0.37, 0.08, 0.86)), Vector((0.09, 0.07, 0.1)), skin, 10, 6),
        add_sphere("HandR", Vector((0.37, 0.08, 0.86)), Vector((0.09, 0.07, 0.1)), skin, 10, 6),
    ]

    # --- Backpack ---
    body += [
        add_cube("Backpack", Vector((0.0, -0.17, 1.38)), Vector((0.26, 0.12, 0.3)), pack),
        add_cube("PackFlap", Vector((0.0, -0.22, 1.52)), Vector((0.24, 0.08, 0.08)), belt),
        add_cube("PackBuckle", Vector((0.0, -0.24, 1.48)), Vector((0.06, 0.03, 0.04)), metal),
        add_cube("StrapBackL", Vector((-0.12, -0.08, 1.5)), Vector((0.04, 0.1, 0.22)), pack),
        add_cube("StrapBackR", Vector((0.12, -0.08, 1.5)), Vector((0.04, 0.1, 0.22)), pack),
    ]

    body += [add_cyl("Neck", Vector((0.0, 0.0, 1.64)), Vector((0.08, 0.08, 0.1)), skin, 12)]

    # --- Head (FP-hidden group) ---
    head += [
        add_sphere("Head", Vector((0.0, 0.02, 1.8)), Vector((0.19, 0.2, 0.23)), skin, 18, 12),
        add_sphere("Jaw", Vector((0.0, 0.04, 1.7)), Vector((0.14, 0.12, 0.1)), skin_shadow, 12, 8),
        add_sphere("EyeWhiteL", Vector((-0.055, 0.11, 1.82)), Vector((0.045, 0.028, 0.03)), eye_w, 10, 6),
        add_sphere("EyeWhiteR", Vector((0.055, 0.11, 1.82)), Vector((0.045, 0.028, 0.03)), eye_w, 10, 6),
        add_sphere("IrisL", Vector((-0.055, 0.125, 1.82)), Vector((0.022, 0.015, 0.02)), eye_i, 8, 6),
        add_sphere("IrisR", Vector((0.055, 0.125, 1.82)), Vector((0.022, 0.015, 0.02)), eye_i, 8, 6),
        add_sphere("HairCap", Vector((0.0, -0.02, 1.88)), Vector((0.21, 0.22, 0.18)), hair, 14, 10),
        add_cube("Bangs", Vector((0.0, 0.1, 1.88)), Vector((0.17, 0.06, 0.08)), hair),
        add_cube("SideL", Vector((-0.12, 0.06, 1.78)), Vector((0.05, 0.08, 0.12)), hair),
        add_cube("SideR", Vector((0.12, 0.06, 1.78)), Vector((0.05, 0.08, 0.12)), hair),
    ]
    # Braid: tapered spheres
    for i, z in enumerate([1.72, 1.58, 1.44, 1.3, 1.16, 1.04, 0.94]):
        t = i / 6.0
        s = 0.075 - t * 0.03
        x = 0.07 + t * 0.06
        y = -0.12 - t * 0.12
        head.append(add_sphere(f"Braid{i}", Vector((x, y, z)), Vector((s, s, s * 1.15)), hair, 10, 6))
    head.append(add_cube("BraidTip", Vector((0.14, -0.26, 0.88)), Vector((0.045, 0.045, 0.07)), hair))
    head.append(add_sphere("BraidBand", Vector((0.09, -0.14, 1.55)), Vector((0.08, 0.08, 0.05)), teal, 10, 6))

    return join_named(body, "Body"), join_named(head, "Head_FP_Hide")


def create_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "Armature"
    eb = arm_obj.data.edit_bones

    root = eb[0]
    root.name = "Root"
    root.head, root.tail = Vector((0, 0, 0)), Vector((0, 0, 0.12))

    def add(name: str, parent: str | None, head: Vector, tail: Vector):
        b = eb.new(name)
        b.head, b.tail = head, tail
        if parent:
            b.parent = eb[parent]
            b.use_connect = False
        return b

    add("Hips", "Root", Vector((0, 0, 0.98)), Vector((0, 0, 1.12)))
    add("Spine", "Hips", Vector((0, 0, 1.12)), Vector((0, 0, 1.32)))
    add("Chest", "Spine", Vector((0, 0, 1.32)), Vector((0, 0, 1.55)))
    add("Neck", "Chest", Vector((0, 0, 1.55)), Vector((0, 0, 1.68)))
    add("Head", "Neck", Vector((0, 0, 1.68)), Vector((0, 0, 1.92)))
    add("UpperArm_L", "Chest", Vector((-0.22, 0, 1.56)), Vector((-0.32, 0.02, 1.25)))
    add("LowerArm_L", "UpperArm_L", Vector((-0.32, 0.02, 1.25)), Vector((-0.37, 0.06, 0.9)))
    add("UpperArm_R", "Chest", Vector((0.22, 0, 1.56)), Vector((0.32, 0.02, 1.25)))
    add("LowerArm_R", "UpperArm_R", Vector((0.32, 0.02, 1.25)), Vector((0.37, 0.06, 0.9)))
    add("Thigh_L", "Hips", Vector((-0.11, 0, 0.98)), Vector((-0.11, 0.02, 0.55)))
    add("Calf_L", "Thigh_L", Vector((-0.11, 0.02, 0.55)), Vector((-0.11, 0.05, 0.12)))
    add("Thigh_R", "Hips", Vector((0.11, 0, 0.98)), Vector((0.11, 0.02, 0.55)))
    add("Calf_R", "Thigh_R", Vector((0.11, 0.02, 0.55)), Vector((0.11, 0.05, 0.12)))
    add("Braid_0", "Head", Vector((0.08, -0.1, 1.72)), Vector((0.09, -0.13, 1.5)))
    add("Braid_1", "Braid_0", Vector((0.09, -0.13, 1.5)), Vector((0.11, -0.17, 1.25)))
    add("Braid_2", "Braid_1", Vector((0.11, -0.17, 1.25)), Vector((0.13, -0.22, 1.0)))
    add("Braid_3", "Braid_2", Vector((0.13, -0.22, 1.0)), Vector((0.14, -0.26, 0.88)))

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def parent_with_height_weights(mesh_obj: bpy.types.Object, arm_obj: bpy.types.Object, is_head: bool) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type="ARMATURE_NAME")

    while mesh_obj.vertex_groups:
        mesh_obj.vertex_groups.remove(mesh_obj.vertex_groups[0])

    bone_names = [b.name for b in arm_obj.data.bones]
    groups = {n: mesh_obj.vertex_groups.new(name=n) for n in bone_names}

    # Height-band skinning (blockout-quality, better than single bone)
    for v in mesh_obj.data.vertices:
        z = v.co.z
        x = v.co.x
        if is_head:
            if z > 1.55:
                groups["Head"].add([v.index], 1.0, "REPLACE")
            elif z > 1.35:
                groups["Braid_0"].add([v.index], 1.0, "REPLACE")
            elif z > 1.15:
                groups["Braid_1"].add([v.index], 1.0, "REPLACE")
            elif z > 0.95:
                groups["Braid_2"].add([v.index], 1.0, "REPLACE")
            else:
                groups["Braid_3"].add([v.index], 1.0, "REPLACE")
            continue

        if z >= 1.55:
            groups["Neck"].add([v.index], 1.0, "REPLACE")
        elif z >= 1.32:
            groups["Chest"].add([v.index], 1.0, "REPLACE")
        elif z >= 1.12:
            groups["Spine"].add([v.index], 1.0, "REPLACE")
        elif z >= 0.95:
            groups["Hips"].add([v.index], 1.0, "REPLACE")
        elif z >= 0.52:
            # Thighs by side
            if x < -0.02:
                groups["Thigh_L"].add([v.index], 1.0, "REPLACE")
            elif x > 0.02:
                groups["Thigh_R"].add([v.index], 1.0, "REPLACE")
            else:
                groups["Hips"].add([v.index], 1.0, "REPLACE")
        else:
            if x < -0.02:
                groups["Calf_L"].add([v.index], 1.0, "REPLACE")
            elif x > 0.02:
                groups["Calf_R"].add([v.index], 1.0, "REPLACE")
            else:
                groups["Hips"].add([v.index], 1.0, "REPLACE")

        # Arms override by lateral + height
        if z >= 0.85 and z <= 1.6 and abs(x) > 0.22:
            if x < 0:
                if z >= 1.2:
                    groups["UpperArm_L"].add([v.index], 1.0, "REPLACE")
                else:
                    groups["LowerArm_L"].add([v.index], 1.0, "REPLACE")
            else:
                if z >= 1.2:
                    groups["UpperArm_R"].add([v.index], 1.0, "REPLACE")
                else:
                    groups["LowerArm_R"].add([v.index], 1.0, "REPLACE")

    mod = next((m for m in mesh_obj.modifiers if m.type == "ARMATURE"), None)
    if mod is None:
        mod = mesh_obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm_obj
    mod.use_vertex_groups = True


def apply_object(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def normalize_height(arm_obj: bpy.types.Object, target: float = 1.72) -> None:
    meshes = [c for c in arm_obj.children_recursive if c.type == "MESH"]
    if not meshes:
        return
    min_z, max_z = 1e9, -1e9
    for m in meshes:
        for corner in m.bound_box:
            z = (m.matrix_world @ Vector(corner)).z
            min_z = min(min_z, z)
            max_z = max(max_z, z)
    height = max_z - min_z
    if height < 0.01:
        return
    s = target / height
    arm_obj.scale = (s, s, s)
    apply_object(arm_obj)
    min_z = 1e9
    for m in [c for c in arm_obj.children_recursive if c.type == "MESH"]:
        for corner in m.bound_box:
            z = (m.matrix_world @ Vector(corner)).z
            min_z = min(min_z, z)
    arm_obj.location.z -= min_z
    apply_object(arm_obj)


def make_idle(arm_obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    pose = arm_obj.pose

    action = bpy.data.actions.new(name="Idle")
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = action

    scene = bpy.context.scene
    scene.render.fps = 24
    scene.frame_start = 1
    scene.frame_end = 48

    def key_bone(bone_name: str, keys: list[tuple[int, Euler]]) -> None:
        if bone_name not in pose.bones:
            return
        pb = pose.bones[bone_name]
        pb.rotation_mode = "XYZ"
        for frame, eul in keys:
            scene.frame_set(frame)
            pb.rotation_euler = eul
            pb.keyframe_insert(data_path="rotation_euler", frame=frame)

    key_bone("Chest", [(1, Euler((0, 0, 0))), (24, Euler((0.055, 0, 0))), (48, Euler((0, 0, 0)))])
    key_bone("Spine", [(1, Euler((0, 0, 0))), (24, Euler((0.03, 0, 0))), (48, Euler((0, 0, 0)))])
    key_bone("Hips", [(1, Euler((0, 0, -0.035))), (24, Euler((0, 0, 0.035))), (48, Euler((0, 0, -0.035)))])
    key_bone("Head", [(1, Euler((0.01, 0, 0))), (24, Euler((-0.01, 0.02, 0))), (48, Euler((0.01, 0, 0)))])
    key_bone("UpperArm_L", [(1, Euler((0.06, 0, 0.05))), (24, Euler((0.09, 0, 0.03))), (48, Euler((0.06, 0, 0.05)))])
    key_bone("UpperArm_R", [(1, Euler((0.06, 0, -0.05))), (24, Euler((0.09, 0, -0.03))), (48, Euler((0.06, 0, -0.05)))])
    for i, amp in enumerate((0.05, 0.07, 0.1, 0.12)):
        key_bone(
            f"Braid_{i}",
            [(1, Euler((0, amp * 0.4, 0))), (24, Euler((0, -amp, 0))), (48, Euler((0, amp * 0.4, 0)))],
        )

    if hasattr(action, "use_cyclic"):
        action.use_cyclic = True
    if hasattr(action, "use_frame_range"):
        action.use_frame_range = True
        action.frame_start = 1
        action.frame_end = 48

    bpy.ops.object.mode_set(mode="OBJECT")
    scene.frame_set(1)


def export_glb(path: Path) -> None:
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
    print(f"Exported: {path}")


def main() -> None:
    clear_scene()
    body, head = build_meshes()
    arm = create_armature()
    parent_with_height_weights(body, arm, is_head=False)
    parent_with_height_weights(head, arm, is_head=True)
    normalize_height(arm, 1.72)
    make_idle(arm)
    export_glb(OUT_GLB)
    print("Done. Upgraded TR2-style body: smoother forms, multi-bone skin, richer materials.")


if __name__ == "__main__":
    main()
