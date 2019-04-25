extends Node

export(int) var chunk_size=16
export(int) var world_size=30
export(int) var distance=5
export(bool) onready var trigger_generation = false setget Generate
export(Vector3) var current_coord = Vector3(0, 0, 0)



var terrain_instance

func _ready():
	terrain_instance = Terrain.new(1234)

func Generate(_newval):
	if(_newval != trigger_generation):
		for i in range(0, get_child_count()):
			get_child(i).queue_free()

	terrain_instance.reset(distance, world_size, chunk_size)
	terrain_instance.generate(add_child, get_child)




class Terrain:
	var Chunk
	var chunks = {}
	var noise=null
	var distance
	var world_size
	var chunk_size
	

	func _init(_seed):
		self.noise=OpenSimplexNoise.new()
		self.noise.seed = _seed
		self.noise.period = 28
		self.Chunk = load("Chunk.gd")

	func reset(_distance, _world_size, _chunk_size):
		self.distance = _distance
		self.world_size = _world_size
		self.chunk_size = _chunk_size
		self.chunks.clear()
		for x in range(0, world_size):
			for y in range(0, world_size):
				for z in range(0, world_size):
					var chunk = self.get_related_chunk(x,y,z)
					chunk._top = self.get_related_chunk(x,y+1,z)
					chunk._bottom = self.get_related_chunk(x,y-1,z)

					chunk._front = self.get_related_chunk(x,y,z-1)
					chunk._back = self.get_related_chunk(x,y,z+1)

					chunk._left = self.get_related_chunk(x-1,y,z)
					chunk._right = self.get_related_chunk(x+1,y,z)

	
	func generate(add_callback, get_child_callback):
		var i=0
		for x in range(-self.distance, self.distance):
			for y in range(-self.distance, self.distance):
				for z in range(-self.distance, self.distance):
					var chunk = self.get_related_chunk(x,y,z)
					var terrain_pos_x = (chunk._x+current_coord.x)*chunk_size
					var terrain_pos_y = (chunk._y+current_coord.y)*chunk_size
					var terrain_pos_z = (chunk._z+current_coord.z)*chunk_size
					add_callback(chunk.get_mesh(false))
					get_child_callback(i).set_pos(Vector3(terrain_pos_x, terrain_pos_y, terrain_pos_z))
					i = i+1

	func get_related_chunk(x,y,z):
		var _x = to_range(x, 0, self.world_size)
		var _y = to_range(y, 0, self.world_size)
		var _z = to_range(z, 0, self.world_size)

		var key = x+"_"+y+"_"+z

		if self.chunks.has(key) == false:
			self.chunks[key] = self.Chunk.new(x,y,z, self.chunk_size, self.noise)

		return self.chunks[key]
	
	func getVoxelFromWorldCoord(x,y,z, rx, ry, rz):
		var terrain_x = floor(x/self.world_size)
		var terrain_y = floor(y/self.world_size)
		var terrain_z = floor(z/self.world_size)

		var chunk = self.get_related_chunk(terrain_x, terrain_y, terrain_z)
		return chunk.get_voxel(self.overflowValue(rx), self.overflowValue(ry), self.overflowValue(rz))	
		

	func to_range(number, _min, _max):
		if number < _min:
			return _max - abs(number - _min)
		if number > _max:
			return _min + abs(number - _max)
	
		return number


	func overflowValue(v):
		var t = v
		while(t<0):
			t = t + self.chunk_size

		while(t>chunk_size):
			t = t - self.chunk_size

		return t

	func update(chunk_instance):
		chunk_instance.get_mesh(true)
		