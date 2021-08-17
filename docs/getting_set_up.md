# Getting set up

I will not lie, **this is a complex framework**! Hopefully it's external API isn't _too_ convoluted, but still, probably the easiest way to get set up is to copy the [Squirrel Away example app](https://github.com/snoringcatgames/squirrel_away), and then adjust it to fit your needs.

-   Set up Scaffolder
    -   https://github.com/snoringcatgames/scaffolder/blob/master/docs/getting_set_up.md
-   `addons/scaffolder`
    -   Add the [Scaffolder](https://github.com/snoringcatgames/scaffolder/) library to your `addons/` folder.
    -   This is a framework that provides assorted general-purpose infrastructure that can be useful for adding a bunch of app boilerplate that you may or may not want for your game.
    -   Surfacer currently depends on this additional framework.
    -   See the Scaffolder [README](https://github.com/snoringcatgames/scaffolder/blob/master/README.md) for details on setting it up.
-   `addons/crypto_uuid_v4`
    -   Add the [Crypto UUID v4](https://godotengine.org/asset-library/asset/748) library to your `addons/` folder.
-   `addons/surfacer`
    -   Add the [Surfacer](https://github.com/snoringcatgames/surfacer/) library to your `addons/` folder.
-   `Sc`
    -   Define `Sc` as an AutoLoad (in Project Settings).
    -   "Sc" is short for "Scaffolder".
    -   It should point to the path `res://addons/scaffolder/src/sc.gd`.
    -   It should be the first AutoLoad in the list.
-   `Su`
    -   Define `Su` as an AutoLoad (in Project Settings).
    -   "Su" is short for "Surfacer".
    -   It should point to the path `res://addons/surfacer/src/su.gd`.
    -   It should be the second AutoLoad in the list, just after `Sc`.
-   `app_manifest`
    -   Define configuration parameters for Scaffolder and Surfacer.
    -   There are a _lot_ of parameters you can adjust here.
    -   Most of these parameters are for Scaffolder.
    -   Probably the easiest way to get started with this is to copy/paste/edit the pre-existing app-configuration from the Squirrel Away example app.
-   `Sc.run(app_manifest)`
    -   Configure both the Surfacer and Scaffolder frameworks by calling `Sc.run(app_manifest)` as early as possible in your application.
-   Include `*.json` under "Filters to export non-resource files/folders" in your export settings.
    -   Platform graphs can be pre-calculated and saved in JSON files.

> **NOTE**: The Scaffolder framework is _big_. It probably has a lot of stuff you don't need. Also, it probably structures things differently than you want. You should be able to either hide or ignore the bits from Scaffolder that you don't want. Ideally, Surfacer shouldn't depend on Scaffolder. But decoupling these frameworks hasn't been a priority yet. Sorry!

## Creating a level

In order to create levels, you'll need to override a few classes from Surfacer.

_Probably the easiest way to get started with this is to copy/paste/edit the pre-existing level class from the Squirrel Away example app._

-   [`SurfacerLevel`](/src/level/surfacer_level.gd).
-   [`SurfacesTileMap`](/src/platform_graph/surfaces_tile_map.gd):
    -   You will need to instance `SurfacesTileMap` as a sub-scene in order to define the shape of the collidable surfaces your level.
-   [`SurfacerLevelConfig`](/src/config/surfacer_level_config.gd):
    -   You will need to sub-class `SurfacerLevelConfig` and reference this in your `app_manifest`.
    -   This defines some metadata for each of the levels in your game. For example:
        -   `name`: The display name for the level.
        -   `sort_priority`: The level's position relative to other levels.
        -   `unlock_conditions`: How and when the level is unlocked.
        -   `platform_graph_character_names`: The names of the characters that might appear in the level. A platform graph will need to be calculated for each of these characters.

## Creating a character

In order to create a new character type, you'll need to override a few classes from Surfacer.

_Probably the easiest way to get started with this is to copy/paste/edit a pre-existing character from the Squirrel Away example app._

-   [`SurfacerCharacter`](/src/character/surfacer_character.gd)
    -   This defines how your character reacts to input and decides when and were to navigate within the level.
    -   Required children:
        -   `MovementParameters`
        -   `ScaffolderCharacterAnimator`
        -   `CollisionShape2D`
    -   `collision_detection_layers`
        -   This helps your `SurfacerCharacter` detect when other areas or bodies collide with the character.
        -   The default `PhysicsBody2D.collision_layer` property is limited, because the `move_and_slide` system will adjust our movement when we collide with matching objects.
        -   So this separate `collision_detection_layers` property lets us detect collisions without adjusting our movement.
    -   `ProximityDetector`
        -   This helps your `SurfacerCharacter` detect when other areas or bodies enter or exit the proximity of your character.
        -   You can declare these as children in your SurfacerCharacter scenes.
        -   You can configure the shape used to define the proximity range.
-   [`ScaffolderCharacterAnimator`](https://github.com/snoringcatgames/scaffolder/blob/master/src/character/scaffolder_character_animator.gd)
    -   This defines how your character is rendered and animated.
    -   Surfacer makes some opinionated assumptions about how this will be set-up, but you can probably adjust or ignore some of this to fit your needs.
    -   `uses_standard_sprite_frame_animations`
        -   Set this export property to `true` if you want to set up all of the animations for this character by changing the `frame` property on a corresponding `Sprite`.
        -   If this is enabled, then the `ScaffolderCharacterAnimator` will expect there to be a one-to-one mapping between immediate-child `Sprites` and animations in the `AnimationPlayer`, and these matching animations and Sprites will need to share the same names.
    -   `animations`
        -   This `Dictionary` is auto-populated with keys corresponding to each animation in the `AnimationPlayer`.
        -   You can configure some additional state for each of the animation configs in this dictionary, such as the default playback speed for the animation, and the name of a `Sprite` to automatically show when starting the animation.
-   [`MovementParameters`](/src/platform_graph/edge/models/movement_params.gd)
    -   This defines how your character will move.
    -   There are a _lot_ of parameters you can adjust here.
    -   You can adjust these parameters within the editor's inspector panel.
