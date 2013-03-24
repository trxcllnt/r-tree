package
{
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import asx.array.allOf;
	import asx.array.anyOf;
	import asx.array.contains;
	import asx.array.detect;
	import asx.array.filter;
	import asx.array.flatten;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.range;
	import asx.array.zip;
	import asx.fn.K;
	import asx.fn._;
	import asx.fn.areEqual;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.ifElse;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.number.gt;
	
	import trxcllnt.ds.Envelope;
	import trxcllnt.ds.Node;
	import trxcllnt.ds.RTree;

	public class TreeTests
	{
		public function TreeTests(tree:RTree, numRects:int, width:Number, height:Number)
		{
			var /*const*/ getRect:Function = function():Rectangle {
				var /*const*/ x:Number = Math.random() * width;
				var /*const*/ y:Number = Math.random() * height;
				var /*const*/ w:Number = Math.random() * (width - x);
				var /*const*/ h:Number = Math.random() * 600;
				
				return new Rectangle(x, y, w, h);
			};
			
			var /*const*/ assertCanFindNode:Function = function(tree:RTree, n:Node):Boolean {
				return contains(tree.intersections(n), n);
			};
			
			var /*const*/ assertMeetsBounds:Function = function(tree:RTree, nodes:Array, n0:Node):Boolean {
				
				var /*const*/ envelopes:Array = pluck(nodes, 'envelope');
				
				return allOf(tree.intersections(n0), function(n1:Node):Boolean {
					return anyOf(envelopes, n1.envelope.equals);
				});
			};
			
			var /*const*/ getParents:Function = function(tree:RTree, n:Node):Array {
				var /*const*/ hierarchy:Array = tree.search(
					null,
					sequence(
						getProperty('children'),
						partial(detect, _, partial(areEqual, n))
					),
					ifElse(
						callProperty('container', n),
						getProperty('children'),
						K([])
					)
				);
				
				var parents:Array = flatten(hierarchy);
				
				return parents;
			};
			
			var /*const*/ valueOnlyHasOneParent:Function = function(tree:RTree, n:Node):Boolean {
				
				var parents:Array = getParents(tree, n);
				
				return parents.length == 1;
			};
			
			var /*const*/ indexes:Array = range(numRects);
			var /*const*/ rects:Array = map(indexes, getRect);
			
			var /*const*/ zipped:Array = zip(indexes, rects);
			
			var t:Number = getTimer();
			// Do insert
			var /*const*/ nodes:Array = map(zipped, distribute(tree.insert));
			trace(
				getTimer() - t + 'ms:',
				'inserted', numRects, ' nodes'
			);
			
			var /*const*/ values:Array = tree.values();
			t = getTimer();
			var /*const*/ found:Boolean = allOf(values, partial(assertCanFindNode, tree));
			trace(
				getTimer() - t + 'ms:',
				'[' + (found ? 'Success' : 'Failure') + ']:',
				'All nodes', (found ? 'are' : 'are not'), 'found in the list of intersections when queried for themselves.'
			);
			
			t = getTimer();
			var /*const*/ meetsBounds:Boolean = allOf(values, partial(assertMeetsBounds, tree, values));
			trace(
				getTimer() - t + 'ms:',
				'[' + (meetsBounds ? 'Success' : 'Failure') + ']:',
				'All intersections for each node', (meetsBounds ? 'exist' : 'don\'t exist'),
				'in the list of value envelopes.'
			);
			
			t = getTimer();
			var /*const*/ singlyParented:Boolean = allOf(values, partial(valueOnlyHasOneParent, tree));
			trace(
				getTimer() - t + 'ms:',
				'[' + (singlyParented ? 'Success' : 'Failure') + ']:',
				'Each value', (singlyParented ? 'has only' : 'has more than one'),
				'parent node in the tree.'
			);
		}
	}
}