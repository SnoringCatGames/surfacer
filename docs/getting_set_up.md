# Getting set up

I will not lie, **this is a complex framework**! Hopefully it's external API isn't _too_ convoluted, but still, probably the easiest way to get set up is to copy the [Squirrel Away example app](https://github.com/snoringcatgames/squirrel-away), and then adjust it to fit your needs.

-   Set up Scaffolder
    -   https://github.com/snoringcatgames/scaffolder/docs/getting_set_up.md
-   `addons/scaffolder`
    -   Add the [Scaffolder](https://github.com/snoringcatgames/scaffolder/) library to your `addons/` folder.
    -   This is a framework that provides assorted general-purpose infrastructure that can be useful for adding a bunch of app boilerplate that you may or may not want for your game.
    -   Surfacer currently depends on this additional framework.
    -   See the Scaffolder [README](https://github.com/snoringcatgames/scaffolder/README.md) for details on setting it up.
-   `addons/crypto_uuid_v4`
    -   Add the [Crypto UUID v4](https://godotengine.org/asset-library/asset/748) library to your `addons/` folder.
-   `addons/surfacer`
    -   Add the [Surfacer](https://github.com/snoringcatgames/surfacer/) library to your `addons/` folder.
-   `Sc`
    -   Define `Sc` as an AutoLoad (in Project Settings).
    -   "Sc" is short for "Scaffolder."
    -   It should point to the path `res://addons/scaffolder/src/sc.gd`.
    -   It should be the first AutoLoad in the list.
-   `Su`
    -   Define `Su` as an AutoLoad (in Project Settings).
    -   "Su" is short for "Surfacer."
    -   It should point to the path `res://addons/surfacer/src/su.gd`.
    -   It should be the second AutoLoad in the list, just after `Sc`.
-   Input Map
    -   Define the following input keys in Project Settings > Input Map:
        -   ui_accept
        -   ui_select
        -   ui_cancel
        -   ui_back
        -   ui_left
        -   ui_right
        -   ui_up
        -   ui_down
        -   zoom_in
        -   zoom_out
        -   pan_left
        -   pan_right
        -   pan_up
        -   pan_down
        -   screenshot
        -   jump
        -   move_left
        -   move_right
        -   move_up
        -   move_down
        -   dash
        -   face_left
        -   face_right
        -   grab_wall
-   `app_manifest`
    -   Define configuration parameters for Scaffolder and Surfacer.
    -   There are a _lot_ of parameters you can adjust here.
    -   Most of these parameters are for Scaffolder.
    -   Probably the easiest way to get started with this is to copy/paste/edit the pre-existing app-configuration from the Squirrel Away example app.
-   `Sc.run(app_manifest)`
    -   Configure both the Surfacer and Scaffolder frameworks by calling `Sc.run(app_manifest)` as early as possible in your application.
-   Include `*.json` under "Filters to export non-resource files/folders" in your export settings.
    -   Platform graphs can be pre-calculated and saved in JSON files.

> **NOTE**: The Scaffolder framework is _big_. It probably has a lot of stuff you don't need. Also, it probably structures things differently than you want. You should be able either hide or ignore the bits from Scaffolder that you don't want. Ideally, Surfacer shouldn't depend on Scaffolder. But decoupling these frameworks hasn't been a priority yet. Sorry!

## Creating a level

_Probably the easiest way to get started with this is to copy/paste/edit the pre-existing level class from the Squirrel Away example app._

Hopefully, you shouldn't need to define too much level logic to make Surfacer happy.

The main thing to know is that you will need to instance a `CollidableTileMap` as a sub-scene in order to define the shape of your level.

## Creating a player

In order to create a new player type, you'll need to override a few classes from Surfacer.

_Probably the easiest way to get started with this is to copy/paste/edit a pre-existing player from the Squirrel Away example app._

-   `Player`
    -   This defines how your player reacts to input and decides when and were to navigate within the level.
-   `PlayerAnimator`
    -   This defines how your player is rendered and animated.
    -   Surfacer makes some opinionated assumptions about how this will be set-up, but you can probably adjust or ignore some of this to fit your needs.
-   [`MovementParams`](./src/platform_graph/edge/models/movement_params.gd)
    -   This defines how your player will move.
    -   There are a _lot_ of parameters you can adjust here.

## Expected console errors

When closing your game, you may see the following errors printed in the console. These are due to an underlying bug in Godot's type system. Godot improperly handles circular type references, and this leads to false-positives in Godot's memory-leak detection system.

```
ERROR: ~List: Condition "_first != __null" is true.
   At: ./core/self_list.h:112
ERROR: ~List: Condition "_first != __null" is true.
   At: ./core/self_list.h:112
WARNING: cleanup: ObjectDB instances leaked at exit (run with --verbose for details).
     At: core/object.cpp:2132
ERROR: clear: Resources still in use at exit (run with --verbose for details).
   At: core/resource.cpp:450
ERROR: There are still MemoryPool allocs in use at exit!
   At: core/pool_vector.cpp:66
```
