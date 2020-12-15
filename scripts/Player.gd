extends KinematicBody2D


# Declare member variables here. Examples:
var speed = 300
var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

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
		var inverse_self = self.rotation - PI
		if inverse_self > PI:
			inverse_self -= 2*PI
		elif inverse_self < -PI:
			inverse_self += 2*PI
		print(rads)
		print($Cabeza.rotation)
		print(self.rotation)
		print(inverse_self)
		if (self.rotation >= 0 && rads < self.rotation && rads > inverse_self) || (self.rotation < 0 && rads < self.rotation && rads < inverse_self):
			$Cabeza.rotation = rads + (90 * PI/180) - self.rotation
		elif $Cabeza.rotation > 0:
			self.rotation = rads
		elif $Cabeza.rotation < 0:
			self.rotation = rads - PI