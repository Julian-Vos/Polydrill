extends StaticBody2D

func _ready():
	$CollisionPolygon2D.polygon = $Polygon2D.polygon

func destruct(polygon):
	var clipped = Geometry.clip_polygons_2d($Polygon2D.polygon, Transform2D(0, -global_position).xform(polygon))
	
	match clipped.size():
		0:
			queue_free()
		2:
			if Geometry.is_polygon_clockwise(clipped[1]):
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
								
								update_or_create(part1, boundary_size, false)
								update_or_create(part2, hole_size, true)
								
								return
			else:
				continue
		_:
			for i in clipped.size():
				update_or_create(clipped[i], clipped[i].size(), i > 0)

func update_or_create(polygon, size, new):
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
				
				update_or_create(part1, i + 1, new)
				update_or_create(part2, size - i + 1, true)
				
				return
			
			i += step
			
			step = -step
			step += sign(step)
	
	var area = 0
	var point = polygon[polygon.size() - 1]
	
	for i in polygon.size(): # also remove points which are too close to each other
		var next_point = polygon[i]
		
		area += point.x * next_point.y
		area -= point.y * next_point.x
		
		point = next_point
	
	if area / 2 < 8:
		if !new:
			queue_free()
	else:
		var body = self
		
		if new:
			body = duplicate()
			# body.modulate = Color(randf(), randf(), randf())
			
			get_parent().call_deferred('add_child', body)
		
		body.get_child(0).polygon = polygon
		body.get_child(1).polygon = polygon
