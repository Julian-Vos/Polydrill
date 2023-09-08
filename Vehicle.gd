extends Sprite

var brush = PoolVector2Array()

func _ready():
	for i in 30:
		var angle = i * PI / 15

		brush.push_back(Vector2(cos(angle), sin(angle)) * 64)

func _process(delta):
	var velocity = Vector2()
	
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 140 * delta
		
	if Input.is_action_pressed("ui_down"):
		velocity.y += 140 * delta
	
	if Input.is_action_pressed("ui_left"):
		rotation -= 2 * delta
	
	if Input.is_action_pressed("ui_right"):
		rotation += 2 * delta
	
	position += velocity.rotated(rotation)
	
	for body in get_parent().get_children():
		if body is StaticBody2D:
			body.destruct(Transform2D(0, global_position - Vector2(0, 32).rotated(rotation)).xform(brush))
