extends Position2D

var far_bg_speed = 0.1
var bg_speed = 0.3

func _physics_process(delta):
	get_input()

func get_input():
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")
	
	if left:
		$bg1_1.position.x += far_bg_speed
		$bg1_2.position.x += far_bg_speed
		$bg2_1.position.x += bg_speed
		$bg2_2.position.x += bg_speed
	
	if right:
		$bg1_1.position.x -= far_bg_speed
		$bg1_2.position.x -= far_bg_speed
		$bg2_1.position.x -= bg_speed
		$bg2_2.position.x -= bg_speed
