extends CharacterBody3D

const SPEED = 5.0
const DETECTION_RADIUS = 15.0
const CLEANING_TIME = 4.0
const SPOT_COUNT_RADIUS = 15.0

var direction = Vector3.ZERO
var current_grime_spot: Node = null
var cleaning_timer = 0.0
var detected_grime_spots: Array = []
var my_spot_data: Dictionary = {}
static var global_task_data: Dictionary = {}  # Variable de classe partagée entre tous les robots

func _ready():
	_change_direction()

func _physics_process(delta: float) -> void:
	_check_proximity_to_grime_spots()  # Ajouté ici pour vérifier les taches à chaque cycle
	if is_instance_valid(current_grime_spot):
		_clean_grime_spot(delta)
	else:
		_move_randomly(delta)

	_update_global_task_data()
	_check_other_robot_tasks()
	_display_robot_data()

	# Appel de la fonction pour afficher le contenu du tableau
	_display_robot_data()

func _check_proximity_to_grime_spots() -> void:
	var grime_spots = get_tree().get_nodes_in_group("grime_spots")
	detected_grime_spots.clear()

	for spot in grime_spots:
		if spot and global_transform.origin.distance_to(spot.global_transform.origin) < DETECTION_RADIUS:
			detected_grime_spots.append(spot)

	if detected_grime_spots.size() > 0 and current_grime_spot == null:
		current_grime_spot = detected_grime_spots[randi() % detected_grime_spots.size()]
		print("Detected a grime spot at: ", current_grime_spot.global_transform.origin)

func _move_randomly(delta: float) -> void:
	if randf() < 0.02:
		_change_direction()

	velocity = direction * SPEED
	move_and_slide()

func _clean_grime_spot(delta: float) -> void:
	# Vérifier que la tâche n'a pas été supprimée avant de l'utiliser
	if is_instance_valid(current_grime_spot):
		if global_transform.origin.distance_to(current_grime_spot.global_transform.origin) < 1.0:
			cleaning_timer += delta

			if cleaning_timer >= CLEANING_TIME:
				print("Cleaned the grime spot at: ", current_grime_spot.global_transform.origin)
				current_grime_spot.queue_free()  # Supprimer la tâche
				print("Grime spot deleted")
				current_grime_spot = null  # Réinitialiser pour éviter d'utiliser une tâche supprimée
				cleaning_timer = 0.0
		else:
			_move_toward_grime_spot()
	else:
		current_grime_spot = null  # Si l'instance n'est plus valide, la réinitialiser

func _move_toward_grime_spot() -> void:
	# Vérifier la validité de la tâche avant de l'utiliser
	if is_instance_valid(current_grime_spot):
		var direction_to_target = (current_grime_spot.global_transform.origin - global_transform.origin).normalized()
		velocity = direction_to_target * SPEED
		move_and_slide()

# Mise à jour des données locales du robot dans le tableau global
func _update_global_task_data() -> void:
	my_spot_data.clear()  # Réinitialiser les données du robot
	var grime_spots = get_tree().get_nodes_in_group("grime_spots")
	var count = 0

	for spot in grime_spots:
		if spot and global_transform.origin.distance_to(spot.global_transform.origin) < SPOT_COUNT_RADIUS:
			count += 1

	my_spot_data["robot_position"] = global_transform.origin
	my_spot_data["grime_spot_count"] = count
	global_task_data[get_instance_id()] = my_spot_data  # Mettre à jour global_task_data

# Fonction pour vérifier si un autre robot a trouvé des tâches
func _check_other_robot_tasks() -> void:
	if my_spot_data["grime_spot_count"] == 0:
		print("Robot ", get_instance_id(), " has no tasks, checking other robots.")
		print("**", my_spot_data)
		for robot_id in global_task_data.keys():
			print("[[", global_task_data.keys(), "]", robot_id, "]", get_instance_id())
			if robot_id != get_instance_id() and global_task_data[robot_id]["grime_spot_count"] > 0:
				var other_robot_position = global_task_data[robot_id]["robot_position"]
				print("Robot", robot_id, "has tasks, moving to assist at", other_robot_position)
				
				_move_toward_position(other_robot_position)
				return

# Déplacer le robot vers une position donnée
func _move_toward_position(target_position: Vector3) -> void:
	var direction_to_target = (target_position - global_transform.origin).normalized()
	velocity = direction_to_target * SPEED
	move_and_slide()

func _change_direction() -> void:
	var angle = randf_range(0, TAU)
	direction = Vector3(cos(angle), 0, sin(angle)).normalized()

# Fonction pour afficher le contenu de toutes les données globales
func _display_robot_data() -> void:
	print("Données globales des robots:", global_task_data)
	print("Robot ID:", get_instance_id())
	print("Données locales du robot:", my_spot_data)
