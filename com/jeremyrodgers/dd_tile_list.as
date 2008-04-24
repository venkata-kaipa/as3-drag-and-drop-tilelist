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
	 *	-- TileList Config --
	 *	ddt.rowCount = 1;
	 *	ddt.rowHeight = 96;
	 *	ddt.columnWidth = 128;
	 *	ddt.height = 96 + 16;
	 *	ddt.direction = ScrollBarDirection.HORIZONTAL;
	 *	ddt.dataProvider = new DataProvider( new XML( "<items><item label="first" source="first.jpg"/></items>" ) );
	 *	ddt.addEventListener( MouseEvent.DOUBLE_CLICK, show_properties );
	 *	
	 *	-- dd_tile_list Config --
	 *	ddt.canDragFrom = true;
	 *	ddt.dragRemovesItem = true;
	 *	ddt.dropOffRemovesItem = true;
	 *	ddt.canDropOn = true;
	 *	ddt.dragAlpha = .43;
	 *	ddt.autoScroll = true;
	 *	ddt.scrollZone = .15;
	 *	ddt.scrollSpeed = 3;
	 *	ddt.allowDuplicates = false;
	 *	// ddt.addEventListener( dd_tile_list.DUPLICATE_DENIED, dd_denied );
	 *
     * @see fl.controls.listClasses.TileList
     *
	 * @author Jeremy Rodgers 
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
	 */
	public class dd_tile_list extends TileList {

		/* Events */
		public static var ITEM_ADDED		:String = "item_added";			// TODO: Custom event classes.
		public static var ITEM_REMOVED 		:String = "item_removed";		// TODO: Add this
		public static var DUPLICATE_DENIED	:String = "duplicate_denied";
		
		/* Inspectable */
		private var _can_drag_from			:Boolean = true;
		private var _drag_removes_item		:Boolean = true;
		private var _drop_off_removes_item	:Boolean = true;
		private var _can_drop_on			:Boolean = true;
		private var _drag_alpha				:Number = .83;
		private var _auto_scroll			:Boolean = true;
		private var _scroll_zone			:Number = .1;
		private var _scroll_speed			:Number = 4;
		private var _allow_duplicates		:Boolean = true;
		
		/* Private */
		private var _ic						:Object;
		private var _class_name				:String;
		private var _dragging				:Boolean;
		private var _drag_item				:CellRenderer;
		private var _drag_item_loader		:Loader;
		private var _ti						:Timer;
		private var _scroll_interval		:Number = 20;
		private var _scroll_left			:Number;			// Calculated
		private var _scroll_right			:Number;			// Calculated
		private var _scroll_bottom			:Number;			// Calculated
		private var _scroll_top				:Number;			// Calculated
		private var _drop_arrow				:dd_drop_arrow;

		function dd_tile_list()
		{
			super();
			
			trace( "dd_tile_list.dd_tile_list()  "+ name );
			
			_ic = null;
			
			_class_name = getQualifiedClassName( this );	
			_drop_arrow = new dd_drop_arrow();
			addChild( _drop_arrow );
			_drop_arrow.visible = false;
			
			scrollZone = _scroll_zone;
			
			_ti = new Timer( _scroll_interval );
			_ti.addEventListener( TimerEvent.TIMER, tl_scroll );	

			addEventListener( MouseEvent.MOUSE_DOWN, tl_mouse_down );
			addEventListener( MouseEvent.MOUSE_UP, tl_mouse_up );	
		}
		
		private function tl_mouse_down( _me:MouseEvent )
		{
			if( _ic == null && !_dragging ) {
				try {
					_ic = new Object();
					_ic.data = _me.target.data;
					_ic.data.index = _me.target.listData.index;
					_ic.data.listData = _me.target.listData;
					addEventListener( MouseEvent.MOUSE_MOVE, tl_mouse_move );
				}
				catch( _e:Error ) {
					_ic = null;
				}
			}
		}
		
		private function tl_mouse_up( _me:MouseEvent )
		{
			if( !_dragging ) {
				_ic = null;
				removeEventListener( MouseEvent.MOUSE_MOVE, tl_mouse_move );
			}
		}
		
		private function tl_mouse_move( _me:MouseEvent )
		{
			if( _ic != null && !_dragging ) {
				
				removeEventListener( MouseEvent.MOUSE_MOVE, tl_mouse_move );
				
				_dragging = true;
				
				_drag_item = getDisplayObjectInstance( getStyleValue( "cellRenderer" ) ) as CellRenderer;
				_drag_item.setSize( columnWidth, rowHeight );
				_drag_item.listData = _ic.data.listData
				_drag_item.drawNow();
				
				di_start_drag( _me.target.mouseX, _me.target.mouseY );
			}
		}
		
		private function di_start_drag( _ox:Number, _oy:Number )
		{
			stage.addChild( _drag_item as Sprite );

			_drag_item.x = stage.mouseX - _ox;
			_drag_item.y = stage.mouseY - _oy;
			
			if( _drag_removes_item ) {
				super.dataProvider.removeItemAt( _ic.data.index );
			}

			_drag_item.addEventListener( MouseEvent.MOUSE_MOVE, di_mouse_move );
			_drag_item.addEventListener( MouseEvent.MOUSE_UP, di_stop_drag );		
			_drag_item.startDrag();
			
			_drag_item.alpha = _drag_alpha;

			_ti.start();

		}
		
		private function di_mouse_move( _me:MouseEvent )
		{
			var tl:Object = get_first_parent_with_classname( _drag_item.dropTarget, _class_name );
			if( tl ) {
				var cr:Object = get_first_parent_with_classname( _drag_item.dropTarget, getQualifiedClassName( tl.cellRenderer ) );
				if( cr ) {
					var dx:Rectangle = cr.getBounds( tl );
					var pt:Point = new Point( dx.left, dx.top );
					
					cr.localToGlobal( pt );
					tl.arrowPosition = pt;
				}
			}
		}
		
		private function tl_scroll( _te:TimerEvent )
		{
			var pt:Point = new Point( mouseX, mouseY );
			pt = this.localToGlobal( pt );
			var um:Object = stage.getObjectsUnderPoint( pt )[0];
			var tl:Object = get_first_parent_with_classname( um, _class_name );
			
			if( tl ) {
				if( ! tl.autoScroll ) {
					return;
				}				
				pt = tl.globalToLocal( pt );
				var hs:ScrollBar;
				if( tl.direction == ScrollBarDirection.HORIZONTAL ) {
					if( pt.x < tl.scrollZoneLeft ) {
						hs = tl.horizontalScrollBar;
						hs.scrollPosition -= ( tl.scrollZoneLeft - pt.x ) / _scroll_speed;
					}
					else if ( pt.x > tl.scrollZoneRight ) {
						hs = tl.horizontalScrollBar;
						hs.scrollPosition += ( pt.x - tl.scrollZoneRight ) / _scroll_speed;
					}
				}
				else if( tl.direction == ScrollBarDirection.VERTICAL ) {
					if( pt.y < tl.scrollZoneTop ) {
						hs = tl.verticalScrollBar;
						hs.scrollPosition -= ( tl.scrollZoneTop - pt.y ) / _scroll_speed;
					}
					else if ( pt.y > tl.scrollZoneBottom ) {
						hs = tl.verticalScrollBar;
						hs.scrollPosition += ( pt.y - tl.scrollZoneBottom ) / _scroll_speed;
					}
				}
			}
		}
		
		private function di_stop_drag( _me:MouseEvent )
		{
			_ti.stop();
			_drop_arrow.visible = false;
			_drag_item.stopDrag();
			_drag_item.removeEventListener( MouseEvent.MOUSE_MOVE, di_mouse_move );
			_drag_item.removeEventListener( MouseEvent.MOUSE_UP, di_stop_drag );	
			
			if( _ic != null && _dragging ) {
				var tl:Object = get_first_parent_with_classname( _drag_item.dropTarget, _class_name );
				if( tl ) {
					var cr:Object = get_first_parent_with_classname( _drag_item.dropTarget, getQualifiedClassName( tl.cellRenderer ) );
					tl.arrowVisibility = false;
				}
				var dupe:Boolean;
				if( tl && cr ) {
					// TODO: after drop add whitespace (VERT/HORIZ) 10 or 20 px for drop at end.
					if( tl.canDropOn ) {
						if( tl._allow_duplicates ) {
							tl.dataProvider.addItemAt( _ic.data, cr['listData'].index );
							tl.dispatchEvent( new Event( ITEM_ADDED ) );
						}
						else {
							dupe = tl.checkDuplicate( _ic.data, tl );
							if( dupe ) {
								tl.dispatchEvent( new Event( DUPLICATE_DENIED ) );
							}
							else {
								tl.dataProvider.addItemAt( _ic.data, cr['listData'].index );
								tl.dispatchEvent( new Event( ITEM_ADDED ) );
							}
						}
					}
					else if( ! _drop_off_removes_item && _drag_removes_item ) {
						super.dataProvider.addItemAt( _ic.data, _ic.data.index );
						scrollToIndex( _ic.data.index );
					}
				}
				else if( tl ) {
					if( tl.canDropOn ) {
						if( tl._allow_duplicates ) {
							tl.dataProvider.addItem( _ic.data );
							tl.dispatchEvent( new Event( ITEM_ADDED ) );
						}
						else {
							dupe = tl.checkDuplicate( _ic.data, tl );
							if( dupe ) {
								tl.dispatchEvent( new Event( DUPLICATE_DENIED, true ) );
							}
							else {
								tl.dataProvider.addItem( _ic.data );
								tl.dispatchEvent( new Event( ITEM_ADDED ) );
							}
						}
					}
				}
				else {
					if( ! _drop_off_removes_item && _drag_removes_item ) {
						super.dataProvider.addItemAt( _ic.data, _ic.data.index );
						scrollToIndex( _ic.data.index );
					}
				}
			}
			_dragging = false;
			_ic = null;
			stage.removeChild( _drag_item );
		}
	
		private function get_first_parent_with_classname( _o:Object, _s:String ):Object
		{
			var _oi:Object;
			try {
				while( _o.parent ){ 
					if( getQualifiedClassName( _o.parent ) == _s ) {
						_oi = _o.parent;
						break;
					}
					_o = _o.parent;
				}
			}
			catch( _e:Error ) {
				_oi = null;
			}
			return _oi;
		}
		
		
		/* Public Functions */
		
		public function checkDuplicate( _o:Object, _tl:Object ):Boolean
		{
			var dp:Array = _tl.dataProvider.toArray();
			if( dp.indexOf( _o ) > -1 ) {
				return true;
			}
			return false;
		}
		
		
		/* Uninspectable Property Accessors */
		
		public function set arrowPosition( pt:Point ):void
		{
			if( _can_drop_on ) {
				_drop_arrow.visible = true;
				_drop_arrow.x = pt.x;
				_drop_arrow.y = pt.y;
			}
		}
		public function set arrowVisibility( _b:Boolean ):void
		{
			_drop_arrow.visible = _b;
		}
		public function get scrollZoneLeft():Number
		{
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
		
		
		/* Inspectable Properties */
		
		// if true item can be dragged between dd_tile_list components, if false can just re-order within dd_tile_list.
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set canDragFrom( _b:Boolean )
		{
			_can_drag_from = _b;
		}
		public function get canDragFrom():Boolean
		{
			return _can_drag_from;
		}
		
		 // if true item is removed from list when dragged, if false item stays (pool).
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set dragRemovesItem( _b:Boolean )
		{
			_drag_removes_item = _b;
		}
		public function get dragRemovesItem():Boolean
		{	
			return _drag_removes_item;
		}
		
		// if _drop_off_removes_item is true and this is true it will remove the item from the list. if _drop_off_removes_item is false this does nothing
		[Inspectable(type="Boolean", defaultValue=false)]
		public function set dropOffRemovesItem( _b:Boolean )
		{
			_drop_off_removes_item = _b;
		}
		public function get dropOffRemovesItem():Boolean
		{
			return _drop_off_removes_item;
		}
		
		// if true dd_tile_list will accept an item from another dd_tile_list (reordering within component always works).
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set canDropOn( _b:Boolean )
		{
			_can_drop_on = _b;
		}
		public function get canDropOn():Boolean
		{
			return _can_drop_on;
		}
		
		// whether the target of the drop allows duplicates to be added (based on the TileListData).
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set allowDuplicates( _b:Boolean )
		{
			_allow_duplicates = _b;
		}
		public function get allowDuplicates():Boolean
		{
			return _allow_duplicates;
		}
		
		// sets the alpha value of the dragging item.
		[Inspectable(type="Number", defaultValue=.83)]
		public function set dragAlpha( _n:Number )
		{
			_drag_alpha = _n;
		}
		public function get dragAlpha():Number
		{
			return _drag_alpha;
		}
		
		// use auto scroll zones or not.
		[Inspectable(type="Boolean", defaultValue=true)]
		public function set autoScroll( _b:Boolean )
		{
			_auto_scroll = _b;
		}
		public function get autoScroll():Boolean
		{
			return _auto_scroll;
		}
		
		// sets how far inside from each edge of the component scrolling will occur.
		[Inspectable(type="Number", defaultValue=.1)]
		public function set scrollZone( _n:Number )
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
		public function set scrollSpeed( _n:Number )
		{
			if( _n < 1 ) {
				_n = 1;
			}
			else if ( _n > 10 ) {
				_n = 10;
			}
			_scroll_speed = _n;
		}
		public function get scrollSpeed():Number
		{
			return _scroll_speed;
		}
	}
}

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
