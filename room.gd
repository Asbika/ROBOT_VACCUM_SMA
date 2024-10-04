extends Node3D

const SALON_SIZE_X = 20.0
const SALON_SIZE_Z = 20.0
const NOMBRE_TACHES = 30
var taches_generes = false
var occupied_positions: Array = []

func _ready():
	if not taches_generes:
		_generer_taches_salle()
		taches_generes = true

func _generer_taches_salle():
	for i in range(NOMBRE_TACHES):
		var position_aleatoire = _get_random_position()
		var tache = MeshInstance3D.new()

		# Ajoutez une propriété pour savoir si la tâche a été nettoyée
		tache.set("is_cleaned", false)

		var mesh = PlaneMesh.new()
		mesh.size = Vector2(randf_range(0.5, 1.0), randf_range(0.5, 1.0))
		tache.mesh = mesh

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.15, 0.1)
		material.roughness = 1.0
		material.metallic = 0.0

		tache.material_override = material
		tache.rotation_degrees.y = randf_range(0, 360)
		tache.global_transform.origin = position_aleatoire

		add_child(tache)
		tache.add_to_group("grime_spots")

		print("Tâche de saleté ajoutée à la position : ", position_aleatoire)

func _get_random_position() -> Vector3:
	var position: Vector3
	var overlaps = true

	while overlaps:
		var pos_x = randf_range(-SALON_SIZE_X / 2, SALON_SIZE_X / 2)
		var pos_z = randf_range(-SALON_SIZE_Z / 2, SALON_SIZE_Z / 2)
		position = Vector3(pos_x, 0.5, pos_z)

		overlaps = false
		for occupied in occupied_positions:
			if position.distance_to(occupied) < 1.0:
				overlaps = true
				break

	occupied_positions.append(position)
	return position
