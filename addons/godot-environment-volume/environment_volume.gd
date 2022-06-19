# Copyright © 2022 Josh Jones - MIT License
# See `LICENSE.md` included in the source distribution for details.
# Contains each environment volume itself, which indicates what environment to apply
# to cameras that enter its bounds.
tool
class_name EnvironmentVolume, "environment_volume.svg"
extends Spatial


# Size of the cuboid region this volume controls
var extents: Vector3 = Vector3(1, 1, 1) setget _set_extents;

# Environment to apply to cameras that enter this volume
var environment: Environment setget _set_environment;

# Time in seconds to blend to target strength.
# Target strength is controlled by blend_distance, allowing both to be mixed.
var blend_time: float = 0.0 setget _set_blend_time;

# Distance from the edge of the volume to start blending.
# Strength will linearly increase as the camera approaches the volume's edge.
var blend_distance: float = 0.0 setget _set_blend_distance;

# Calculated bounding box for this region's effect, in local coordinates.
# Within these bounds, the effect will be at full strength.
var inner_bounds := AABB();

# Calculated outer bounding box for this region's effect, in local coordinates.
# This is where the effect will start blending in from.
var outer_bounds := AABB();

# Cameras being updated by this volume.
# Format: { camera, current_blend_strength: float }
var _affected_cameras := {};


func _get_property_list() -> Array:
	return [
		{
			"name": "EnvironmentVolume",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY
		},
		{
			"name": "extents",
			"type": TYPE_VECTOR3,
			"usage": PROPERTY_USAGE_DEFAULT
		},
		{
			"name": "environment",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Environment"
		},
		{
			"name": "Blend",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": "blend_"
		},
		{
			"name": "blend_time",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,4,0.1,or_greater"
		},
		{
			"name": "blend_distance",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,4,0.1,or_greater"
		}
	]


func _process(delta: float) -> void:
	var global_outer_bounds: AABB = global_transform.xform(outer_bounds);
	var global_inner_bounds: AABB = global_transform.xform(inner_bounds);
	
	# For each camera we are tracking
	var cameras: Array = _find_cameras();
	for _camera in cameras:
		var camera: Camera = _camera;
		var camera_pos := camera.global_transform.origin;
		
		# This prevents errors in the editor...
		if !camera:
			continue;
		
		# If the camera is within our bounds, update it.
		if global_outer_bounds.has_point(camera_pos):
			var old_blend_strength := 0.0;
			if _affected_cameras.has(camera):
				old_blend_strength = _affected_cameras[camera];
			
			# Calculate our target strength based on our distance to the inner bounds.
			var target_blend_strength := 1.0;
			if !is_zero_approx(blend_distance):
				var ref_point := _get_closest_point_in_aabb(global_inner_bounds, camera_pos);
				var dist_to_inner := ref_point.distance_to(camera_pos);
				target_blend_strength = (blend_distance - dist_to_inner) / blend_distance;
			
			var new_blend_strength := target_blend_strength;
			if !is_zero_approx(blend_time):
				var time_step := (1.0 / blend_time) * delta;
				new_blend_strength = lerp(old_blend_strength, target_blend_strength, time_step);
			
			EnvironmentBlender.update_environment_for_camera(camera, environment, new_blend_strength);
			_affected_cameras[camera] = new_blend_strength;
		# Otherwise, if we were affecting it before, stop doing so.
		elif _affected_cameras.has(camera):
			var old_blend_strength := 0.0;
			if _affected_cameras.has(camera):
				old_blend_strength = _affected_cameras[camera];
			
			var new_blend_strength := 0.0;
			if !is_zero_approx(blend_time):
				var time_step := (1.0 / blend_time) * delta;
				new_blend_strength = lerp(old_blend_strength, 0.0, time_step);
				
				EnvironmentBlender.update_environment_for_camera(camera, environment, new_blend_strength);
				_affected_cameras[camera] = new_blend_strength;
			
			if is_zero_approx(new_blend_strength):
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


func _set_environment(new_environment: Environment) -> void:
	if environment == new_environment:
		return;
	
	# Clear previous environment.
	for camera in _affected_cameras.keys():
		EnvironmentBlender.remove_environment_for_camera(camera, environment);
	
	environment = new_environment;
	
	# Set new environment with the same strength as the previous environment had.
	for camera in _affected_cameras.keys():
		var blend: float = _affected_cameras[camera];
		EnvironmentBlender.update_environment_for_camera(camera, environment, blend);


func _set_extents(new_extents: Vector3) -> void:
	if extents == new_extents:
		return;
	
	extents = new_extents;
	
	_update_bounds();
	
	property_list_changed_notify();
	update_gizmo();


func _set_blend_time(new_blend_time: float) -> void:
	if is_equal_approx(blend_time, new_blend_time):
		return;
	
	blend_time = new_blend_time;


func _set_blend_distance(new_blend_distance: float) -> void:
	if is_equal_approx(blend_distance, new_blend_distance):
		return;
	
	blend_distance = new_blend_distance;
	
	_update_bounds();
	update_gizmo();


func _update_bounds():
	inner_bounds = AABB(-extents, extents * 2);
	outer_bounds = inner_bounds.grow(blend_distance);


func _find_cameras() -> Array:
	# Pull all cameras the user has marked to be affected
	var cameras := get_tree().get_nodes_in_group("EnvironmentVolumeCameras");
	
	# Fallback to grabbing the active camera in the root viewport.
	if cameras.empty():
		return [ get_viewport().get_camera() ];
	
	return cameras;


func _get_closest_point_in_aabb(aabb: AABB, point: Vector3) -> Vector3:
	var result := Vector3();
	for i in 3:
		if point[i] > aabb.end[i]:
			result[i] = aabb.end[i];
		elif point[i] < aabb.position[i]:
			result[i] = aabb.position[i];
		else:
			result[i] = point[i];
	
	return result;
