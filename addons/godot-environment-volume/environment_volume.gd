# Copyright © 2022 Josh Jones - MIT License
# See `LICENSE.md` included in the source distribution for details.
# Contains each environment volume itself, which indicates what environment to apply
# to cameras that enter its bounds.
tool
class_name EnvironmentVolume, "environment_volume.svg"
extends Spatial


## Size of the cuboid region this volume controls
export var extents: Vector3 = Vector3(1, 1, 1) setget _set_extents;

## Environment to apply to cameras that enter this volume
export var environment: Environment;

## Calculated bounding box for this region's effect, in local coordinates.
var local_bounds := AABB();

## Calculated bounding box for this region's effect, in global coordinates.
var global_bounds := AABB();

# Cameras being updated by this volume.
# This dictionary is being used as a set, only the keys matter.
var _affected_cameras := {};


func _ready() -> void:
	set_notify_transform(true);
	_update_local_bounds();
	_update_global_bounds();


func _process(delta: float) -> void:
	# For each camera we are tracking
	var cameras: Array = _find_cameras();
	for _camera in cameras:
		var camera: Camera = _camera;
		
		# This prevents errors in the editor...
		if !camera:
			continue;
		
		# If the camera is within our bounds, update it.
		if global_bounds.has_point(camera.global_transform.origin):
			_affected_cameras[camera] = true;
			EnvironmentBlender.update_environment_for_camera(camera, environment, 1.0);
		# Otherwise, if we were affecting it before, stop doing so.
		elif _affected_cameras.has(camera):
			EnvironmentBlender.remove_environment_for_camera(camera, environment);
			_affected_cameras.erase(camera);
	
	# Safety check for cameras that were taken out of the group or are no longer active.
	for _camera in _affected_cameras.keys():
		var camera: Camera = _camera;
		
		# Skip if we already processed this camera.
		if cameras.has(camera):
			continue;
		
		# If we didn't process it, it must be left over and should be removed.
		EnvironmentBlender.remove_environment_for_camera(camera, environment);
		_affected_cameras.erase(camera);


func _exit_tree() -> void:
	for camera in _affected_cameras.keys():
		EnvironmentBlender.remove_environment_for_camera(camera, environment);


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			_update_global_bounds();


func _set_extents(new_extents: Vector3) -> void:
	if (extents == new_extents):
		return;
	
	extents = new_extents;
	
	_update_local_bounds();
	_update_global_bounds();
	
	property_list_changed_notify();
	update_gizmo();


func _update_local_bounds():
	local_bounds = AABB(-extents, extents * 2);


func _update_global_bounds():
	if !is_inside_tree():
		return;
	
	global_bounds = global_transform.xform(local_bounds);


func _find_cameras() -> Array:
	# Pull all cameras the user has marked to be affected
	var cameras := get_tree().get_nodes_in_group("EnvironmentVolumeCameras");
	
	# Fallback to grabbing the active camera in the root viewport.
	if cameras.empty():
		return [ get_viewport().get_camera() ];
	
	return cameras;
