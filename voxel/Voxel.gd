extends Node

class Voxel:
	var _x
	var _y
	var _z
	var _chunk
	var _type
	var _terrain
	var isMarching = false
	
	#newcode
	var _left = null
	var  _top = null
	var _bottom = null
	var _right = null
	var _front = null
	var _back = null
	var _coordinate

	func _init(x, y, z, _coordinate, type, terrain, chunk):
		_type = type
		_x=x
		_y=y
		_z=z
		_chunk = chunk
		_terrain=terrain

	func draw(surfacetool):

		if self.isMarching:
			get_marching(surfacetool)
		else:
			get_cube(surfacetool)
	

	func get_marching(surfacetool):
		var configuration=0;
		configuration = configuration + (1 if self._back.type>0 else 0)
		configuration = configuration + (2 if self._right.type>0 else 0)
		configuration = configuration + (4 if self._front.type>0 else 0)
		configuration = configuration + (8 if self._left.type>0 else 0)
		configuration = configuration + (16 if self._bottom.type>0 else 0)
		configuration = configuration + (32 if self._top.type>0 else 0)
		if configuration == 0:
			return
		
	func get_cube(surfacetool):
		if self._front.type > 0: #front
			self.draw_poly([Vector3(0.5, 0.5, 0.5), Vector3(0.5, -0.5, 0.5),Vector3(-0.5, 0.5, 0.5),Vector3(-0.5, -0.5, 0.5)])
		if self._left.type > 0: #left
			self.draw_poly([Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, -0.5, 0.5),Vector3(-0.5, 0.5, -0.5),Vector3(-0.5, -0.5, -0.5)])
		if self._right.type > 0: #right
			self.draw_poly([Vector3(0.5, -0.5, -0.5),Vector3(0.5, -0.5, 0.5),Vector3(0.5, 0.5, -0.5),Vector3(0.5, 0.5, 0.5)])
		if self._back.type > 0: #back
			self.draw_poly([Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5),Vector3(-0.5, 0.5, -0.5),Vector3(0.5, 0.5, -0.5)])
		if self._top.type > 0: #top
			self.draw_poly([Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5),Vector3(-0.5, 0.5, 0.5),Vector3(0.5, 0.5, 0.5)])
		if self._bottom.type > 0: #bottom
			self.draw_poly([Vector3(0.5, -0.5, 0.5),Vector3(0.5, -0.5, -0.5),Vector3(-0.5, -0.5, 0.5),Vector3(-0.5, -0.5, -0.5)])

		pass

	func draw_poly(surfacetool, dir):
	 	self.draw_triangle(surfacetool, [dir[0], dir[1], dir[2]])
	 	self.draw_triangle(surfacetool, [dir[3], dir[2], dir[1]])

	func draw_triangle(surfacetool, corner):
		surfacetool.add_vertex(corner[0]+Vector3(self._x,self._y,self._z))
		surfacetool.add_vertex(corner[1]+Vector3(self._x,self._y,self._z))
		surfacetool.add_vertex(corner[2]+Vector3(self._x,self._y,self._z))

	func change_type(type):
		if x==0:
			self._terrain.update(self._chunk._left)
		if x==self._chunk.size-1:
			self._terrain.update(self._chunk._right)
		if y == 0:
			self._terrain.update(self._chunk._top)
		if y == self._chunk.size-1:
			self._terrain.update(self._chunk._bottom)
		if z==0:
			self._terrain.update(self._chunk._back)
		if z== self._chunk.size-1:
			self._terrain.update(self._chunk._front)
