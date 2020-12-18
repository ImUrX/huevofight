extends KinematicBody2D


# Declare member variables here. Examples:
var head_distance = 1500
var speed = 300
var velocity = Vector2()
var rotation_weight = 5
var body_speed = .15

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

var elapsed_move = .0
func get_input(delta):
	velocity = Vector2()
	var mouse = get_global_mouse_position()
	var head_pos = $Cabeza.global_position
	if Input.is_action_pressed("move") && mouse.distance_squared_to(head_pos) > head_distance:
		elapsed_move += delta
		var rads = atan2(mouse.y - head_pos.y, mouse.x - head_pos.x)
		var rads_calc = inside_pi(rads + (90 * PI/180))
		
		if abs(self.rotation - rads_calc) <= deg2rad(5): 
			self.rotation = rads_calc
			elapsed_move = .0
		else:
			self.rotation = lerp_angle(self.rotation, rads_calc, elapsed_move/rotation_weight)
		velocity = Vector2(cos(rads), sin(rads)) * speed
		rpc_unreliable("set_rots", self.rotation, $Cabeza.rotation)
	else:
		elapsed_move = .0
	rpc_unreliable("set_pos_and_vel", position, velocity)

func _physics_process(delta):
	if is_network_master():
		get_input(delta)
	move_and_collide(velocity * delta)

func inside_pi(input):
	if input > PI:
		input -= 2*PI
	elif input < -PI:
		input += 2*PI
	return input

puppet func set_pos_and_vel(pos, vel):
	position = pos
	velocity = vel

puppet func set_rots(body, head):
	$Cabeza.rotation = head
	rotation = body

func _process(delta):
	if !is_network_master(): return
	var mouse = get_global_mouse_position()
	var head_pos = $Cabeza.global_position
	var rads = atan2(mouse.y - head_pos.y, mouse.x - head_pos.x)
	var inverse_self = inside_pi(self.rotation - PI)
	if (self.rotation >= 0 && rads < self.rotation && rads > inverse_self) || (self.rotation < 0 && (rads > self.rotation) == (rads > inverse_self)):
		$Cabeza.rotation = inside_pi(rads + (90 * PI/180) - self.rotation)
	elif mouse.distance_squared_to(head_pos) > head_distance:
		if $Cabeza.rotation > 0:
			self.rotation = lerp_angle(self.rotation, rads, body_speed)
		elif $Cabeza.rotation < 0:
			self.rotation = lerp_angle(self.rotation, inside_pi(rads - PI), body_speed)
	rpc_unreliable("set_rots", self.rotation, $Cabeza.rotation)
