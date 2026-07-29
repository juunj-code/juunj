class_name DataRegistryLoader
extends RefCounted
## Shared enumerate -> sort -> load -> duplicate-check utility for data
## registries (CompanionRegistry, EnemyRegistry). See ADR-0006.
## Stateless: each call is independent, holds no data itself.

## Loads every .tres file under folder_path, sorted ascending by filename
## (deterministic across editor/web export — directory scan order is not).
## reject_if_invalid(resource) -> bool: true means "load-rejection", not a
## soft warning (e.g. base_hp <= 0). Duplicate ids keep the sorted-first file.
## Returns Dictionary[String, Resource] keyed by each resource's "id" field.
static func load_all(folder_path: String, reject_if_invalid: Callable) -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_error("DataRegistryLoader: cannot open folder %s" % folder_path)
		return result

	var filenames: Array[String] = []
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tres"):
			filenames.append(filename)
		filename = dir.get_next()
	dir.list_dir_end()
	filenames.sort()

	for fname in filenames:
		var resource: Resource = load(folder_path.path_join(fname))
		if resource == null:
			push_error("DataRegistryLoader: failed to load %s" % fname)
			continue
		if reject_if_invalid.call(resource):
			push_error("DataRegistryLoader: rejected invalid resource in %s" % fname)
			continue
		var id: String = resource.get("id")
		if result.has(id):
			push_error("DataRegistryLoader: duplicate id '%s' in %s (keeping first by sort order)" % [id, fname])
			continue
		result[id] = resource

	return result
