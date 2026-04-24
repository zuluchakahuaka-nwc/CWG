extends RefCounted

func find_path(from_id: String, to_id: String, side: String, max_distance: int = 2) -> Array:
	if from_id == to_id:
		return [from_id]
	var visited: Dictionary = {from_id: 0}
	var queue: Array = [{"id": from_id, "distance": 0, "path": [from_id]}]
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		if current["distance"] >= max_distance:
			continue
		var adjacent: Array = CardDatabase.get_adjacent_territories(current["id"])
		for adj_id in adjacent:
			if visited.has(adj_id) and visited[adj_id] <= current["distance"] + 1:
				continue
			var adj_owner: String = GameManager.get_territory_owner(adj_id)
			var adj_data: Dictionary = CardDatabase.get_territory(adj_id)
			var terrain: String = adj_data.get("terrain", "plains")
			var move_cost: float = _get_movement_cost(terrain)
			var new_distance: int = current["distance"] + 1
			visited[adj_id] = new_distance
			var new_path: Array = current["path"].duplicate()
			new_path.append(adj_id)
			if adj_id == to_id:
				return new_path
			if adj_owner == side or adj_owner == "neutral":
				queue.append({"id": adj_id, "distance": new_distance, "path": new_path})
	return []

func find_reachable_territories(from_id: String, side: String, max_distance: int = 2) -> Array:
	var reachable: Array = []
	var visited: Dictionary = {from_id: true}
	var queue: Array = [{"id": from_id, "distance": 0}]
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		if current["distance"] >= max_distance:
			continue
		var adjacent: Array = CardDatabase.get_adjacent_territories(current["id"])
		for adj_id in adjacent:
			if visited.has(adj_id):
				continue
			visited[adj_id] = true
			var adj_data: Dictionary = CardDatabase.get_territory(adj_id)
			var terrain: String = adj_data.get("terrain", "plains")
			reachable.append({"id": adj_id, "distance": current["distance"] + 1, "terrain": terrain})
			queue.append({"id": adj_id, "distance": current["distance"] + 1})
	return reachable

func get_path_distance(path: Array) -> float:
	var total: float = 0.0
	for i in range(1, path.size()):
		var t: Dictionary = CardDatabase.get_territory(path[i])
		total += _get_movement_cost(t.get("terrain", "plains"))
	return total

func _get_movement_cost(terrain: String) -> float:
	var costs: Dictionary = {
		"plains": 1.0, "hills": 0.8, "forest": 0.7, "river": 0.5,
		"city": 0.5, "swamp": 0.4, "mountain": 0.3
	}
	return costs.get(terrain, 1.0)
