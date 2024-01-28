#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

class EnvironmentBlender : public Object {
	GDCLASS(EnvironmentBlender, Object);

	static EnvironmentBlender *singleton;

protected:
	static void _bind_methods();

public:
	static EnvironmentBlender *get_singleton();

	EnvironmentBlender();
	~EnvironmentBlender();
};
