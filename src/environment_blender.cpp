#include "environment_blender.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

EnvironmentBlender *EnvironmentBlender::singleton = nullptr;

void EnvironmentBlender::_bind_methods() {
	//ClassDB::bind_method(D_METHOD("hello_singleton"), &MySingleton::hello_singleton);
}

EnvironmentBlender *EnvironmentBlender::get_singleton() {
	return singleton;
}

EnvironmentBlender::EnvironmentBlender() {
	ERR_FAIL_COND(singleton != nullptr);
	singleton = this;
}

EnvironmentBlender::~EnvironmentBlender() {
	ERR_FAIL_COND(singleton != this);
	singleton = nullptr;
}
