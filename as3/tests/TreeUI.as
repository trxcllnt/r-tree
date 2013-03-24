package
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	import flash.utils.getTimer;
	
	import asx.array.filter;
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.range;
	import asx.array.zip;
	import asx.color.blue;
	import asx.color.green;
	import asx.fn.I;
	import asx.fn._;
	import asx.fn.aritize;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.setProperty;
	import asx.number.sum;
	import asx.object.newInstance;
	
	import trxcllnt.ds.Node;
	import trxcllnt.ds.RTree;
	
	public class TreeUI extends Sprite
	{
		protected function getRect(i:int):Rectangle {
			
			const x:Number = Math.random() * width;
			const y:Number = Math.random() * height;
			const w:Number = Math.random() * (width - x);
			const h:Number = Math.random() * 600;
			
			return new Rectangle(x, y, w, h);
		};
		
		public function TreeUI(tree:RTree, numRects:int, width:Number, height:Number)
		{
			super();
			
			doubleClickEnabled = true;
			
			graphics.beginFill(0, 1);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();
			
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
				g.lineStyle(2, 0xffffff);
				g.drawRect(r.x, r.y, r.width, r.height);
			}));
			
			trace("Rendering took", getTimer() - t, "ms");
			
			trace("Inserting nodes");
			const insertionStart:int = setT();
			const insertionTimes:Array = [];
			
			// Insert the Array<Sprite, Rect> into the tree.
			for(var j:int = 0, k:int = pairs.length; j < k; ++j) {
				setT();
				tree.insert(pairs[j][0], pairs[j][1]);
				insertionTimes[insertionTimes.length] = getTimer() - t;
			}
			
			trace("Insertion took", getTimer() - insertionStart, "ms");
			trace("Avg insertion time", sum(insertionTimes) / insertionTimes.length);
			trace("Insertion times", insertionTimes);
			
			// Breadth-first iteration through the container nodes so
			// we can color them by insertion-level.
			var /*const*/ color:Function = function(level:int):Function {
				return function(node:Node):void {
					if(node.isEmpty) return;
					node.element = level;
					forEach(node.children, color(level + 1));
				};
			};
			
			forEach(tree.children, color(1));
			
			var overlapping:Array = [];
			
			const highlight:Function = function(r:Rectangle):void {
				
				forEach(overlapping, ifElse(contains, removeChild, noop));
				
				overlapping.length = 0;
				
				graphics.clear();
				graphics.beginFill(0, 1);
				graphics.drawRect(0, 0, width, height);
				graphics.endFill();
				
				graphics.lineStyle(3, 0xFF0000);
				graphics.drawRect(r.x, r.y, r.width, r.height);
				
				const block:TextBlock = new TextBlock();
				
				const intersections:Array = tree.intersections(r);
				
				tree.search(
					filter(tree.children, callProperty('intersects', r)),
					getProperty('isEmpty'),
					function(node:Node):Array {
						
						var /*const*/ parent:Rectangle = node.parent.envelope;
						var /*const*/ r1:Rectangle = node.envelope;
						var /*const*/ l:int = node.element;
						
						var /*const*/ overlaps:Boolean = r1.x == parent.x && r1.y == parent.y && l > 1;
						var /*const*/ str:String = (overlaps ? '- ' : '') + l.toString();
						
						block.content = new TextElement(str.toString(), new ElementFormat(null, 20, 0x00FF00, 0.5));
						
						var /*const*/ line:TextLine = block.createTextLine(null);
						line.x = r1.x + (overlaps ? 20 : 5);
						line.y = r1.y + 5 + line.ascent;
						
						intersections.push({element: line});
						
						graphics.lineStyle(2, 0x00FF00, 0.25);
						graphics.drawRect(r1.x, r1.y, r1.width, r1.height);
						
						return node.intersections(r);
					});
				
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