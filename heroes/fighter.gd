extends KinematicBody2D

#Сигналы -----------------------------------------------------------------------
signal take_damage(damage, fly_velocity)

#Характеристики ----------------------------------------------------------------
var health = 100
var damage = 2
var move_speed = 100
var jump_speed = 200
var char_strength = 10

#Переменные для работы функций -------------------------------------------------
var velocity = Vector2.ZERO
var strikes_animations = ["strike_1", "strike_2", "strike_3"]
var strikes_damage_frames = [3, 3, 4]
var strikes_strength = [50, 50, 250]
onready var strikes_hit_areas = [$fighter/strike1_hit_area/Shape, $fighter/strike2_hit_area/Shape, $fighter/strike3_hit_area/Shape]
var combo_count = 0

#Переменные для анимации и функций----------------------------------------------
var jumping = false
var fighting = false
var can_strike = true
var end_combo = false
var taking_damage = false

#Основные функции --------------------------------------------------------------
func _ready():
	for i in strikes_hit_areas:
		i.set_disabled(true)

func _physics_process(delta):
	player_input()
	animation()
	
	velocity.y += Global.GRAVITY * delta
	
	if jumping and is_on_floor():
		jumping = false
	
	velocity = move_and_slide(velocity, Vector2.UP)

#Ввод игрока -------------------------------------------------------------------
func player_input():
	var left = Input.is_action_pressed(Global.LEFT_ACTION)
	var right = Input.is_action_pressed(Global.RIGHT_ACTION)
	var jump = Input.is_action_just_pressed(Global.JUMP_ACTION)
	var strike = Input.is_action_just_pressed(Global.STRIKE_ACTION)
	
	if not fighting and not taking_damage and is_on_floor():
		velocity.x = 0
		if left:
			$fighter.scale.x = -1
			velocity.x -= move_speed
		if right:
			$fighter.scale.x = 1
			velocity.x += move_speed
		if jump and is_on_floor():
			jumping = true
			velocity.y = -jump_speed
	if strike and can_strike:
		velocity.x = 0
		fighting = true
		can_strike = false
		combo_count += 1
		if combo_count > strikes_animations.size()-1:
			combo_count = 0
			end_combo = true

#Анимация ----------------------------------------------------------------------
func animation():
	var anim = "idle"
		
	if velocity.x != 0 and is_on_floor():
		anim = "run"
	if not is_on_floor():
		anim = "jump"
	
	if taking_damage:
		anim = "wound"
	elif fighting:
		if is_on_floor():
			anim = strikes_animations[combo_count]
	
	$fighter/AnimatedSprite.animation = anim

func stop_animation():
	var anim = $fighter/AnimatedSprite.animation
	
	if anim == "wound":
		taking_damage = false
		can_strike = true
		
	for i in strikes_animations:
		
		if anim == i:
			fighting = false
			if end_combo:
				$combo_delay.start()
			else:
				$strike_delay.start()

func get_frame():
	var anim = $fighter/AnimatedSprite.animation
	var frame = $fighter/AnimatedSprite.frame
	
	for i in range(strikes_animations.size()):
		if anim == strikes_animations[i]:
			if frame == strikes_damage_frames[i]:
				strikes_hit_areas[i].set_disabled(false)
			else:
				strikes_hit_areas[i].set_disabled(true)

#Атака\Получение урона ---------------------------------------------------------
func attack(body):
	if body.is_connected("take_damage", body, "take_damage"):
		var fly_velocity = Vector2(strikes_strength[combo_count] * $fighter.scale.x, -strikes_strength[combo_count]/2)
		body.emit_signal("take_damage", damage, fly_velocity)

func take_damage(damage, fly_velocity):
	taking_damage = true
	fighting = false
	$fighter/AnimatedSprite.animation = "wound"
	health -= damage
	fly_velocity.x -= char_strength 
	fly_velocity.y += char_strength
	velocity = move_and_slide(fly_velocity/2, Vector2.UP)

#Сигналы таймера ---------------------------------------------------------------
func strike_delay_timeout():
	can_strike = true

func combo_delay_timeout():
	can_strike = true
	end_combo = false
