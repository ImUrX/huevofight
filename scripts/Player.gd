extends KinematicBody2D


# Declare member variables here. Examples:
var speed = 300
var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed('ui_right'):
		velocity.x += 1
	if Input.is_action_pressed('ui_left'):
		velocity.x -= 1
	if Input.is_action_pressed('ui_down'):
		velocity.y += 1
	if Input.is_action_pressed('ui_up'):
		velocity.y -= 1
	velocity = velocity.normalized() * speed

func _physics_process(delta):
	get_input()
	move_and_collide(velocity * delta)

func _input(event):
	if event is InputEventMouseMotion:
		var head_pos = $Cabeza.global_position
		var rads = atan2(event.position.y - head_pos.y, event.position.x - head_pos.x)
		print(rads)
		print(self.rotation)
		print(self.rotation + (PI * -1))
		if rads < self.rotation && rads > self.rotation + PI * -1:
			$Cabeza.rotation = rads
			$Cabeza.rotate(90 * PI/180)
		elif rads < self.rotation:
			self.rotation = rads
		elif rads > self.rotation + PI * -1:
			self.rotation = rads
			self.rotate(PI * -1)
