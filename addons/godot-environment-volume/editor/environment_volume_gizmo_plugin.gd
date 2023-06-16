@tool
# Copyright © 2022 Josh Jones - MIT License
# See `LICENSE.md` included in the source distribution for details.
# Contains the editor gizmo for the environment region
extends EditorNode3DGizmoPlugin

# Used to allow undo/redo of changes made via gizmo
var undo_redo: EditorUndoRedoManager;


func _init(p_undo_redo: EditorUndoRedoManager) -> void:
	undo_redo = p_undo_redo;
	
	var gizmo_color := Color(0.5, 0.6, 1.0);
	create_material("material", gizmo_color);
	
	gizmo_color.a = 0.5;
	create_material("material_internal", gizmo_color);
	
	# TODO: create_icon_material
	create_handle_material("handles");


func has_gizmo(spatial: Node3D) -> bool:
	return spatial is EnvironmentVolume;


func get_name() -> String:
	return "EnvironmentVolume";


func redraw(gizmo: EditorNode3DGizmo) -> void:
	var volume := gizmo.get_node_3d() as EnvironmentVolume;
	var material := get_material("material", gizmo);
	var material_internal := get_material("material_internal", gizmo);
	var material_handles := get_material("handles", gizmo);
	
	gizmo.clear();
	
	var inner_lines := PackedVector3Array();
	var inner_aabb := volume.inner_bounds;
	
	for i in range(0, 12):
		var pair := _aabb_get_edge(inner_aabb, i);
		inner_lines.append_array(pair);
	
	gizmo.add_lines(inner_lines, material);

	if !is_zero_approx(volume.blend_distance):
		var outer_aabb := volume.outer_bounds;
		var outer_lines := PackedVector3Array();

		for i in range(0, 12):
			var pair := _aabb_get_edge(outer_aabb, i);
			outer_lines.append_array(pair);
		
		gizmo.add_lines(outer_lines, material_internal);
	
	var handles := PackedVector3Array();
	for i in range(0, 3):
		var handle_pos := Vector3();
		handle_pos[i] = inner_aabb.position[i] + inner_aabb.size[i];
		handles.append(handle_pos);
	
	gizmo.add_handles(handles, material_handles, []);


func _get_handle_name(gizmo: EditorNode3DGizmo, index: int, secondary: bool) -> String:
	match index:
		0:
			return "Extents X";
		1:
			return "Extents Y";
		2:
			return "Extents Z";
	
	return "";


func _get_handle_value(gizmo: EditorNode3DGizmo, index: int, secondary: bool):
	var volume := gizmo.get_node_3d() as EnvironmentVolume;
	return volume.size;


func set_handle(gizmo: EditorNode3DGizmo, index: int, camera: Camera3D, point: Vector2) -> void:
	var volume := gizmo.get_node_3d() as EnvironmentVolume;
	
	var gt := volume.get_global_transform();
	var gi := gt.affine_inverse();
	
	var size = volume.size;
	
	var ray_from = camera.project_ray_origin(point);
	var ray_dir = camera.project_ray_normal(point);
	
	var sg = [ gi * (ray_from), gi * (ray_from + ray_dir * camera.far) ];
	
	var axis = Vector3();
	axis[index] = 1.0;
	
	var r := Geometry3D.get_closest_points_between_segments(Vector3(), axis * camera.far, sg[0], sg[1]);
	var d := r[0][index];
	
	if (d < 0.001):
		d = 0.001;
	
	size[index] = d;
	volume.size = size;


func _commit_handle(gizmo: EditorNode3DGizmo, index: int, secondary: bool, restore, cancel: bool = false) -> void:
	var volume := gizmo.get_node_3d() as EnvironmentVolume;
	
	if cancel:
		volume.size = restore;
		return;
	
	undo_redo.create_action("Change Extents");
	undo_redo.add_do_property(volume, "size", volume.size);
	undo_redo.add_undo_property(volume, "size", restore);
	undo_redo.commit_action();


# Taken from core/math/aabb.cpp
func _aabb_get_edge(aabb: AABB, edge: int) -> Array:
	assert(edge >= 0);
	assert(edge < 12);
	
	var position := aabb.position;
	var size := aabb.size;
	
	match edge:
		0:
			return [
				Vector3(position.x + size.x, position.y, position.z),
				Vector3(position.x, position.y, position.z)
			];
		1:
			return [
				Vector3(position.x + size.x, position.y, position.z + size.z),
				Vector3(position.x + size.x, position.y, position.z)
			];
		2:
			return [
				Vector3(position.x, position.y, position.z + size.z),
				Vector3(position.x + size.x, position.y, position.z + size.z)
			];
		3:
			return [
				Vector3(position.x, position.y, position.z),
				Vector3(position.x, position.y, position.z + size.z)
			];
		4:
			return [
				Vector3(position.x, position.y + size.y, position.z),
				Vector3(position.x + size.x, position.y + size.y, position.z)
			];
		5:
			return [
				Vector3(position.x + size.x, position.y + size.y, position.z),
				Vector3(position.x + size.x, position.y + size.y, position.z + size.z)
			];
		6:
			return [
				Vector3(position.x + size.x, position.y + size.y, position.z + size.z),
				Vector3(position.x, position.y + size.y, position.z + size.z)
			];
		7:
			return [
				Vector3(position.x, position.y + size.y, position.z + size.z),
				Vector3(position.x, position.y + size.y, position.z)
			];
		8:
			return [
				Vector3(position.x, position.y, position.z + size.z),
				Vector3(position.x, position.y + size.y, position.z + size.z)
			];
		9:
			return [
				Vector3(position.x, position.y, position.z),
				Vector3(position.x, position.y + size.y, position.z)
			];
		10:
			return [
				Vector3(position.x + size.x, position.y, position.z),
				Vector3(position.x + size.x, position.y + size.y, position.z)
			];
		11:
			return [
				Vector3(position.x + size.x, position.y, position.z + size.z),
				Vector3(position.x + size.x, position.y + size.y, position.z + size.z)
			];
	
	return [];
