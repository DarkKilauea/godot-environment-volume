# Copyright © 2022 Josh Jones - MIT License
# See `LICENSE.md` included in the source distribution for details.
# Contains each environment volume itself, which indicates what environment to apply
# to cameras that enter its bounds.
tool
class_name EnvironmentVolume
extends Spatial


# Size of the cuboid region this volume controls
export var extents: Vector3 = Vector3(1, 1, 1) setget _set_extents;

# Environment to apply to cameras that enter this volume
export var environment: Environment;

# Calculated bounding box for this region's effect, in local coordinates.
var bounds := AABB();


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			EnvironmentBlender.register_environment_volume(self);
			_update_bounds();
		NOTIFICATION_EXIT_TREE:
			EnvironmentBlender.unregister_environment_volume(self);


func _set_extents(new_extents: Vector3) -> void:
	if (extents == new_extents):
		return;
	
	extents = new_extents;
	_update_bounds();
	property_list_changed_notify();
	update_gizmo();


func _update_bounds():
	bounds = AABB(-extents, extents * 2);
