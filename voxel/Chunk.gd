extends Node


class Chunk:
	var _x=0
	var _y=0
	var _z=0

	var _up = null
	var _down = null
	var _left = null
	var _right = null
	var _front = null
	var _back = null

	var Voxel
	var size=16
	var max_height=100
	var noise_seed=0
	var noise
	var data=[]
	var _mesh=null
	var terrain

	func _init(_xcoord, _ycoord, _zcoord, _size, _noise, _terrain):
		_x = _xcoord
		_y = _ycoord
		_z = _zcoord
		size = _size
		noise = noise
		Voxel = load("Voxel.gd")
		terrain = _terrain
		for x in range(0,size):
			data.append([])
			for y in range(0, size):
				data[x].append([])
				for z in range(0,size):
					data[x][y].append(self.Voxel.new(x,y,z, Vector3(real_x, real_y, real_z), 0, self.terrain, self))
		
	#under this line everything should go to a separate thread
	func get_mesh(reload):
		if self._mesh == null:
			self._mesh=MeshInstance.new()

		if reload == true || self._mesh == null:
		    var surfTool = SurfaceTool.new()
			surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
			for x in range(1,size):
				for y in range(1,size):
					for z in range(1,size):
						if data[x][y][z].type > 0:
							data[x][y][z].draw(surfTool)
					
			surfTool.set_material(load("res://terrain.tres"))
			surfTool.generate_normals()
			surfTool.index()
			surfTool.commit(_mesh)
		call_deferred("_mesh_loaded")
		return _mesh

	func get_voxel(x,y,z):
		var capped_x = self.terrain.overflowValue(x)
		var capped_y = self.terrain.overflowValue(y)
		var capped_z = self.terrain.overflowValue(z)

		return data[capped_x][capped_y][capped_z]

	func get_promised_voxel(x,y,z):

		return data[x][y][z]

	
	func generate_heigthmap():
		for x in range(0,size):
			data.append([])
			for y in range(0, size):
				data[x].append([])
				for z in range(0,size):
					var real_x = x+_x
					var real_y = y+_y
					var real_z = z+_z
					var height = noise.get_noise_3d(real_x, real_z)
					var voxel = data[x][y][z]
					if x>0:
						if x<size-1:
							voxel._right = data[x+1][y][z]
						else:
							voxel._right = _right.get_promised_voxel(0, y, z)

						voxel._left = data[x-1][y][z]
					else:
						voxel._left = _left.get_promised_voxel(self.size-1, y, z)

					if y>0:
						if y<size-1:
							voxel._top = data[x][y+1][z]
						else:
							voxel._top = _top.get_promised_voxel(x, 0, z)
						voxel._bottom = data[x][y-1][z]
					else:
						voxel._top = _top.get_promised_voxel(x, self.size-1, z)

					if z>0:
						if z<size-1:
							voxel._back = data[x][y][z+1]
						else:
							voxel._back = _back.get_promised_voxel(x, y, 0)
						voxel._front = data[x][y][z-1]
					else:
						voxel._back = _back.get_promised_voxel(x, x, self.size-1)


		call_deferred("_heightmap_loaded")
		
	func generate_caves():
		for x in range(0,size):
			for y in range(0,size):
				for z in range(0,size):
					if data[x][y][z].type >0:
						var second_layer = ((noise.get_noise_3d(x + _x, y + _y, z + _z)+ 1)/2)*10
						data[x][y][z].type = (1 if second_layer%10 < 4 else 0)

		call_deferred("_caves_loaded")
		