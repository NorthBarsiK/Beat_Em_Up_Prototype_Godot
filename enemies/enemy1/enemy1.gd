extends KinematicBody2D

#Сигналы -----------------------------------------------------------------------
signal take_damage(damage, fly_velocity)

#Характеристики ----------------------------------------------------------------
var health = 5
var damage = 3
var move_speed = 30
var char_strength = 0

#Переменные для работы функций -------------------------------------------------
var velocity = Vector2.ZERO
onready var strikes_hit_areas = [$enemy/strike_1_hit_area/shape, $enemy/strike_2_hit_area2/shape]
var strikes_animations = ["strike_1", "strike_2"]
var strikes_damage_frames = [4, 3]
var strikes_strength = [100, 100]

#Переменные для анимации и ИИ --------------------------------------------------
var fighting = false
var jumping = false
var taking_damage = false
var can_strike = true
var target = null
var fight_distance = 20
var detect_distance = 100
var combo_count = 0

#Основные функции --------------------------------------------------------------
func _ready():
	for i in strikes_hit_areas:
		i.set_disabled(true)
	target = get_node("/root/main/Fighter")

func _physics_process(delta):
	if is_on_floor():
		movement()
		
	animation()
	
	velocity.y += Global.GRAVITY * delta
	
	velocity = move_and_slide(velocity, Vector2.UP)

#Передвижение ------------------------------------------------------------------
func movement():
	var target_distance = abs(target.position.x - position.x)
	
	if target_distance <= fight_distance and can_strike:
		velocity.x = 0
		fighting = true
		can_strike = false
		combo_count += 1
		if combo_count > strikes_animations.size()-1:
			combo_count = 0
	
	if not fighting and not taking_damage:
		if target_distance < detect_distance or target_distance > fight_distance:
			if target.position.x < position.x:
				$enemy.scale.x = -1
				velocity.x = -move_speed
			else:
				$enemy.scale.x = 1
				velocity.x = move_speed
	else:
		velocity.x = 0

#Анимация ----------------------------------------------------------------------
func animation():
	var anim = "idle"
	
	if velocity.x != 0 and is_on_floor():
		anim = "run"
	
	if taking_damage:
		anim = "wound"
	elif fighting:
		anim = strikes_animations[combo_count]
	
	$enemy/AnimatedSprite.animation = anim

func stop_animation():
	var anim = $enemy/AnimatedSprite.animation
	
	if anim == "wound":
		taking_damage = false
		can_strike = true
		set_collision_layer_bit(0, true)
		set_collision_mask_bit(0, true)
		set_collision_layer_bit(2, false)
		set_collision_mask_bit(2, false)
		
	for i in strikes_animations:
		if anim == i:
			fighting = false
			$strike_delay.start()

func get_frame():
	var anim = $enemy/AnimatedSprite.animation
	var frame = $enemy/AnimatedSprite.frame
	
	for i in range(strikes_animations.size()):
		if anim == strikes_animations[i]:
			if frame == strikes_damage_frames[i]:
				strikes_hit_areas[i].set_disabled(false)
			else:
				strikes_hit_areas[i].set_disabled(true)

#Атака\Получение урона ---------------------------------------------------------
func attack(body):
	if body.is_connected("take_damage", body, "take_damage"):
		var fly_velocity = Vector2(strikes_strength[combo_count] * $enemy.scale.x, -strikes_strength[combo_count]/2)
		body.emit_signal("take_damage", damage, fly_velocity)

func take_damage(damage, fly_velocity):
	taking_damage = true
	fighting = false
	$enemy/AnimatedSprite.animation = "wound"
	health -= damage
	fly_velocity.x -= char_strength 
	fly_velocity.y += char_strength
	velocity = move_and_slide(fly_velocity/2, Vector2.UP)
	set_collision_layer_bit(0, false)
	set_collision_mask_bit(0, false)
	set_collision_layer_bit(2, true)
	set_collision_mask_bit(2, true)

#Сигналы таймера ---------------------------------------------------------------
func strike_delay_timeout():
	can_strike = true


