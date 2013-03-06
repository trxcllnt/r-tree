package 
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import asx.array.allOf;
	import asx.array.anyOf;
	import asx.array.contains;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.range;
	import asx.array.zip;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.partial;
	
	import trxcllnt.ds.Envelope;
	import trxcllnt.ds.Node;
	import trxcllnt.ds.RTree;
	
	[SWF(width = "600", height = "500")]
	public class TestOCaml extends Sprite
	{
		public function TestOCaml()
		{
			super();
			
			const container:Sprite = new Sprite();
			addChild(container);
			container.graphics.beginFill(0x00);
			container.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			
			// var /*const*/ name:Type = new Type();
			
			var /*const*/ width:Number = stage.stageWidth;
			var /*const*/ height:Number = stage.stageHeight;
			
			var /*const*/ getRect:Function = function():Rectangle {
				var /*const*/ x:Number = Math.random() * width;
				var /*const*/ y:Number = Math.random() * height;
				var /*const*/ w:Number = Math.random() * (width - x);
				var /*const*/ h:Number = Math.random() * 600;
				
				return new Rectangle(x, y, w, h);
			};
			
			var /*const*/ assertCanFindNode:Function = function(tree:RTree, n:Node):Boolean {
				var /*const*/ intersections:Array = tree.intersections(n.envelope);
				var /*const*/ elements:Array = pluck(intersections, 'element');
				var /*const*/ found:Boolean = asx.array.contains(intersections, n);
				
				if(!found) {
					tree.intersections(n.envelope);
				}
				
				return found;
			};
			
			/**
				let assert_meets_bounds r e elems =
				  let found = Rtree.find r e in
				  List.iter begin fun elem ->
				    let e' = List.assoc elem elems in
				    assert (Envelope.intersects e e')
				  end found
			 */
			var /*const*/ assertMeetsBounds:Function = function(tree:RTree, nodes:Array, n0:Node):Boolean {
				
				var /*const*/ e0:Envelope = n0.envelope;
				var /*const*/ envelopes:Array = pluck(nodes, 'envelope');
				
				var /*const*/ intersections:Array = tree.intersections(e0);
				
				var /*const*/ meetsBounds:Boolean = allOf(intersections, function(n1:Node):Boolean {
					var /*const*/ e1:Envelope = n1.envelope;
					var /*const*/ val:Boolean = anyOf(envelopes, e1.equals);
					return val;
				});
				
				return meetsBounds;
			};
			
			var /*const*/ numRects:int = 100;
			var /*const*/ tree:RTree = new RTree();
			
			var /*const*/ indexes:Array = range(numRects);
			var /*const*/ rects:Array = map(indexes, getRect);
			
			var /*const*/ zipped:Array = zip(indexes, rects);
			
			var t:Number = getTimer();
			// Do insert
			var /*const*/ nodes:Array = map(zipped, distribute(tree.insert));
			trace(
				getTimer() - t, 'ms:',
				'inserted', numRects, ' nodes'
			);
			
			t = getTimer();
			var /*const*/ envelopes:Array = pluck(nodes, 'envelope');
			trace(
				getTimer() - t, 'ms:',
				'selected all the envelopes from the nodes.'
			);
			
			t = getTimer();
			var nodesWithValues:Array = tree.values();
			trace(
				getTimer() - t, 'ms:',
				'computed the nodes with value elements.' 
			);
			
			t = getTimer();
			var /*const*/ found:Boolean = allOf(nodes, partial(assertCanFindNode, tree));
			trace(
				getTimer() - t, 'ms:',
				'All nodes', (found ? 'are' : 'are not'), 'found in the list of intersections when queried for themselves.'
			);
			
			t = getTimer();
			var /*const*/ meetsBounds:Boolean = allOf(nodes, partial(assertMeetsBounds, tree, nodes));
			trace(
				getTimer() - t, 'ms:',
				'All intersections for each node', (meetsBounds ? '' : 'don\'t'),
				'exist in the list of value envelopes.'
			);
			
//			var enumerable:IEnumerable = Enumerable.range(0, 10).
//				map(function(i:int):Point {
//					return new Point(Math.random() * 100, Math.random() * 100);
//				});
//			
//			var itr:IEnumerator = enumerable.getEnumerator();
//			while(itr.moveNext())
//				trace(itr.current);
//			
//			var observable:IObservable = Observable.fromEvent(container, MouseEvent.MOUSE_MOVE).
//				map(function(event:MouseEvent):Point {
//					return new Point(event.stageX, event.stageY);
//				});
//			
//			observable.subscribe(function(point:Point):void {
//				trace(point);
//			});
		}
	}
}
