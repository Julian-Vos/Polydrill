extends Node2D

var brush = PoolVector2Array()
var pressing = false

func _ready():
	for i in 30:
		var angle = i * PI / 15
		
		brush.push_back(Vector2(cos(angle), sin(angle)) * 40)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			pressing = event.pressed
		else:
			return
	elif !(event is InputEventMouseMotion):
		return
	
	update()
	
	if pressing:
		$DestructiblePolygon2D.destruct(Transform2D(0, event.position).xform(brush))

func _draw():
	var points = Transform2D(0, get_global_mouse_position()).xform(brush)
	
	points.push_back(points[0])
	
	draw_polyline(points, Color.black if pressing else Color.white, 3, true)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		update()
