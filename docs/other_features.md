# Other features

## Annotators

We include a large collection of annotators that are useful for visually debugging calculation of the platform graph. Some of these are rendered by selecting entries in the platform graph inspector and some of them can be toggled through checkboxes in the inspector panel.

## Movement parameters

We support a large number of flags and parameters for adjusting various aspects of player/movement/platform-graph behavior. For a complete list of these player-level params, see [movement_params.gd](/src/platform_graph/edge/models/movement_params.gd).

Also, [sc.gd](https://github.com/SnoringCatGames/scaffolder/blob/master/src/config/sc.gd) and [su.gd](/src/config/su.gd) contain lists of interesting app-level params.

## Extensible framework for custom movement mechanics

> TODO: Describe this system. For now, look at the code under `src/player/action/action_handlers/` for examples.

> **NOTE:** The procedural pathfinding logic is implemented independently of this framework. So, you can use this to add cool new movement for human-controlled movement, but the automatic pathfinding will only know about the specific default mechanics that it was designed around.
