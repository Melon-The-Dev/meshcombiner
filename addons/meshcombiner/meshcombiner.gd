@tool
extends EditorPlugin

const BUTTON_SCENE = preload("uid://bx0fj8yclburb")

var button: Button

func _enter_tree():
	create_button()
	# Add button to the 3D editor top bar
	add_control_to_container(
		EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
		button
	)
	# Listen for selection changes
	get_editor_interface().get_selection().selection_changed.connect(
		_update_button_visibility
	)


func _exit_tree():
	remove_control_from_container(
		EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
		button
	)
	button.queue_free()

func create_button():
	button = BUTTON_SCENE.instantiate()
	button.pressed.connect(_on_button_pressed)

func _update_button_visibility():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	var mesh_count := 0

	for node in selection:
		if node is MeshInstance3D:
			mesh_count += 1

	# Show button only if 2 or more MeshInstance3D are selected
	button.visible = mesh_count >= 2

func _on_button_pressed():
	combine_meshes(get_editor_interface().get_selection().get_selected_nodes())

func combine_meshes(mesh_instances:Array):
	var combined = MeshInstance3D.new()
	var final_mesh = ArrayMesh.new()
	# --- Build combined mesh in world space ---
	for mi in mesh_instances:
		if mi is not MeshInstance3D:
			push_error("One of the elected nodes is not a mesh instance")
			return
		if mi == null or mi.mesh == null:
			continue
		var world_xform = mi.global_transform
		for s in range(mi.mesh.get_surface_count()):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(mi.mesh.surface_get_material(s))
			st.append_from(mi.mesh, s, world_xform)
			st.commit(final_mesh)
	# --- Calculate center of combined mesh ---
	var aabb: AABB = final_mesh.get_aabb()
	var center: Vector3 = aabb.position + aabb.size * 0.5
	# --- Rebuild mesh with centered origin ---
	var centered_mesh = ArrayMesh.new()
	for s in range(final_mesh.get_surface_count()):
		var mdt := MeshDataTool.new()
		mdt.create_from_surface(final_mesh, s)
		for i in range(mdt.get_vertex_count()):
			var v = mdt.get_vertex(i)
			mdt.set_vertex(i, v - center)
		mdt.commit_to_surface(centered_mesh)
	# --- Assign centered mesh ---
	combined.mesh = centered_mesh
	combined.global_transform = Transform3D.IDENTITY
	combined.name = "CombinedMesh"
	get_tree().edited_scene_root.add_child(combined,true)
	combined.owner = get_tree().edited_scene_root
	get_editor_interface().edit_node(combined)
	print("Meshes have been combined!")


func split_mesh_by_connectivity(mesh: ArrayMesh):
	var output: Array[ArrayMesh] = []

	if mesh.get_surface_count() == 0:
		return output

	# Process each surface independently
	for surface_idx in range(mesh.get_surface_count()):
		var mdt := MeshDataTool.new()
		mdt.create_from_surface(mesh, surface_idx)

		var vertex_count := mdt.get_vertex_count()

		# Track visited vertices
		var visited := PackedByteArray()
		visited.resize(vertex_count)

		# --- FIND CONNECTED COMPONENTS ---
		var components: Array[Array] = []

		for v in range(vertex_count):
			if visited[v] == 1:
				continue

			var stack := [v]
			var component := []

			while stack.size() > 0:
				var current := stack.pop_back()
				if visited[current] == 1:
					continue

				visited[current] = 1
				component.append(current)

				var edge_count = mdt.get_vertex_edge_count(current)
				for i in range(edge_count):
					var edge = mdt.get_vertex_edge(current, i)
					var v0 := mdt.get_edge_vertex(edge, 0)
					var v1 := mdt.get_edge_vertex(edge, 1)
					var other := v1 if v0 == current else v0

					if visited[other] == 0:
						stack.append(other)

			components.append(component)

		# --- BUILD NEW MESHES ---
		for component in components:
			var new_mdt := MeshDataTool.new()
			var vert_map := {}

			# Add vertices
			for v in component:
				var new_idx := new_mdt.get_vertex_count()
				vert_map[v] = new_idx

				new_mdt.add_vertex(mdt.get_vertex(v))
				new_mdt.set_vertex_normal(new_idx, mdt.get_vertex_normal(v))
				new_mdt.set_vertex_uv(new_idx, mdt.get_vertex_uv(v))
				new_mdt.set_vertex_color(new_idx, mdt.get_vertex_color(v))
				new_mdt.set_vertex_tangent(new_idx, mdt.get_vertex_tangent(v))

			# Add faces
			for f in range(mdt.get_face_count()):
				var a := mdt.get_face_vertex(f, 0)
				var b := mdt.get_face_vertex(f, 1)
				var c := mdt.get_face_vertex(f, 2)

				if vert_map.has(a) and vert_map.has(b) and vert_map.has(c):
					new_mdt.add_face(
						vert_map[a],
						vert_map[b],
						vert_map[c]
					)

			# Commit mesh
			var new_mesh := ArrayMesh.new()
			new_mdt.commit_to_surface(new_mesh)

			# Copy material
			var material := mesh.surface_get_material(surface_idx)
			if material:
				new_mesh.surface_set_material(0, material)

			output.append(new_mesh)

	for m in output:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		add_child(mi)
		mi.owner = get_tree().edited_scene_root
