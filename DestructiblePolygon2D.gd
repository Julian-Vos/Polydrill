extends Node2D

export(bool) var collidable

func _ready():
	var minX = INF
	var minY = INF
	var maxX = -INF
	var maxY = -INF
	# reuse
	for point in $Polygon2D.polygon:
		minX = min(minX, point.x)
		minY = min(minY, point.y)
		maxX = max(maxX, point.x)
		maxY = max(maxY, point.y)
	
	$Polygon2D.set_meta('bounds', Rect2(minX, minY, maxX - minX, maxY - minY))
	
	if collidable:
		var static_body_2d = StaticBody2D.new()
		var collision_polygon_2d = CollisionPolygon2D.new()
		
		collision_polygon_2d.polygon = $Polygon2D.polygon
		
		static_body_2d.add_child(collision_polygon_2d)
		
		$Polygon2D.add_child(static_body_2d)

func destruct(polygon):
	var brush = Transform2D(0, -global_position).xform(polygon) # rename
	var minX = INF
	var minY = INF
	var maxX = -INF
	var maxY = -INF
	
	for point in brush:
		minX = min(minX, point.x)
		minY = min(minY, point.y)
		maxX = max(maxX, point.x)
		maxY = max(maxY, point.y)
	
	var brush_bounds = Rect2(minX, minY, maxX - minX, maxY - minY) # rename
	
	for polygon_2d in get_children():
		if polygon_2d.get_meta('bounds').intersects(brush_bounds):
			destruct_child(polygon_2d, brush)

func destruct_child(polygon_2d, brush):
	var clipped = Geometry.clip_polygons_2d(polygon_2d.polygon, brush)
	
	match clipped.size():
		0:
			polygon_2d.queue_free() # free self if last
		1:
			if !Geometry.intersect_polygons_2d(polygon_2d.polygon, brush).empty():
				continue
		2:
			if !Geometry.is_polygon_clockwise(clipped[1]):
				continue
			
			var boundary_size = clipped[0].size()
			var hole_size = clipped[1].size()
			
			for i in boundary_size:
				var link1 = [clipped[0][i], null]
				
				for j in hole_size:
					link1[1] = clipped[1][j]
					
					if !Geometry.clip_polyline_with_polygon_2d(link1, clipped[0]).empty():
						continue
					
					if !Geometry.intersect_polyline_with_polygon_2d(link1, clipped[1]).empty():
						continue
					
					for k in range(i + 1, boundary_size):
						var link2 = [clipped[0][k], null]
						
						for l in hole_size:
							if l == j:
								continue
							
							link2[1] = clipped[1][l]
							
							if !Geometry.clip_polyline_with_polygon_2d(link2, clipped[0]).empty():
								continue
							
							if !Geometry.intersect_polyline_with_polygon_2d(link2, clipped[1]).empty():
								continue
							
							if Geometry.segment_intersects_segment_2d(link1[0], link1[1], link2[0], link2[1]) != null:
								continue
							
							var part1 = PoolVector2Array()
							var part2 = PoolVector2Array()
							
							for m in boundary_size:
								if m >= i && m <= k:
									part1.push_back(clipped[0][m])
								
								if m <= i:
									part2.push_back(clipped[0][m])
								
								if m >= k:
									part2.insert(m - k, clipped[0][m])
							
							var m = l
							
							while true:
								part1.push_back(clipped[1][m])
								
								if m == j:
									break
								
								m = (m + 1) % hole_size
							
							while true:
								part2.push_back(clipped[1][m])
								
								if m == l:
									break
								
								m = (m + 1) % hole_size
							
							update_or_create(polygon_2d, part1, part1.size(), false)
							update_or_create(polygon_2d, part2, part2.size(), true)
							
							return
		_:
			for i in clipped.size():
				update_or_create(polygon_2d, clipped[i], clipped[i].size(), i > 0)

func update_or_create(polygon_2d, polygon, size, new):
	if size > 128:
		var i = size / 2
		var step = 1
		
		while true:
			for j in size:
				var k = (j + i) % size
				
				if !Geometry.clip_polyline_with_polygon_2d([polygon[j], polygon[k]], polygon).empty():
					continue
				
				var part1 = PoolVector2Array()
				var part2 = PoolVector2Array()
				var l = j
				
				while true:
					part1.push_back(polygon[l])
					
					if l == k:
						break
					
					l = (l + 1) % size
				
				while true:
					part2.push_back(polygon[l])
					
					if l == j:
						break
					
					l = (l + 1) % size
				
				update_or_create(polygon_2d, part1, i + 1, new)
				update_or_create(polygon_2d, part2, size - i + 1, true)
				
				return
			
			i += step
			
			step = -step
			step += sign(step)
	
	var area = 0
	var point = polygon[polygon.size() - 1]
	var minX = INF
	var minY = INF
	var maxX = -INF
	var maxY = -INF
	
	for i in polygon.size(): # also remove points which are too close to each other
		var next_point = polygon[i]
		
		area += point.x * next_point.y
		area -= point.y * next_point.x
		
		point = next_point
		
		minX = min(minX, point.x)
		minY = min(minY, point.y)
		maxX = max(maxX, point.x)
		maxY = max(maxY, point.y)
	
	if area / 2 < 16:
		if !new:
			polygon_2d.queue_free() # free self if last
	else:
		var node = polygon_2d
		
		if new:
			node = node.duplicate()
			# node.modulate = Color(randf(), randf(), randf())
			
			call_deferred('add_child', node)
		
		node.set_meta('bounds', Rect2(minX, minY, maxX - minX, maxY - minY))
		node.polygon = polygon
		
		if collidable:
			node.get_child(0).get_child(0).polygon = polygon
