# Copyright © 2022 Josh Jones - MIT License
# See `LICENSE.md` included in the source distribution for details.
# Contains the central manager for handling the environment updates for all affected cameras.
tool
extends Node


# Set of cameras and the environments with their weights that we are blending.
# Format: { camera: { environment: weight } }
var camera_blended_environments := {};

# Cache for the generated environments for each camera.
# This reduces the cost of creating the environments per frame.
# Format: { camera: environment }
var camera_environment_cache := {};

# The original environment for each camera so we can restore their state.
# Format: { camera: environment }
var camera_original_environments := {};


func _process(delta: float) -> void:
	for _camera in camera_blended_environments:
		var camera: Camera = _camera;
		var world := camera.get_world();
		
		# Default default environment to use as a base for blending
		var base_env: Environment = world.environment;
		if !base_env:
			base_env = world.fallback_environment;
		
		if !base_env:
			base_env = Environment.new();
		
		# Loop over each environment and blend them.
		var environments: Dictionary = camera_blended_environments[camera];
		for _env in environments.keys():
			var environment: Environment = _env;
			var weight: float = environments[environment];
			
			base_env = _environment_lerp(base_env, environment, weight);
		
		camera.environment = base_env;


# Update the environment for a camera, blending with other requests by a weight.
# @param camera Camera to update the environment for.
# @param environment Desired environment settings at full weight.
# @param weight Strength of the provided environment when blending.  0.0 has no effect and 1.0 has full effect.
func update_environment_for_camera(camera: Camera, environment: Environment, weight: float) -> void:
	var env_set: Dictionary;
	if camera_blended_environments.has(camera):
		env_set = camera_blended_environments[camera];
	else:
		env_set = Dictionary();
		camera_blended_environments[camera] = env_set;
		
		camera_original_environments[camera] = camera.environment;
		camera_environment_cache[camera] = _build_default_environment();
		print_debug("Add camera: %s env: %s weight: %s" % [ camera, environment, weight ]);
	
	env_set[environment] = weight;


# Remove a previous request to blend environments for a camera.
# If no requests remain for that camera, it will revert to its original settings.
func remove_environment_for_camera(camera: Camera, environment: Environment) -> void:
	if !camera_blended_environments.has(camera):
		push_warning("Could not find camera %s to remove" % camera);
	
	var env_set: Dictionary = camera_blended_environments[camera];
	env_set.erase(environment);
	
	if env_set.empty():
		camera.environment = camera_original_environments[camera];
		
		camera_original_environments.erase(camera);
		camera_blended_environments.erase(camera);
		camera_environment_cache.erase(camera);
		
		print_debug("Remove camera: %s env: %s" % [ camera, environment ]);


func _build_default_environment() -> Environment:
	return Environment.new();


func _environment_lerp(source: Environment, dest: Environment, blend_weight: float) -> Environment:
	return dest;
