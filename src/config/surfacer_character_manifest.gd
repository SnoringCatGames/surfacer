tool
class_name SurfacerCharacterManifest
extends ScaffolderCharacterManifest


func _parse_character_categories(categories_config: Array) -> void:
    for category_config in categories_config:
        assert(category_config.has("name"))
        assert(category_config.has("characters"))
        assert(category_config.has("movement_params"))
        assert(category_config.movement_params.has("collider_shape"))
        assert(category_config.movement_params.has("collider_rotation"))
        
        var category := SurfacerCharacterCategory.new()
        category.name = category_config.name
        category.characters = category_config.characters
        categories[category_config.name] = category
        
        var movement_params := MovementParameters.new()
        movement_params.belongs_to_a_category = true
        movement_params.character_name = category_config.name
        for key in category_config.movement_params:
            movement_params.set(key, category_config.movement_params[key])
        category.movement_params = movement_params


func _derive_movement_parameters() -> void:
    for category in categories.values():
        category.movement_params._is_ready = true
        category.movement_params._derive_parameters()
