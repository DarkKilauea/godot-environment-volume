#pragma once

#include <godot_cpp/classes/camera3d.hpp>
#include <godot_cpp/classes/environment.hpp>
#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/hash_map.hpp>

using namespace godot;

class EnvironmentVolume : public Node3D {
	GDCLASS(EnvironmentVolume, Node3D);

	Vector3 size = Vector3(1, 1, 1);
	Ref<Environment> environment;
	real_t blend_time = 0.0;
	real_t blend_distance = 0.0;
	AABB inner_bounds;
	AABB outer_bounds;
	HashMap<Camera3D *, real_t> camera_blend_strengths;

protected:
	static void _bind_methods();
	void _clear_cameras_from_blender();
	void _update_cameras_in_blender();
	void _update_bounds();
	TypedArray<Camera3D> _find_cameras();
	Vector3 _get_closest_point_in_aabb(const AABB &p_aabb, const Vector3 &p_point);

public:
	EnvironmentVolume();
	~EnvironmentVolume();

	void _exit_tree() override;
	void _process(double delta) override;

	Vector3 get_size() const { return size; }
	void set_size(const Vector3 &p_size);

	Ref<Environment> get_environment() const { return environment; }
	void set_environment(const Ref<Environment> &p_environment);

	real_t get_blend_time() const { return blend_time; }
	void set_blend_time(real_t p_blend_time);

	real_t get_blend_distance() const { return blend_distance; }
	void set_blend_distance(real_t p_blend_distance);
};
