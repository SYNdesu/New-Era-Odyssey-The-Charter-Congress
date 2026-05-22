class_name PlayerAnimationSetup

## 占位动画生成器
## 为没有美术资源时提供测试用的彩色方块动画

static func setup_placeholder_animations(anim_player: AnimationPlayer, sprite: Sprite2D) -> void:
	if not anim_player or not sprite:
		return
	
	var lib = anim_player.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)
	
	var directions = ["down", "up", "left", "right"]
	var colors = [Color.BLUE, Color.DARK_BLUE, Color.ORANGE, Color.GREEN]
	
	for i in directions.size():
		var dir = directions[i]
		var tex = _create_placeholder_texture(colors[i], dir)
		
		var idle_name = "idle_" + dir
		if not lib.has_animation(idle_name):
			var idle = Animation.new()
			idle.length = 1.0
			idle.loop_mode = Animation.LOOP_LINEAR
			var track = idle.add_track(Animation.TYPE_VALUE)
			idle.track_set_path(track, String(sprite.get_path()) + ":texture")
			idle.track_insert_key(track, 0.0, tex)
			lib.add_animation(idle_name, idle)
		
		var move_name = "move_" + dir
		if not lib.has_animation(move_name):
			var move = Animation.new()
			move.length = 0.45
			move.loop_mode = Animation.LOOP_LINEAR
			var track = move.add_track(Animation.TYPE_VALUE)
			move.track_set_path(track, String(sprite.get_path()) + ":modulate")
			move.track_insert_key(track, 0.0, Color.WHITE)
			move.track_insert_key(track, 0.15, Color(0.7, 0.7, 0.7))
			move.track_insert_key(track, 0.3, Color.WHITE)
			lib.add_animation(move_name, move)


static func _create_placeholder_texture(color: Color, dir: String) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	# 画方向箭头（白色三角）
	var arrow = PackedVector2Array()
	match dir:
		"down":
			arrow = PackedVector2Array([Vector2(16, 24), Vector2(10, 14), Vector2(22, 14)])
		"up":
			arrow = PackedVector2Array([Vector2(16, 8), Vector2(10, 18), Vector2(22, 18)])
		"left":
			arrow = PackedVector2Array([Vector2(8, 16), Vector2(18, 10), Vector2(18, 22)])
		"right":
			arrow = PackedVector2Array([Vector2(24, 16), Vector2(14, 10), Vector2(14, 22)])
	
	for y in range(32):
		for x in range(32):
			if _point_in_triangle(Vector2(x, y), arrow[0], arrow[1], arrow[2]):
				img.set_pixel(x, y, Color.WHITE)
			elif (x == 14 or x == 18) and (y == 12 or y == 20):
				img.set_pixel(x, y, Color.BLACK)
	
	return ImageTexture.create_from_image(img)


static func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 = _sign(p, a, b)
	var d2 = _sign(p, b, c)
	var d3 = _sign(p, c, a)
	var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
	var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
	return not (has_neg and has_pos)


static func _sign(p1: Vector2, p2: Vector2, p3: Vector2) -> float:
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
