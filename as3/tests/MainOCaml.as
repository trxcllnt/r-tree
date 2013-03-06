package 
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.range;
	import asx.array.zip;
	import asx.fn.aritize;
	import asx.fn.distribute;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.object.newInstance;
	
	import trxcllnt.ds.RTree;
	
//	[SWF(width = "600", height = "500")]
	[SWF(width = "1000", height = "8000")]
	public class MainOCaml extends Sprite
	{
		public function MainOCaml()
		{
			super();
			
			var /*const*/ width:Number = stage.stageWidth;
			var /*const*/ height:Number = stage.stageHeight;
			
			var /*const*/ container:Sprite = new Sprite();
			container.doubleClickEnabled = true;
			addChild(container);
			
			var /*const*/ numRects:int = 100;
			
			container.graphics.beginFill(0, 1);
			container.graphics.drawRect(0, 0, width, height);
			container.graphics.endFill();
			
			var /*const*/ tree:RTree = new RTree();
			var /*const*/ getRect:Function = function():Rectangle {
				
				var /*const*/ x:Number = Math.random() * width;
				var /*const*/ y:Number = Math.random() * height;
				var /*const*/ w:Number = Math.random() * (width - x);
				var /*const*/ h:Number = Math.random() * 600;
				
				return new Rectangle(x, y, w, h);
			};
			
			var /*const*/ rects:Array = map(range(numRects), getRect);
			var /*const*/ sprites:Array = map(range(numRects), aritize(partial(newInstance, Sprite), 0));
			
			forEach(
				// Zip the sprites and rects
				zip(sprites, rects),
				sequence(
					// Draw the initial sprite graphics
					distribute(function(sprite:Sprite, r:Rectangle):Array {
						var /*const*/ g:Graphics = sprite.graphics;
						g.lineStyle(1, 0xCCCCCC);
						g.drawRect(r.x, r.y, r.width, r.height);
						return [sprite, r];
					}),
					// Insert the Set<Sprite, Rect> into the tree.
					distribute(tree.insert)
			));
			
			var /*const*/ overlapping:Array = [];
			var /*const*/ highlight:Function = function(r:Rectangle):void {
				
				forEach(overlapping, container.removeChild);
				
				overlapping.length = 0;
				
				container.graphics.clear();
				container.graphics.beginFill(0, 1);
				container.graphics.drawRect(0, 0, width, height);
				container.graphics.endFill();
				
				container.graphics.lineStyle(3, 0xFF0000);
				container.graphics.drawRect(r.x, r.y, r.width, r.height);
				
				var /*const*/ time:int = getTimer();
				var /*const*/ intersections:Array = tree.intersections(r);
				trace('search time:', getTimer() - time);
				
				overlapping.push.apply(overlapping, pluck(intersections, 'element'));
				
				forEach(overlapping, container.addChild);
			};
			
			var /*const*/ viewport:Rectangle = new Rectangle(0, 0, 1000, 600);
			var y:Number = 0;
			
			var /*const*/ down:Function = function(d:MouseEvent):void {
				y = d.stageY;
				container.removeEventListener(MouseEvent.MOUSE_DOWN, down);
				container.addEventListener(MouseEvent.MOUSE_MOVE, move);
				container.addEventListener(MouseEvent.MOUSE_UP, up);
			};
			var /*const*/ move:Function = function(m:MouseEvent):void {
				viewport.y += m.stageY - y;
				y = m.stageY;
				highlight(viewport);
			};
			var /*const*/ up:Function = function(u:MouseEvent):void {
				container.removeEventListener(MouseEvent.MOUSE_MOVE, move);
				container.removeEventListener(MouseEvent.MOUSE_UP, up);
				container.addEventListener(MouseEvent.MOUSE_DOWN, down);
			};
			var /*const*/ doubleClick:Function = function(dd:MouseEvent):void {
				viewport.y = y = dd.stageY - 300;
				highlight(viewport);
			};
			
			container.addEventListener(MouseEvent.MOUSE_DOWN, down);
			container.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClick);
			
			highlight(viewport);
		}
	}
}