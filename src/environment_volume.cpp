#include "environment_volume.h"

#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void EnvironmentVolume::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_size"), &EnvironmentVolume::get_size);
	ClassDB::bind_method(D_METHOD("set_size", "size"), &EnvironmentVolume::set_size);

	ClassDB::bind_method(D_METHOD("get_environment"), &EnvironmentVolume::get_environment);
	ClassDB::bind_method(D_METHOD("set_environment", "environment"), &EnvironmentVolume::set_environment);

	ClassDB::bind_method(D_METHOD("get_blend_time"), &EnvironmentVolume::get_blend_time);
	ClassDB::bind_method(D_METHOD("set_blend_time", "blend_time"), &EnvironmentVolume::set_blend_time);

	ClassDB::bind_method(D_METHOD("get_blend_distance"), &EnvironmentVolume::get_blend_distance);
	ClassDB::bind_method(D_METHOD("set_blend_distance", "blend_distance"), &EnvironmentVolume::set_blend_distance);

	ADD_PROPERTY(PropertyInfo(Variant::VECTOR3, "size"), "set_size", "get_size");
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "environment", PROPERTY_HINT_RESOURCE_TYPE, "Environment"), "set_environment", "get_environment");
	ADD_GROUP("Blend", "blend_");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "blend_time", PROPERTY_HINT_RANGE, "0,4,0.1,or_greater"), "set_blend_time", "get_blend_time");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "blend_distance", PROPERTY_HINT_RANGE, "0,4,0.1,or_greater"), "set_blend_distance", "get_blend_distance");
}

void EnvironmentVolume::_clear_cameras_from_blender() {
	for (auto &kvp : camera_blend_strengths) {
		// Remove from blender's list of cameras
	}
}

void EnvironmentVolume::_update_cameras_in_blender() {
	for (auto &kvp : camera_blend_strengths) {
		// Update all cameras in blender
	}
}

void EnvironmentVolume::_update_bounds() {
	inner_bounds = AABB(-size, size * 2.0);
	outer_bounds = inner_bounds.grow(blend_distance);
}

TypedArray<Camera3D> EnvironmentVolume::_find_cameras() {
	// Pull all cameras the user has marked to be affected
	auto cameras = get_tree()->get_nodes_in_group("EnvironmentVolumeCameras");

	if (cameras.is_empty()) {
		auto results = TypedArray<Camera3D>();
		results.push_back(get_viewport()->get_camera_3d());
		return results;
	}

	return cameras;
}

Vector3 EnvironmentVolume::_get_closest_point_in_aabb(const AABB &p_aabb, const Vector3 &p_point) {
	return Vector3();
}

EnvironmentVolume::EnvironmentVolume() {
}

EnvironmentVolume::~EnvironmentVolume() {
}

void EnvironmentVolume::_exit_tree() {
	_clear_cameras_from_blender();
}

void EnvironmentVolume::_process(double delta) {
}

void EnvironmentVolume::set_size(const Vector3 &p_size) {
	if (p_size.is_equal_approx(size)) {
		return;
	}

	size = p_size;

	_update_bounds();

	notify_property_list_changed();
	update_gizmos();
}

void EnvironmentVolume::set_environment(const Ref<Environment> &p_environment) {
	if (p_environment == environment) {
		return;
	}

	_clear_cameras_from_blender();

	environment = p_environment;

	_update_cameras_in_blender();
}

void EnvironmentVolume::set_blend_time(real_t p_blend_time) {
	if (Math::is_equal_approx(p_blend_time, blend_time)) {
		return;
	}

	blend_time = p_blend_time;
}

void EnvironmentVolume::set_blend_distance(real_t p_blend_distance) {
	if (Math::is_equal_approx(p_blend_distance, blend_distance)) {
		return;
	}

	blend_distance = p_blend_distance;

	_update_bounds();
	update_gizmos();
}
