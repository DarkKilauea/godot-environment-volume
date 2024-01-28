extends Node3D

@export_range(0, 1, 0.01) var mouse_sensitivity = 0.05
@export_range(0, 20, 0.5) var move_speed := 8.0

@onready var camera: Camera3D = $Camera3D as Camera3D;


func _enter_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	# Mouse look (effective only if the mouse is captured)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		self.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		var camera_rot = camera.rotation;
		camera_rot.x = clamp(camera_rot.x, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation = camera_rot;
	
	# Toggle mouse capture (only while the menu is not visible)
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	var input_vector = Vector3.ZERO
	var cam_xform = camera.get_global_transform()
	
	if Input.is_action_pressed("move_right"):
		input_vector += Vector3.RIGHT;
	if Input.is_action_pressed("move_left"):
		input_vector += Vector3.LEFT;
	if Input.is_action_pressed("move_backward"):
		input_vector += Vector3.BACK;
	if Input.is_action_pressed("move_forward"):
		input_vector += Vector3.FORWARD;
	
	input_vector = cam_xform.basis * (input_vector);
	input_vector = input_vector.normalized()
	
	if Input.is_action_pressed("move_sprint"):
		input_vector *= 2
	
	position += input_vector * move_speed * delta

