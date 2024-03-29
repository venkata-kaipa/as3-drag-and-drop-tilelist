//--------------------------------------
//  License: New BSD License
//--------------------------------------
/**
Copyright (c) 2008, Jeremy Rodgers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that
the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of conditions and the
		 following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
		 the following disclaimer in the documentation and/or other materials provided with the distribution.
	* Neither the name of Jeremy Rodgers nor the names of its contributors may be used to endorse or promote
		 products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.
*/
package com.jeremyrodgers {
		
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import flash.geom.*;
	import fl.controls.*;
	import fl.controls.listClasses.*;
	import fl.events.*;
	import fl.data.*;
	import fl.core.*;
	
	//--------------------------------------
	//  Class description
	//--------------------------------------
	/**
	* The dd_tile_list class provides drag and drop functionality to the TileList
	* class.  Dropping between components is supported, there are several options
	* to configure the behaviour.
	*
	* Usage:
	*  ddt = new dd_tile_list();
	*
	*  -- TileList Config --
	*  ddt.rowCount = 1;
	*  ddt.rowHeight = 96;
	*  ddt.columnWidth = 128;
	*  ddt.height = 96 + 16; // height plus scroll bar height.
	*  ddt.direction = ScrollBarDirection.HORIZONTAL;
	*  ddt.dataProvider = new DataProvider( new XML( "<items><item label="first" source="first.jpg"/></items>" ) );
	*  ddt.addEventListener( MouseEvent.DOUBLE_CLICK, show_properties );
	*
	*  -- dd_tile_list Config --
	*  ddt.canDragFrom = true;
	*  ddt.dragRemovesItem = true;
	*  ddt.dropOffRemovesItem = true;
	*  ddt.canDropOn = true;
	*  ddt.dragAlpha = .43;
	*  ddt.autoScroll = true;
	*  ddt.scrollZone = .15;
	*  ddt.scrollSpeed = 3;
	*  ddt.allowDuplicates = false;
	*  // ddt.addEventListener( dd_tile_list.DUPLICATE_DENIED, dd_denied );
	*
	* @see fl.controls.listClasses.TileList
	*
	* @author Jeremy Rodgers
	* @langversion 3.0
	* @playerversion Flash 9.0.28.0
	*/
	public class dd_tile_list extends TileList {

		/* Events */
		public static  var ITEM_ADDED:String = "item_added";// TODO: Custom event classes.
		public static  var ITEM_REMOVED:String = "item_removed";
		public static  var DUPLICATE_DENIED:String = "duplicate_denied";
		public static  var LIST_REORDERED:String = "list_reordered";
		// fpm: begin ======
		public static  var ITEM_DROPPED:String = "item_dropped";
		public static  var ITEM_DROPPED_INSIDE:String = "item_dropped_inside";
		public static  var ITEM_DROPPED_INSIDE_SELF:String = "item_dropped_inside_self";
		public static  var ITEM_DROPPED_INSIDE_OTHER:String = "item_dropped_inside_other";
		public static  var ITEM_DROPPED_OUTSIDE:String = "item_dropped_outside";
		// fpm: end ========

		/* Inspectable */
		private var _can_drag_from					:Boolean = true;
		private var _drag_removes_item				:Boolean = true;
		private var _drop_off_removes_item			:Boolean = true;
		private var _can_drop_on					:Boolean = true;
		private var _drag_alpha						:Number = .83;
		private var _auto_scroll					:Boolean = true;
		private var _scroll_zone					:Number = .1;
		private var _scroll_speed					:Number = 4;
		private var _allow_duplicates				:Boolean = true;
		
		/* Private */
		private var _ic:Object;		// ImageCell
		private var _class_name:String;
		private var _dragging:Boolean;
		private var _drag_item:CellRenderer;
		private var _drag_item_loader:Loader;
		private var _ti:Timer;
		private var _scroll_interval:Number = 20;
		private var _scroll_left:Number; // Calculated
		private var _scroll_right:Number; // Calculated
		private var _scroll_bottom:Number; // Calculated
		private var _scroll_top:Number; // Calculated
		private var _drop_arrow:dd_drop_arrow;
		private var _compare_function:Function;

		// fpm: begin ======
		// alternate drop target list for TL
		private var _alt_drop_targets:Array;
		// Note: The MC in each RenderCell or ImageCell may also have an '_alt_drop_targets' list 
		// and a '_class_name' var to make the alternate drop target specific to the RC or IC
		// Alternate drop targets can be handled by ITEM_DROPPED_OUTSIDE listener classes 
		// fpm: end ========

		/**
		* Initialize the dd_tile_list.  Initialize the super class.
		* Detect and store the name of this class (ie. dd_tile_list).
		* Create a drop indicator for later use. Calculate the scroll zone
		* from scroll l/t/r/b values.  Configure the timer for later use
		* and add listeners for MOUSE_UP and MOUSE_DOWN.
		* 
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		function dd_tile_list()
		{
			super();
			
			trace( "dd_tile_list.dd_tile_list()  "+ name );

			_ic = null;
			_class_name = getQualifiedClassName( this );
			
			// fpm: begin ======
			//trace( "ddTileList()"+this.name+" "+this.parent.name );
			_alt_drop_targets = new Array();
			// fpm: end ========

			_drop_arrow = new dd_drop_arrow();
			addChild( _drop_arrow );
			_drop_arrow.visible = false;

			scrollZone = _scroll_zone;

			_ti = new Timer( _scroll_interval );
			_ti.addEventListener( TimerEvent.TIMER, tl_scroll );	 

			addEventListener( MouseEvent.MOUSE_DOWN, tl_mouse_down );
			addEventListener( MouseEvent.MOUSE_UP, tl_mouse_up );  
		}

		/**
		* Listens to the MOUSE_DOWN event.
		* If the target of the mouse event has data and listData then it is
		* probably a CellRenderer (TODO: make this check more through) so the data
		* is copied to a temporary object and a MOUSE_MOVE listener is configured.
		* Drag is not started on MOUSE_DOWN but also requires a MOUSE_MOVE, this
		* should help for cases when something else happens on MOUSE_DOWN.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function tl_mouse_down( _me:MouseEvent ):void
		{
			if( _ic == null && !_dragging )
			{
				try 
				{
					_ic = new Object();
					_ic.data = _me.target.data;
					_ic.listData = _me.target.listData;
					addEventListener( MouseEvent.MOUSE_MOVE, tl_mouse_move );
				}
				catch( _e:Error )
				{
					_ic = null;
				}
			}
		}

		/**
		* Resets the MOUSE_MOVE drag start trigger.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function tl_mouse_up( _me:MouseEvent ):void
		{
			if( !_dragging ) 
			{
				_ic = null;
				removeEventListener( MouseEvent.MOUSE_MOVE, tl_mouse_move );
			}
		}

		/**
		* Listens for a MOUSE_MOVE event.
		* If there is a valid target to drag it is duplicated as the source cellRenderer class.
		* Event listener is removed, data is copied and drag is initialized.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function tl_mouse_move( _me:MouseEvent ):void
		{
			// wxa: begin ======
			if( _ic != null && !_dragging && _ic.listData )
			{
			// wxa: end ======
				removeEventListener( MouseEvent.MOUSE_MOVE, tl_mouse_move );

				_dragging = true;
				
				_drag_item = getDisplayObjectInstance( getStyleValue( "cellRenderer" ) ) as CellRenderer;
				
				// fpm: begin ======
				// added 'try|catch' to handle error if TileList is empty  
				try { 
					_drag_item.data = _ic.data;
					_drag_item.setSize( columnWidth, rowHeight );
					_drag_item.listData = _ic.listData;
					_drag_item.drawNow();
					
					di_start_drag( _me.target.mouseX, _me.target.mouseY );
				} catch ( _e:Error ) {
					_drag_item = null;
				}
				// fpm: end =========
			}
		}

		/**
		* Attaches the drag item to the stage (TODO: make this configurable) and places
		* it under the pointer at an offset equal to that at which it was picked up.
		* If dragRemovesItem is true the object is removed from this data provider.
		* Listeners are initialized, drag is started and the interval timer for drop
		* target detection is started.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function di_start_drag( _ox:Number, _oy:Number ):void
		{
			stage.addChild( _drag_item as Sprite );

			_drag_item.x = stage.mouseX - _ox;
			_drag_item.y = stage.mouseY - _oy;
			
			if( _drag_removes_item ) 
			{
				super.dataProvider.removeItemAt( _ic.listData.index );
			}

			_drag_item.addEventListener( MouseEvent.MOUSE_MOVE, di_mouse_move );
			_drag_item.addEventListener( MouseEvent.MOUSE_UP, di_stop_drag );				  
			_drag_item.startDrag();
			
			_drag_item.alpha = _drag_alpha;

			_ti.start();
		}
		
		/**
		* Listens to the MOUSE_MOVE event.
		* Attempts to determine if the drag item is on top of an object whose class name
		* is the same as this one (ie dd_tile_list).
		* If so attempts to find the CellRenderer instance the drag item is over, if one
		* is found the drop target dd_tile_list is instructed to position its indicator
		* at the appropriate point.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function di_mouse_move( _me:MouseEvent ):void
		{
			var p3:Point = new Point( mouseX, mouseY );
			p3 = this.localToGlobal( p3 );
			var oup:Array = stage.getObjectsUnderPoint( p3 );

			var tl:Object, cr:Object;
			for each( var ob:Object in oup )
			{
				if( ! tl ) 
				{
					tl = get_first_parent_with_classname( ob, _class_name );
				}
				if( ! cr && tl ) 
				{
					var cr_tmp:Object = get_first_parent_with_classname( ob, getQualifiedClassName( tl.cellRenderer ) );
					if( cr_tmp == _drag_item )
					{
						cr = null;
					}
					else 
					{
						cr = cr_tmp;
					}
				}
			}
			if( tl && cr) 
			{
				var dx:Rectangle = cr.getBounds( tl );
				var p2:Point = cr.globalToLocal( p3 );

				var pt:Point;

				// fpm: begin ======
				// position and rotate arrow for HORIZONTAL or VERTICAL scroll direction
				if (tl.direction == ScrollBarDirection.HORIZONTAL) {
					if ( (dx.right - dx.left ) / 2 > p2.x ) {// detect left or right drop.
						pt = new Point( dx.left, dx.top );
					} else {
						pt = new Point( dx.right, dx.top );
					}
					tl.arrowRotation = 0;
				} else {
					if ( (dx.bottom - dx.top ) / 2 < p2.y ) {// detect top or bottom drop.
						pt = new Point( dx.left, dx.bottom );
					} else {
						pt = new Point( dx.left, dx.top );
					}
					tl.arrowRotation = 270;
				}
				// fpm: end =========

				cr.localToGlobal( pt );
				tl.arrowPosition = pt;
			}
		}
		
		/**
		* Listens to a timer event which runs when dragging.
		* Detects drag item drop target, if it is an object whose class name is the
		* same as this one (ie dd_tile_list) and the target tile list autoScroll
		* property is true then perform scrolling on the target tile list based on
		* its public settings.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function tl_scroll( _te:TimerEvent ):void
		{
			var pt:Point = new Point( mouseX, mouseY );
			pt = this.localToGlobal( pt );
			var um:Object = stage.getObjectsUnderPoint( pt )[0];
			var tl:Object = get_first_parent_with_classname( um, _class_name );
			
			if( tl ) 
			{
				if( ! tl.autoScroll ) 
				{
					return;
				}										
				pt = tl.globalToLocal( pt );
				var hs:ScrollBar;
				if( tl.direction == ScrollBarDirection.HORIZONTAL ) 
				{
					if( pt.x < tl.scrollZoneLeft ) 
					{
						hs = tl.horizontalScrollBar;
						hs.scrollPosition -= ( tl.scrollZoneLeft - pt.x ) / tl.scrollSpeed;
					}
					else if ( pt.x > tl.scrollZoneRight ) 
					{
						hs = tl.horizontalScrollBar;
						hs.scrollPosition += ( pt.x - tl.scrollZoneRight ) / tl.scrollSpeed;
					}
				}
				else if( tl.direction == ScrollBarDirection.VERTICAL ) 
				{
					if( pt.y < tl.scrollZoneTop ) 
					{
						hs = tl.verticalScrollBar;
						hs.scrollPosition -= ( tl.scrollZoneTop - pt.y ) / tl.scrollSpeed;
					}
					else if ( pt.y > tl.scrollZoneBottom ) 
					{
						hs = tl.verticalScrollBar;
						hs.scrollPosition += ( pt.y - tl.scrollZoneBottom ) / tl.scrollSpeed;
					}
				}
			}
		}
		
		/**
		* Listens for MOUSE_UP event and responds by attempting to find an object in the dropTarget
		* heirarchy which matches this one (ie dd_tile_list).  If one is found attempts to find a
		* CellRenderer in the dropTarget heirarchy which matches the cellRenderer of the detected
		* tile list.  If one is not found the drag item is added to the end of the tile list data
		* provider.  If one is found the drag item is spliced into the tile list data provider.  If
		* no tile list is found the drag item is removed and the source data provider either replaces
		* the item or not depending on the dropOffRemovesItem and dragRemovesItem settings.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function di_stop_drag( _me:MouseEvent ):void
		{
			_ti.stop();
			_drop_arrow.visible = false;
			_drag_item.stopDrag();
			_drag_item.removeEventListener( MouseEvent.MOUSE_MOVE, di_mouse_move );
			_drag_item.removeEventListener( MouseEvent.MOUSE_UP, di_stop_drag );
			
			// fpm: begin ======
			this.dispatchEvent( new Event( ITEM_DROPPED ) );
			// fpm: end ========
			
			if ( _ic != null && _dragging ) {
				// fpm: begin ======
				// use AS3 'stageX' and 'stageY' properties instead of 'localToGlobal()'.
				var p3:Point = new Point( _me.stageX,  _me.stageY ); 
				//var p3:Point = new Point( mouseX, mouseY );
				//p3 = this.localToGlobal( p3 );
				// fpm: end ========
				var oup:Array = stage.getObjectsUnderPoint( p3 );

				var tl:Object, cr:Object;
				for each( var ob:Object in oup ) 
				{
					if( ! tl ) 
					{
						tl = get_first_parent_with_classname( ob, _class_name );
						
						// fpm: begin ======
						// trigger the 'ITEM_DROPPED_INSIDE' events
						if ( tl ) {
							this.dispatchEvent( new Event( ITEM_DROPPED_INSIDE ) );
							if ( tl == this ) {
								this.dispatchEvent( new Event( ITEM_DROPPED_INSIDE_SELF ) );
							}
							else {
								this.dispatchEvent( new Event( ITEM_DROPPED_INSIDE_OTHER ) );
							}
						}
						// fpm: end ========
						
					}
					if( ! cr && tl ) 
					{
						var cr_tmp:Object = get_first_parent_with_classname( ob, getQualifiedClassName( tl.cellRenderer ) );
						if( cr_tmp == _drag_item )
						{
							cr = null;
						}
						else 
						{
							cr = cr_tmp;
						}
					}
				}
				
				// fpm: begin ======
				// trigger the 'ITEM_DROPPED_OUTSIDE' event
				// Note: Classes with event handlers for 'ITEM_DROPPED_OUTSIDE' can handle the 'alt_drop_targets' 
				// of the dragged-from TL and/or the 'alt_drop_targets' of the dropped '_ic'.
				// The 'alt_drop_targets' are accessible via 'event.target' or 'event.target.ic.listData.owner' 
				// for the TL and 'event.target.ic.data.source' for the '_ic'.
				// To check for 'dropped on' conditions, check if the Mouse is over any of the MCs in 
				// the TL's and/or '_ic's 'alt_drop_targets' list by comparing the Mouse xy to the MC's 
				// bounding box and Stage xy position. 
				if ( ! tl ) {
					this.dispatchEvent( new Event( ITEM_DROPPED_OUTSIDE ) );
				}
				// fpm: end =========
				
				if ( tl ) {
					tl.arrowVisibility = false;
				}
				var dupe:Boolean;
				if( tl && cr ) // Dropping on an existing CellRenderer.
				{
					if ( ( _drag_removes_item ) && ( tl != this ) )
					{
						this.dispatchEvent( new Event( ITEM_REMOVED ) );  
					}
					var dx:Rectangle = cr.getBounds( tl );
					var p2:Point = cr.globalToLocal( p3 );

					// fpm: begin ======
					// find drop position for HORIZONTAL or VERTICAL scroll direction
					var lr:int;
					if (tl.direction == ScrollBarDirection.HORIZONTAL) {
						if ( ( dx.right - dx.left ) / 2 > p2.x ) {// detect left or right drop.
							lr = 0;
						} else {
							lr = 1;
						}
					} else {
						if ( ( dx.bottom - dx.top ) / 2 < p2.y ) {// detect top or bottom drop.
							lr = 1;
						} else {
							lr = 0;
						}
					}
					// fpm: end =========

					if( tl.canDropOn ) 
					{
						if( tl._allow_duplicates ) 
						{
							tl.dataProvider.addItemAt( _ic.data, cr['listData'].index + lr );
							if (tl!=this)
							{
								tl.dispatchEvent( new Event( ITEM_ADDED ) );
							}
							else 
							{
								tl.dispatchEvent( new Event( LIST_REORDERED ) );
							}
							tl.scrollToIndex( cr['listData'].index + lr );
						}
						else
						{
							dupe = tl.checkDuplicate( _ic.data, tl );
							if( dupe ) 
							{
								tl.dispatchEvent( new Event( DUPLICATE_DENIED ) );
							}
							else
							{
								tl.dataProvider.addItemAt( _ic.data, cr['listData'].index + lr );
								if (tl!=this)
								{
									tl.dispatchEvent( new Event( ITEM_ADDED ) );
								}
								else 
								{
									tl.dispatchEvent( new Event( LIST_REORDERED ) );
								}
								tl.scrollToIndex( cr['listData'].index + lr );
							}
						}
					}
					else if( ! _drop_off_removes_item && _drag_removes_item )
					{
						super.dataProvider.addItemAt( _ic.data, _ic.listData.index );
						scrollToIndex( _ic.listData.index );
					}
				}
				else if( tl ) // Dropping on the TileList itself.
				{
					if (( _drag_removes_item ) && (tl!=this))
					{
						this.dispatchEvent( new Event( ITEM_REMOVED ) );  
					}					
					if( tl.canDropOn ) 
					{
						if( tl._allow_duplicates ) 
						{
							tl.dataProvider.addItem( _ic.data );
							if (tl!=this)
							{
								tl.dispatchEvent( new Event( ITEM_ADDED ) );
							}
							else 
							{
								tl.dispatchEvent( new Event( LIST_REORDERED ) );
							}
							tl.scrollToIndex( tl.dataProvider.length - 1);
						}
						else 
						{
							dupe = tl.checkDuplicate( _ic.data, tl );
							if( dupe )
							{
								tl.dispatchEvent( new Event( DUPLICATE_DENIED, true ) );
							}
							else
							{
								tl.dataProvider.addItem( _ic.data );
								if (tl!=this)
								{
									tl.dispatchEvent( new Event( ITEM_ADDED ) );
								}
								else 
								{
									tl.dispatchEvent( new Event( LIST_REORDERED ) );
								}
								tl.scrollToIndex( tl.dataProvider.length - 1);
							}
						}
					}
				}
				else 
				{
					if( ! _drop_off_removes_item && _drag_removes_item )
					{
						super.dataProvider.addItemAt( _ic.data, _ic.listData.index );
						scrollToIndex( _ic.listData.index );
					}
					else if ( _drop_off_removes_item && _drag_removes_item )
					{
						this.dispatchEvent( new Event( ITEM_REMOVED ) );  
					}
				}
			}
			
			// fpm: begin ======
			TileList( _drag_item.listData.owner ).dataProvider.invalidate();
			// fpm: end =========
			
			_dragging = false;
			_ic = null;
			stage.removeChild( _drag_item );
		}
		
		/**
		* Immediately halt operations and clean up resources.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0		
		*/
		public function halt():void
		{
			_ti.stop();
			_dragging = false;
			_ic = null;
			_drop_arrow.visible = false;
			_drag_item.stopDrag();
			_drag_item.removeEventListener( MouseEvent.MOUSE_MOVE, di_mouse_move );
			_drag_item.removeEventListener( MouseEvent.MOUSE_UP, di_stop_drag );
			stage.removeChild( _drag_item );
		}

		/**
		* Traverses the parent chain of the given object attempting to match the qualified
		* class name to the second parameter.  Returns the object if there is a match or null
		* if there is no match.
		*
		* @langversion 3.0
		* @playerversion Flash 9.0.28.0
		*/
		private function get_first_parent_with_classname( _o:Object, _s:String ):Object
		{
			if( _o == null ) 
			{
				return null;
			}
			var _oi:Object = null;
			while( _o.parent ) 
			{
				if( _o.parent && getQualifiedClassName( _o.parent ) == _s ) 
				{
					_oi = _o.parent;
					break;
				}
				_o = _o.parent;
			}
			return _oi;
		}
		
		/* Public Functions */
		
		public function checkDuplicate( _o:Object, _tl:Object ):Boolean
		{
			if( _compare_function is Function ) 
			{
				return _compare_function( _o, _tl );
			}
			var dp:Array = _tl.dataProvider.toArray();
			if( dp.indexOf( _o ) > -1 ) 
			{
				return true;
			}
			return false;
		}
		
		
		/* Uninspectable Property Accessors */
		
		public function set arrowPosition( pt:Point ):void
		{
			if( _can_drop_on )
			{
				_drop_arrow.visible = true;
				_drop_arrow.x = pt.x;
				_drop_arrow.y = pt.y;
			}
		}
		public function set arrowVisibility( _b:Boolean ):void
		{
			_drop_arrow.visible = _b;
		}
		// fpm: begin =====
		public function set arrowRotation( r:Number ):void {
			_drop_arrow.rotation = r;
		}
		// fpm: end ========

		public function get scrollZoneLeft():Number {
			return _scroll_left;
		}
		public function get scrollZoneRight():Number
		{
			return _scroll_right;
		}				  
		public function get scrollZoneTop():Number
		{
			return _scroll_top;
		}		
		public function get scrollZoneBottom():Number
		{
			return _scroll_bottom;
		}		
		public function get cellRenderer():Object
		{
			return _cellRenderer;
		}
		public function set compareFunction( _f:Function ):void
		{
			_compare_function = _f;
		}
		// jmr: 27/05/2010: begin ======
		public function get drag_item():DisplayObject
		{
			return _drag_item;
		}
		// jmr: 27/05/2010: end ======
		// fpm: begin ======
		public function get ic():Object {
			return _ic;
		}
		public function get class_name():Object {
			return _class_name;
		}
		//
		// alternative drop target mc for all RCs the TL
		// Note: the MC in the active RC|IC may also have an '_alt_drop_target' MC as well as a '_class_name' var 
		//
		public function addDropTarget( mc:MovieClip ):void {
			_alt_drop_targets.push( mc );	
		}
		//	
		public function get alt_drop_targets():Array {
			return _alt_drop_targets;
		}
		public function set alt_drop_targets( arr:Array ):void {
			_alt_drop_targets = arr;
		}
		// fpm: end ========

		/* Inspectable Properties */
		
		// if true item can be dragged between dd_tile_list components, if false can just re-order within dd_tile_list.
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set canDragFrom( _b:Boolean ):void
		{
			_can_drag_from = _b;
		}
		public function get canDragFrom():Boolean
		{
			return _can_drag_from;
		}
		
		// if true item is removed from list when dragged, if false item stays (pool).
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set dragRemovesItem( _b:Boolean ):void
		{
			_drag_removes_item = _b;
		}
		public function get dragRemovesItem():Boolean
		{		
			return _drag_removes_item;
		}
		
		// if _drop_off_removes_item is true and this is true it will remove the item from the list. if _drop_off_removes_item is false this does nothing
		[Inspectable(type="Boolean", defaultValue=false)]
		public function set dropOffRemovesItem( _b:Boolean ):void
		{
			_drop_off_removes_item = _b;
		}
		public function get dropOffRemovesItem():Boolean
		{
			return _drop_off_removes_item;
		}
		
		// if true dd_tile_list will accept an item from another dd_tile_list (reordering within component always works).
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set canDropOn( _b:Boolean ):void
		{
			_can_drop_on = _b;
		}
		public function get canDropOn():Boolean
		{
			return _can_drop_on;
		}
		
		// whether the target of the drop allows duplicates to be added (based on the TileListData).
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set allowDuplicates( _b:Boolean ):void
		{
			_allow_duplicates = _b;
		}
		public function get allowDuplicates():Boolean
		{
			return _allow_duplicates;
		}
		
		// sets the alpha value of the dragging item.
		[Inspectable(type="Number", defaultValue=.83)]
		public function set dragAlpha( _n:Number ):void
		{
			_drag_alpha = _n;
		}
		public function get dragAlpha():Number
		{
			return _drag_alpha;
		}
		
		// use auto scroll zones or not.
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set autoScroll( _b:Boolean ):void
		{
			_auto_scroll = _b;
		}
		public function get autoScroll():Boolean
		{
			return _auto_scroll;
		}
		
		// sets how far inside from each edge of the component scrolling will occur.
		[Inspectable(type="Number", defaultValue=.1)]
		public function set scrollZone( _n:Number ):void
		{
			_scroll_zone = _n;
			
			_scroll_left = width * _scroll_zone;
			_scroll_top  = height * _scroll_zone;
			_scroll_right = width - _scroll_left;
			_scroll_bottom = height - _scroll_top;
		}
		public function get scrollZone():Number
		{
			return _scroll_zone;
		}

		// speed : lower is faster. 1-10
		[Inspectable(type="Number", defaultValue=4)]
		public function set scrollSpeed( _n:Number ):void
		{
			if( _n < 1 ) 
			{
				_n = 1;
			}
			else if ( _n > 10 )
			{
				_n = 10;
			}
			_scroll_speed = _n;
		}
		public function get scrollSpeed():Number
		{
			return _scroll_speed;
		}
	} // end class
} // end package

import flash.display.*;

//--------------------------------------
//  Class description
//--------------------------------------
/**
* Provides the drop indicator graphic for dd_tile_list.
*
* @see com.jeremyrodgers.dd_tile_list
*
* @author Jeremy Rodgers
* @langversion 3.0
* @playerversion Flash 9.0.28.0
*/
class dd_drop_arrow extends Sprite
{
	
	/*function dd_drop_arrow()
	{
		graphics.beginFill( 0x074456 );
		graphics.lineStyle( 1, 0x0099CC32, 1, false, LineScaleMode.NONE, CapsStyle.SQUARE, JointStyle.BEVEL, 2 );
		graphics.moveTo( 0, 0 );
		graphics.lineTo( 48, 0 );
		graphics.lineTo( 48, 64 );
		graphics.lineTo( 0, 64 );
		graphics.lineTo( 0, 0 );		
		graphics.endFill();
		graphics.beginFill( 0xFFFFFF );
		graphics.lineStyle( 1, 0x0099CC, 1, false, LineScaleMode.NONE, CapsStyle.SQUARE, JointStyle.BEVEL, 2 );
		graphics.moveTo( 0, 32 );
		graphics.lineTo( 32, 16 );
		graphics.lineTo( 32, 48 );
		graphics.lineTo( 0, 32 );
		graphics.endFill();		
	}*/
	
	function dd_drop_arrow()
	{
		graphics.beginFill( 0x074456 );
		graphics.lineStyle( 1, 0x0099CC, 1, false, LineScaleMode.NONE, CapsStyle.SQUARE, JointStyle.BEVEL, 2 );
		graphics.moveTo( 0, 0 );
		graphics.lineTo( -4.5, -8.5 );
		graphics.lineTo( 4.5, -8.5 );
		graphics.lineTo( 0, 0 );
		graphics.endFill();
	}
}
