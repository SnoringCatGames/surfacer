# Other features

## Annotators

We include a large collection of annotators that are useful for visually debugging calculation of the platform graph. Some of these are rendered by selecting entries in the platform graph inspector and some of them can be toggled through checkboxes in the inspector panel.

## Movement parameters

We support a large number of flags and parameters for adjusting various aspects of character/movement/platform-graph behavior. For a complete list of these character-level params, see [movement_params.gd](/src/platform_graph/edge/models/movement_params.gd).

Also, [sc.gd](https://github.com/SnoringCatGames/scaffolder/blob/master/src/config/sc.gd) and [su.gd](/src/config/su.gd) contain lists of interesting app-level params.

## Extensible framework for custom movement mechanics

In order to implement low-level movement mechanics, Surfacer uses an extensible character action-handler system. An "action handler" is called each frame and defines some basic rule for how character movement should be updated depending on the current context.

Here are some examples:
-   The floor-friction action handler offsets the horizontal velocity depending on what surface the character is standing on.
-   The in-air default action handler offsets the velocity according to either slow-rise or fast-fall gravity.
-   The wall-jump action handler sets the velocity for a new jump.

Each action handler is specific to a certain surface type—floor, wall, ceiling, in-air—and only the action-handlers for the current surface type are triggered each frame.

You can register the specific action handlers your game uses in your app manifest.

The benefit of this system is that it is highly decoupled, so it is very easy to make changes or add new mechanics. When creating a platformer game, these atomic movement mechanics tend to be very hard to keep separate. Consequently, the core movement logic for most platformers is a bunch of very brittle spaghetti code.

Look at the code under [`/src/character/action/action_handlers/`](`/src/character/action/action_handlers/`) for examples.

> **NOTE:** The procedural pathfinding logic is implemented independently of the action-handler system. So, you can use this to add cool new movement for player-controlled movement, but the automatic pathfinding will only know about the default built-in mechanics that it was designed around.

## Behaviors

> **TODO:** Describe the high-level character behavior system.

Look at the code under [`/src/character/behaviors/behavior.gd`](`/src/character/behaviors/behavior.gd`) for examples.
