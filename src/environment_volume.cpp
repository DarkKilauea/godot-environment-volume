#include "environment_volume.h"

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

EnvironmentVolume::EnvironmentVolume() {
}

EnvironmentVolume::~EnvironmentVolume() {
}

void EnvironmentVolume::_ready() {
}

void EnvironmentVolume::_process(double delta) {
}

void EnvironmentVolume::set_size(const Vector3 &p_size) {
	if (p_size.is_equal_approx(size)) {
		return;
	}

	size = p_size;
}

void EnvironmentVolume::set_environment(const Ref<Environment> &p_environment) {
	if (p_environment == environment) {
		return;
	}

	environment = p_environment;
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
}
