#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "environment_blender.h"
#include "environment_volume.h"

using namespace godot;

static EnvironmentBlender *_my_singleton;

void gdextension_initialize(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		ClassDB::register_class<EnvironmentBlender>();
		ClassDB::register_class<EnvironmentVolume>();

		_my_singleton = memnew(EnvironmentBlender);
		Engine::get_singleton()->register_singleton("EnvironmentBlender", EnvironmentBlender::get_singleton());
	}
}

void gdextension_terminate(ModuleInitializationLevel p_level) {
	if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		Engine::get_singleton()->unregister_singleton("EnvironmentBlender");
		memdelete(_my_singleton);
	}
}

extern "C" {
GDExtensionBool GDE_EXPORT gdextension_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(gdextension_initialize);
	init_obj.register_terminator(gdextension_terminate);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
