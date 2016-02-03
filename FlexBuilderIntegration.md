# Introduction #
The problem is:

```
Severity and Description        Path    Resource        Location        Creation Time   Id
1017: defintion of baseclass TileList not found [translation]. DragDrop/src/com/jeremyrodgers  dd_tile_list.as line 78 1222794066718   2722
```

After importing a TileList via `import mx.controls.TileList;` I get 13 errors. Changing the import `fl.*` statements to `import mx.*`, I can reduce errors to 9 (`import mx.data.*;` still produces an error, of course). These errors are related to classes CellRenderer and Scrollbar and its references.

Solution: add the attached `.swc`<sup>1</sup> to your Flex Builder's library path. The link http://www.moock.org/blog/archives/000253.html explains how to in every detail.

What I did in Flash CS3: dragged a TileList from components to library. Export it, include `.swc`-file and u r done.

Thanks to Stefan Dierdorf for the solution.

<sup>1</sup> download dd_TileList.swc in the Downloads section._

# Details #
Given a dd\_tile\_list named ddt\_selection:
```
private function init_ddt_selection():void
{
   var ddt_selection:dd_tile_list = new dd_tile_list();

   ddt_selection.rowCount = 1;
   ddt_selection.rowHeight = 96;
   ddt_selection.columnWidth = 128;
   ddt_selection.height = (96 * 2) + 16;
   ddt_selection.width = 500;
   ddt_selection.direction = ScrollBarDirection.HORIZONTAL;

   ddt_selection.canDragFrom = true;
   ddt_selection.dragRemovesItem = true;
   ddt_selection.dropOffRemovesItem = true;
   ddt_selection.canDropOn = true;
   ddt_selection.autoScroll = true;
   ddt_selection.dragAlpha = .63;
   ddt_selection.scrollZone = .1;
   ddt_selection.scrollSpeed = 5;
   ddt_selection.allowDuplicates = false;
   ddt_selection.compareFunction = my_compare;

   ddt_selection.dataProvider = new DataProvider( new XML( "<items><item source='assets/stinkefinger.gif'/><item source='assets/globe.jpg'/></items>" ) );

   ddt_selection.addEventListener( dd_tile_list.DUPLICATE_DENIED, dd_denied );

   // This is the important part since Flex can only handle UIComponents visually.
   var wrapper:UIComponent = new UIComponent();
   wrapper.addChild(ddt_selection);
   dd_canvas.addChild(wrapper);
}
```