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
	import asx.number.sum;
	import asx.object.newInstance;
	
	import trxcllnt.ds.RTree;
	
	public class TreeUI extends Sprite
	{
		public function TreeUI(tree:RTree, numRects:int, width:Number, height:Number)
		{
			super();
			
			doubleClickEnabled = true;
			
			graphics.beginFill(0, 1);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();
			
			const getRect:Function = function():Rectangle {
				
				const x:Number = Math.random() * width;
				const y:Number = Math.random() * height;
				const w:Number = Math.random() * (width - x);
				const h:Number = Math.random() * 600;
				
				return new Rectangle(x, y, w, h);
			};
			
			const rects:Array = map(range(numRects), getRect);
			const sprites:Array = map(range(numRects), aritize(partial(newInstance, Sprite), 0));
			
			var t:int = 0;
			const setT:Function = function():int { return t = getTimer(); };
			
			// Zip the sprites and rects
			const pairs:Array = zip(sprites, rects);
			
			// Draw the initial sprite graphics
			trace("Rendering", numRects, "Sprites");
			setT();
			
			forEach(pairs,  distribute(function(sprite:Sprite, r:Rectangle):void {
				const g:Graphics = sprite.graphics;
				g.lineStyle(1, 0xCCCCCC);
				g.drawRect(r.x, r.y, r.width, r.height);
			}));
			
			trace("Rendering took", getTimer() - t, "ms");
			
			trace("Inserting nodes");
			const insertionStart:int = setT();
			const insertionTimes:Array = [];
			
			//			 Insert the Set<Sprite, Rect> into the tree.
			for(var j:int = 0, k:int = pairs.length; j < k; ++j) {
				setT();
				tree.insert(pairs[j][0], pairs[j][1]);
				insertionTimes[insertionTimes.length] = getTimer() - t;
			}
			
			trace("Insertion took", getTimer() - insertionStart, "ms");
			trace("Avg insertion time", sum(insertionTimes) / insertionTimes.length);
			trace("Insertion times", insertionTimes);
			
			var overlapping:Array = [];
			const highlight:Function = function(r:Rectangle):void {
				
				const parents:Array = pluck(overlapping, 'parent');
				forEach(overlapping, removeChild);
				
				overlapping.length = 0;
				
				graphics.clear();
				graphics.beginFill(0, 1);
				graphics.drawRect(0, 0, width, height);
				graphics.endFill();
				
				graphics.lineStyle(3, 0xFF0000);
				graphics.drawRect(r.x, r.y, r.width, r.height);
				
				setT();
				const intersections:Array = tree.intersections(r);
				trace('Searching took:', getTimer() - t);
				
				overlapping = map(pluck(intersections, 'element'), addChild);
			};
			
			const viewport:Rectangle = new Rectangle(0, 0, 1000, 600);
			var y:Number = 0;
			
			const down:Function = function(d:MouseEvent):void {
				y = d.stageY;
				removeEventListener(MouseEvent.MOUSE_DOWN, down);
				addEventListener(MouseEvent.MOUSE_MOVE, move);
				addEventListener(MouseEvent.MOUSE_UP, up);
			};
			const move:Function = function(m:MouseEvent):void {
				viewport.y += m.stageY - y;
				y = m.stageY;
				highlight(viewport);
			};
			const up:Function = function(u:MouseEvent):void {
				removeEventListener(MouseEvent.MOUSE_MOVE, move);
				removeEventListener(MouseEvent.MOUSE_UP, up);
				addEventListener(MouseEvent.MOUSE_DOWN, down);
			};
			const doubleClick:Function = function(dd:MouseEvent):void {
				viewport.y = y = dd.stageY - 300;
				highlight(viewport);
			};
			
			addEventListener(MouseEvent.MOUSE_DOWN, down);
			addEventListener(MouseEvent.DOUBLE_CLICK, doubleClick);
			
			highlight(viewport);
		}
	}
}