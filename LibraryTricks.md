# Introduction #

Using folders in the library it is possible to have both a dd\_tile\_list and a regular TileList component on the Stage simultaneously.


# Details #

Put the first TileList component you drag from the Component Panel to the Stage in a folder then drag another TileList from the Component Panel to the Stage, not the Library.  Then change the component linkage of one or the other TileList components in the Library from fl.controls.TileList to com.jeremyrodgers.dd\_tile\_list.

Here is a screenshot of what your library would look like in this case.  In this way you can still use both dd\_tile\_list and TileList in the same FLA using stage instances.

![http://jeremyrodgers.com/dd_tile_list/TileList-Library-Example.gif](http://jeremyrodgers.com/dd_tile_list/TileList-Library-Example.gif)

Alternatively you can place the dd\_tile\_list and TileList components separately through code.  Compiled component is on the TODO list.