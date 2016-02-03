### Description ###
The dd\_tile\_list class extends the as3 TileList component to add drag and drop functionality.  Dropping between components is supported.
This class aims to be CellRenderer and Style agnostic.

### Example ###
  * Basic: http://jeremyrodgers.com/dd_tile_list/index.html
  * Video: http://jeremyrodgers.com/dd_tile_list/example2.html

if you have something you want to show send a url to: [jeremymrodgers@gmail.com](mailto:jeremymrodgers@gmail.com)
I'd like to see what, if anything, is being done with this project. Please indicate in the message if I can post the link here.

### Properties ###
There are several options to configure the behaviour:
  * Inspectable Public Properties
    * canDragFrom (t/f)
    * dragRemovesItem (t/f)
    * dropOffRemovesItem (t/f)
    * canDropOn (t/f)
    * dragAlpha (0:1)
    * autoScroll (t/f) (autoScroll works in both horizontal and vertical TileList directions.)
    * scrollZone (0:1)
    * scrollSpeed (1:10)
    * allowDuplicates (t/f)

  * Uninspectable Public Properties
    * compareFunction (function)

### Events ###
  * ITEM\_ADDED
  * ITEM\_REMOVED
  * DUPLICATE\_DENIED
  * LIST\_REORDERED
  * ITEM\_DROPPED (new in v.7)
  * ITEM\_DROPPED\_INSIDE (new in v.7)
  * ITEM\_DROPPED\_INSIDE\_SELF (new in v.7)
  * ITEM\_DROPPED\_INSIDE\_OTHER (new in v.7)
  * ITEM\_DROPPED\_OUTSIDE (new in v.7)

### Methods ###
  * halt() - removes listeners, stops timer and removes drag\_item.

### Not implemented ###
  * multiple selections.
  * grouping of components. (this should be possible in v.7+ although no example exists).

### Notes ###
  * the drag item is placed on the stage DisplayObjectContainer.
  * the ITEM\_ADDED and ITEM\_REMOVED events are not fired when re-ordering within a dd\_tile\_list instance, instead a LIST\_REORDERED event occurs.
  * I haven't built the component yet so this needs to be instantiated in code or you can [change the linkage of TileList in the library](http://code.google.com/p/as3-drag-and-drop-tilelist/wiki/LibraryTricks).

### News ###
  * Version 8 released. May.30.2010
    * Fixed issue ID #1: "Bug while drag and drop in same list", thanks to winxalex for the fix.
    * Added a public accessor, drag\_item to directly reference the CellRenderer which is being dragged.  I needed this to get the mouse offset to determine exact position for an ITEM\_DROPPED\_OUTSIDE operation.
  * Version 7 released. Nov.11.2009 (contributed by Frank McGuire, thanks Frank!)
    * Possible to use 'wrapper' classes with 'dd\_tile\_list' as a base class to restrict drag-drop interaction between groups of TileLists.
    * Made the positioning 'arrow' work with vertical TileLists. (arrowRotation)
    * Made selected TileLists accept a list of alternate drop target objects.
    * Made individual TileList ImageCells accept a list of alternate drop target objects.
    * Added events:
      * ITEM\_DROPPED
      * ITEM\_DROPPED\_INSIDE
      * ITEM\_DROPPED\_INSIDE\_SELF
      * ITEM\_DROPPED\_INSIDE\_OTHER
      * ITEM\_DROPPED\_OUTSIDE
    * Added properties:
      * arrowRotation
      * arrowVisibility
      * arrowPosition
      * alt\_drop\_targets
    * Added methods:
      * addDropTarget
    * General Notes:  The MC in each RenderCell or ImageCell may also have an '_alt\_drop\_targets' list and a '_class\_name' var to make the alternate drop target specific to the RC or IC Alternate drop targets can be handled by ITEM\_DROPPED\_OUTSIDE listener classes.
  * Version 6 released.
    * Added halt() function - clean up listeners, timer and remove drag\_item.
    * Changed some internals:
      * `_ic.data.listData` is now just `_ic.listData`
      * `_ic.data.index` is now just `_ic.listData.index`
      * this makes more sense and fixes a bug I had with a custom CellRenderer.
      * `_drag_item.data` is now populated on start of drag.
      * LIST\_REORDERED fires when reordering within a dd\_tile\_list
  * Version 5 released.
    * Added code contributed by [Mathias Wedeken](mailto:mathiaswedeken@gmail.com) to report ITEM\_ADDED and ITEM\_REMOVED events.
    * These events are not fired when re-ordering within a dd\_tile\_list instance.
    * Added the example.xml file back to the Example download - sorry 'bout that, thanks for pointing it out Mathias.
  * Version 4 released.
    * New method to determine TileList and CellRenderer under mouse, fixes a problem with as2 swf files in TileList.
    * Should be compatible with previous versions.
    * emBRACE-ing new code formatting.
  * Version 3 released.
    * Added compare function override.
  * Version 2 released.
    * Fixed a bug which used the source scrollSpeed setting instead of the target scrollSpeed setting.
    * Added a feature to determine if drop should add to the left or right side of the dropTarget.
    * Added a feature which scrolls the target dd\_tile\_list to always show the newly added item.