tool
extends MeshInstance
export(Material)    var material    = null
#export(FixedMaterial)    var material    = null
export(bool) onready var trigger_generation= false setget GenerateMesh
export(int) var chunk_size=10
var thread = Thread.new()

var sides = {
	"UP":[Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5),Vector3(-0.5, 0.5, 0.5),Vector3(0.5, 0.5, 0.5)],
	"DOWN":[Vector3(0.5, -0.5, 0.5),Vector3(0.5, -0.5, -0.5),Vector3(-0.5, -0.5, 0.5),Vector3(-0.5, -0.5, -0.5)],
	"LEFT":[Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, -0.5, 0.5),Vector3(-0.5, 0.5, -0.5),Vector3(-0.5, -0.5, -0.5)],
	"RIGHT":[ Vector3(0.5, -0.5, -0.5),Vector3(0.5, -0.5, 0.5),Vector3(0.5, 0.5, -0.5),Vector3(0.5, 0.5, 0.5)],
	"FRONT":[Vector3(0.5, 0.5, 0.5), Vector3(0.5, -0.5, 0.5),Vector3(-0.5, 0.5, 0.5),Vector3(-0.5, -0.5, 0.5)],
	"BACK":[Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5),Vector3(-0.5, 0.5, -0.5),Vector3(0.5, 0.5, -0.5)]
}


func GenerateMesh(_newval):
	if(_newval != trigger_generation):
		if thread.is_active():
			print("not starting, thread active")
			return
		#generate()
		thread.start(self, "generate", chunk_size)
	
func generate(chunk_size):
	print("thread called")
	var data = generateMapData(0,chunk_size, randi())
	var mesh = generateMapMesh(chunk_size, data)
	self.set_mesh(mesh)
	call_deferred("_bg_load_chunk")
	return mesh

func _bg_load_chunk():
	var mesh = thread.wait_to_finish()
	print("thread loaded")
	self.set_mesh(mesh)

func generateMapData(coord, size, _seed):
	var data = []
	var noise = OpenSimplexNoise.new()
	noise.seed = _seed
	noise.period = 28
	
	for x in range(0,size):
		data.append([])
		for y in range(0,size):
			data[x].append([])
			for z in range(0,size):
				data[x][y].append(0 if coord.y>=0 else 1)
				
	if coord.y>=0:
		#generating heigthmap
		for x in range(0,size):
			for z in range(0, size):	
				var height = ((noise.get_noise_2d(x, z)+ 1)/2)*size
				for y in range(0, min(height, size)):
					data[x][y][z] = 1
	
	
	for x in range(0,size):
		for y in range(0,size):
			var height = ((noise.get_noise_2d(x, y)+ 1)/2)*10
			for z in range(0,size):
				if data[x][y][z] >0:
					var second_layer = ((noise.get_noise_3d(x, y, z)+ 1)/2)*10
					data[x][y][z] = (1 if height>second_layer else 0)
	return data
	
func generateMapMesh(size, data):
	var surfTool = SurfaceTool.new()
	var mesh = Mesh.new()
	surfTool.set_material(material)
	surfTool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#var st = SurfaceTool.new()
	#st.set_material(mat1)
	# add vertices...
	#var mesh = st.commit()
	#st.set_material(mat2)
	# add other vertices...
	#st.commit(mesh) # This appends a new surface to the mesh
	
	for x in range(0, size):
		for y in range(0, size):
			for z in range(0, size):
				#generate mesh
				cube(data, surfTool, x, y, z)
	surfTool.set_material(load("res://terrain.tres"))
	surfTool.generate_normals()
	surfTool.index()
	surfTool.commit(mesh)
	
	print("thread finish")
	return mesh

func cube(data, surfTool, x, y, z):
	
	var coord = Vector3(x,y,z)
	if isVisible(data, x,y,z, x-1,y,z):
		plane(surfTool, coord, Vector3(-1, 0,0))
	if isVisible(data, x,y,z, x+1,y,z):
			plane(surfTool, coord, Vector3(1,0,0))

	
	if isVisible(data, x,y,z, x,y+1,z):
			plane(surfTool, coord, Vector3(0,1,0))
	if isVisible(data, x,y,z, x,y-1,z):
			plane(surfTool, coord, Vector3(0,-1,0))
			
	
	if isVisible(data, x,y,z, x,y,z+1):
			plane(surfTool, coord, Vector3(0,0,1))
	if isVisible(data, x,y,z, x,y,z-1):
			plane(surfTool, coord, Vector3(0,0,-1))
		
func isVisible(data, cx, cy, cz, x,y,z):
	#var check = coord + add
	return ((x<0 or y<0 or z<0 or x>=len(data) or y>=len(data) or z>=len(data)) and data[cx][cy][cz]>0) or (data[x][y][z] == 0 and data[cx][cy][cz]>0)
	#else:
	#	return data[coord.x][coord.y][coord.z] != 0
		
	return false
		
func in_arr(arr, i):
	return i>=0 and i<len(arr)
						
func plane(surfacetool, coord, direction):
	var dir=null
	if direction.x !=0:
		dir = sides["LEFT"] if direction.x<0 else sides["RIGHT"]
	if direction.y != 0:
		dir = sides["DOWN"] if direction.y<0 else sides["UP"]
	if direction.z != 0:
		dir = sides["FRONT"] if direction.z>0 else sides["BACK"]
	
	if false:
		var distance = Vector3(10,0,0)
		
		drawSide(surfacetool, sides["LEFT"], coord + distance)
		drawSide(surfacetool, sides["RIGHT"], coord + distance)
		drawSide(surfacetool, sides["UP"], coord + distance)
		drawSide(surfacetool, sides["DOWN"], coord + distance)
		drawSide(surfacetool, sides["FRONT"], coord + distance)
		drawSide(surfacetool, sides["BACK"], coord + distance)
		
	drawSide(surfacetool, dir, coord)
		
func drawSide(surfacetool, dir, coord):
	surfacetool.add_vertex(dir[0]+coord)
	surfacetool.add_vertex(dir[1]+coord)
	surfacetool.add_vertex(dir[2]+coord)

	surfacetool.add_vertex(dir[3]+coord)
	surfacetool.add_vertex(dir[2]+coord)	
	surfacetool.add_vertex(dir[1]+coord)