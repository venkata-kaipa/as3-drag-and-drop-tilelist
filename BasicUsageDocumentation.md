# Introduction #

Example code for dd\_tile\_list usage.

# Assumptions #
2 stage instances of dd\_tile\_list:
  * ddt\_pool - source for drag
  * ddt\_selection - target for drop

# Code #

```
function init_ddt_pool():void
{
	ddt_pool.rowCount = 1;
	ddt_pool.rowHeight = 96;
	ddt_pool.columnWidth = 128;
	ddt_pool.height = (96*1) + 16;
	ddt_pool.direction = ScrollBarDirection.HORIZONTAL;
	
	ddt_pool.canDragFrom = true;
	ddt_pool.dragRemovesItem = false;
	ddt_pool.dropOffRemovesItem = false;
	ddt_pool.canDropOn = false;
	ddt_pool.dragAlpha = .43;
	ddt_pool.autoScroll = false;
	ddt_pool.scrollZone = .15;
	ddt_pool.scrollSpeed = 3;
	ddt_pool.allowDuplicates = false;

	dp_pool = new DataProvider( new XML( "<items>"+ image_xml +"</items>" ) );
	ddt_pool.dataProvider = dp_pool;
}

function init_ddt_selection():void
{
	ddt_selection.rowCount = 1;
	ddt_selection.rowHeight = 96;
	ddt_selection.columnWidth = 128;
	ddt_selection.height = (96 * 1) + 16;
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

	ddt_selection.dataProvider = new DataProvider( new XML() );

	ddt_selection.addEventListener( dd_tile_list.DUPLICATE_DENIED, dd_denied );
}

public function my_compare( _o:Object, _tl:dd_tile_list ):Boolean
{
	var dp:Array = _tl.dataProvider.toArray();
	for( var m:int = 0; m < dp.length; m++ ) {
		if( _o.source == dp[m].source ) {
			return true;
		}
	}
	return false;
}
```