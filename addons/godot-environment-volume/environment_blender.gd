# Copyright © 2022 Josh Jones - MIT License
# See `LICENSE.md` included in the source distribution for details.
# Contains the central manager for handling the environment updates for all affected cameras.
@tool
extends Node


## Set of cameras and the environments with their weights that we are blending.
## Format: { camera: { environment: weight } }
var camera_blended_environments := {};

## Cache for the generated environments for each camera.
## This reduces the cost of creating the environments per frame.
## Format: { camera: environment }
var camera_environment_cache := {};

## The original environment for each camera so we can restore their state.
## Format: { camera: environment }
var camera_original_environments := {};


func _process(delta: float) -> void:
	for _camera in camera_blended_environments:
		var camera: Camera3D = _camera;
		var environments: Dictionary = camera_blended_environments[camera].duplicate();

		# Check if total weights add up to at least one.
		# If not, we need to inject a base environment to give something to blend from.
		var total_weight := 0.0;
		for weight in environments.values():
			total_weight += weight;

		if total_weight < 1.0:
			var base_env := _get_base_environment_for_camera(camera);
			var base_weight := 1.0 - total_weight;

			environments[base_env] = base_weight;
		
		# Blend environments
		var dest_env: Environment = camera_environment_cache[camera];
		_blend_environments(environments, dest_env);
		camera.environment = dest_env;


## Update the environment for a camera, blending with other requests by a weight.
## @param camera Camera to update the environment for.
## @param environment Desired environment settings at full weight.
## @param weight Strength of the provided environment when blending.  0.0 has no effect and 1.0 has full effect.
func update_environment_for_camera(camera: Camera3D, environment: Environment, weight: float) -> void:
	var env_set: Dictionary;
	if camera_blended_environments.has(camera):
		env_set = camera_blended_environments[camera];
	else:
		env_set = Dictionary();
		camera_blended_environments[camera] = env_set;
		
		camera_original_environments[camera] = camera.environment;
		camera_environment_cache[camera] = Environment.new();
	
	env_set[environment] = weight;


## Remove a previous request to blend environments for a camera.
## If no requests remain for that camera, it will revert to its original settings.
func remove_environment_for_camera(camera: Camera3D, environment: Environment) -> void:
	if !camera_blended_environments.has(camera):
		push_warning("Could not find camera %s to remove" % camera);
	
	var env_set: Dictionary = camera_blended_environments[camera];
	env_set.erase(environment);
	
	if env_set.is_empty():
		camera.environment = camera_original_environments[camera];
		
		camera_original_environments.erase(camera);
		camera_blended_environments.erase(camera);
		camera_environment_cache.erase(camera);


func _get_base_environment_for_camera(camera: Camera3D) -> Environment:
	# Check to see if the camera originally had an environment.
	if camera_original_environments[camera]:
		return camera_original_environments[camera];

	# If not, check the world.
	var world := camera.get_world_3d();
	if world.environment:
		return world.environment;
	
	# If not, check the fallback.
	if world.fallback_environment:
		return world.fallback_environment;
	
	# If not, use the default environment settings.
	return Environment.new();


func _get_highest_weight_value(objects: Dictionary, property: String):
	# Gather unique values for this property and compute the total weight.
	var unique_values := {};
	for object in objects:
		var weight: float = objects[object];
		var value = object.get_indexed(property);

		if !unique_values.has(value):
			unique_values[value] = 0.0;
		
		unique_values[value] += weight;

	# Figure out the value with the greatest total weight.
	var max_weight := 0.0;
	var final_value;
	for value in unique_values:
		var weight: float = unique_values[value];

		if weight > max_weight:
			max_weight = weight;
			final_value = value;
	
	return final_value;


func _get_highest_weight_class(objects: Dictionary, property: String) -> String:
	# Gather unique values for this property and compute the total weight.
	var unique_values := {};
	for object in objects:
		var weight: float = objects[object];
		var value: Object = object.get_indexed(property);
		var type: String;

		if !value:
			type = "";
		else:
			type = value.get_class();

		if !unique_values.has(type):
			unique_values[type] = 0.0;
		
		unique_values[type] += weight;

	# Figure out the value with the greatest total weight.
	var max_weight := 0.0;
	var final_type: String;
	for type in unique_values:
		var weight: float = unique_values[type];

		if weight > max_weight:
			max_weight = weight;
			final_type = type;
	
	return final_type;


func _weighted_average_float(objects: Dictionary, property: String) -> float:
	var total_weight := 0.0;
	var weighted_sum := 0.0;

	for object in objects:
		var weight: float = objects[object];

		total_weight += weight;
		weighted_sum += (object.get_indexed(property) * weight);
	
	return weighted_sum / total_weight;


func _weighted_average_int(objects: Dictionary, property: String) -> int:
	var total_weight := 0;
	var weighted_sum := 0;

	for object in objects:
		var weight: float = objects[object];

		total_weight += weight;
		weighted_sum += (object.get_indexed(property) * weight);
	
	return weighted_sum / total_weight;


func _weighted_average_color(objects: Dictionary, property: String) -> Color:
	return Color(
		_weighted_average_float(objects, property + ":r"),
		_weighted_average_float(objects, property + ":g"),
		_weighted_average_float(objects, property + ":b"),
		_weighted_average_float(objects, property + ":a")
	);


func _weighted_average_vector3(objects: Dictionary, property: String) -> Vector3:
	return Vector3(
		_weighted_average_float(objects, property + ":x"),
		_weighted_average_float(objects, property + ":y"),
		_weighted_average_float(objects, property + ":z")
	);


func _weighted_average_basis(objects: Dictionary, property: String) -> Basis:
	return Basis(
		_weighted_average_vector3(objects, property + ":x"),
		_weighted_average_vector3(objects, property + ":y"),
		_weighted_average_vector3(objects, property + ":z")
	);


func _blend_environments(environments: Dictionary, dest_environment: Environment) -> void:
	# Background
	dest_environment.background_mode = _get_highest_weight_value(environments, "background_mode");
	match dest_environment.background_mode:
		Environment.BG_SKY:
			dest_environment.background_sky = _get_highest_weight_value(environments, "background_sky");
			dest_environment.background_sky_custom_fov = _weighted_average_float(environments, "background_sky_custom_fov");
			dest_environment.background_sky_orientation = _weighted_average_basis(environments, "background_sky_orientation");
		Environment.BG_COLOR:
			dest_environment.background_color = _weighted_average_color(environments, "background_color");
		Environment.BG_CANVAS:
			dest_environment.background_canvas_max_layer = _get_highest_weight_value(environments, "background_canvas_max_layer");
		Environment.BG_CAMERA_FEED:
			dest_environment.background_camera_feed_id = _get_highest_weight_value(environments, "background_camera_feed_id");
	
	dest_environment.background_energy = _weighted_average_float(environments, "background_energy");
	
	# Ambient Light
	dest_environment.ambient_light_color = _weighted_average_color(environments, "ambient_light_color");
	dest_environment.ambient_light_energy = _weighted_average_float(environments, "ambient_light_energy");
	dest_environment.ambient_light_sky_contribution = _weighted_average_float(environments, "ambient_light_sky_contribution");

	# Fog
	dest_environment.fog_enabled = _get_highest_weight_value(environments, "fog_enabled");
	if dest_environment.fog_enabled:
		dest_environment.fog_color = _weighted_average_color(environments, "fog_color");
		
		dest_environment.fog_sun_color = _weighted_average_color(environments, "fog_sun_color");
		dest_environment.fog_sun_amount = _weighted_average_float(environments, "fog_sun_amount");
		
		dest_environment.fog_depth_enabled = _get_highest_weight_value(environments, "fog_depth_enabled");
		if dest_environment.fog_depth_enabled:
			dest_environment.fog_depth_begin = _weighted_average_float(environments, "fog_depth_begin");
			dest_environment.fog_depth_end = _weighted_average_float(environments, "fog_depth_end");
			dest_environment.fog_depth_curve = _weighted_average_float(environments, "fog_depth_curve");
		
		dest_environment.fog_transmit_enabled = _get_highest_weight_value(environments, "fog_transmit_enabled");
		if dest_environment.fog_transmit_enabled:
			dest_environment.fog_transmit_curve = _weighted_average_float(environments, "fog_transmit_curve");

		dest_environment.fog_height_enabled = _get_highest_weight_value(environments, "fog_height_enabled");
		if dest_environment.fog_height_enabled:
			dest_environment.fog_height_min = _weighted_average_float(environments, "fog_height_min");
			dest_environment.fog_height_max = _weighted_average_float(environments, "fog_height_max");
			dest_environment.fog_height_curve = _weighted_average_float(environments, "fog_height_curve");

	# Tonemap
	dest_environment.tonemap_mode = _get_highest_weight_value(environments, "tonemap_mode");
	dest_environment.tonemap_exposure = _weighted_average_float(environments, "tonemap_exposure");
	dest_environment.tonemap_white = _weighted_average_float(environments, "tonemap_white");

	# Auto exposure
	dest_environment.auto_exposure_enabled = _get_highest_weight_value(environments, "auto_exposure_enabled");
	if dest_environment.auto_exposure_enabled:
		dest_environment.auto_exposure_scale = _weighted_average_float(environments, "auto_exposure_scale");
		dest_environment.auto_exposure_min_luma = _weighted_average_float(environments, "auto_exposure_min_luma");
		dest_environment.auto_exposure_max_luma = _weighted_average_float(environments, "auto_exposure_max_luma");
		dest_environment.auto_exposure_speed = _weighted_average_float(environments, "auto_exposure_speed");

	# SS Reflections
	dest_environment.ssr_enabled = _get_highest_weight_value(environments, "ssr_enabled");
	if dest_environment.ssr_enabled:
		dest_environment.ssr_max_steps = _weighted_average_int(environments, "ssr_max_steps");
		dest_environment.ssr_fade_in = _weighted_average_float(environments, "ssr_fade_in");
		dest_environment.ssr_fade_out = _weighted_average_float(environments, "ssr_fade_out");
		dest_environment.ssr_depth_tolerance = _weighted_average_float(environments, "ssr_depth_tolerance");
		dest_environment.ss_reflections_roughness = _get_highest_weight_value(environments, "ss_reflections_roughness");

	# SSAO
	dest_environment.ssao_enabled = _get_highest_weight_value(environments, "ssao_enabled");
	if dest_environment.ssao_enabled:
		dest_environment.ssao_radius = _weighted_average_float(environments, "ssao_radius");
		dest_environment.ssao_intensity = _weighted_average_float(environments, "ssao_intensity");
		dest_environment.ssao_radius2 = _weighted_average_float(environments, "ssao_radius2");
		dest_environment.ssao_intensity2 = _weighted_average_float(environments, "ssao_intensity2");
		dest_environment.ssao_bias = _weighted_average_float(environments, "ssao_bias");
		dest_environment.ssao_light_affect = _weighted_average_float(environments, "ssao_light_affect");
		dest_environment.ssao_ao_channel_affect = _weighted_average_float(environments, "ssao_ao_channel_affect");
		dest_environment.ssao_color = _weighted_average_color(environments, "ssao_color");
		dest_environment.ssao_quality = _get_highest_weight_value(environments, "ssao_quality");
		dest_environment.ssao_blur = _get_highest_weight_value(environments, "ssao_blur");
		dest_environment.ssao_edge_sharpness = _weighted_average_float(environments, "ssao_edge_sharpness");

	# DOF (far)
	dest_environment.dof_blur_far_enabled = _get_highest_weight_value(environments, "dof_blur_far_enabled");
	if dest_environment.dof_blur_far_enabled:
		dest_environment.dof_blur_far_distance = _weighted_average_float(environments, "dof_blur_far_distance");
		dest_environment.dof_blur_far_transition = _weighted_average_float(environments, "dof_blur_far_transition");
		dest_environment.dof_blur_far_amount = _weighted_average_float(environments, "dof_blur_far_amount");
		dest_environment.dof_blur_far_quality = _get_highest_weight_value(environments, "dof_blur_far_quality");
	
	# DOF (near)
	dest_environment.dof_blur_near_enabled = _get_highest_weight_value(environments, "dof_blur_near_enabled");
	if dest_environment.dof_blur_near_enabled:
		dest_environment.dof_blur_near_distance = _weighted_average_float(environments, "dof_blur_near_distance");
		dest_environment.dof_blur_near_transition = _weighted_average_float(environments, "dof_blur_near_transition");
		dest_environment.dof_blur_near_amount = _weighted_average_float(environments, "dof_blur_near_amount");
		dest_environment.dof_blur_near_quality = _get_highest_weight_value(environments, "dof_blur_near_quality");
	
	# Glow
	dest_environment.glow_enabled = _get_highest_weight_value(environments, "glow_enabled");
	if dest_environment.glow_enabled:
		for level in range(1, 8):
			dest_environment.set_glow_level(level, _get_highest_weight_value(environments, "glow_levels/%d" % level));
		dest_environment.glow_intensity = _weighted_average_float(environments, "glow_intensity");
		dest_environment.glow_strength = _weighted_average_float(environments, "glow_strength");
		dest_environment.glow_bloom = _weighted_average_float(environments, "glow_bloom");
		dest_environment.glow_blend_mode = _get_highest_weight_value(environments, "glow_blend_mode");
		dest_environment.glow_hdr_threshold = _weighted_average_float(environments, "glow_hdr_threshold");
		dest_environment.glow_hdr_luminance_cap = _weighted_average_float(environments, "glow_hdr_luminance_cap");
		dest_environment.glow_hdr_scale = _weighted_average_float(environments, "glow_hdr_scale");
		dest_environment.glow_bicubic_upscale = _get_highest_weight_value(environments, "glow_bicubic_upscale");
		dest_environment.glow_high_quality = _get_highest_weight_value(environments, "glow_high_quality");

	# Adjustment
	dest_environment.adjustment_enabled = _get_highest_weight_value(environments, "adjustment_enabled");
	if dest_environment.adjustment_enabled:
		dest_environment.adjustment_brightness = _weighted_average_float(environments, "adjustment_brightness");
		dest_environment.adjustment_contrast = _weighted_average_float(environments, "adjustment_contrast");
		dest_environment.adjustment_saturation = _weighted_average_float(environments, "adjustment_saturation");
		dest_environment.adjustment_color_correction = _get_highest_weight_value(environments, "adjustment_color_correction");
