package trxcllnt.ds
{
	import flash.geom.Rectangle;
	
	import asx.array.filter;
	import asx.array.first;
	import asx.array.flatten;
	import asx.array.last;
	import asx.array.map;
	import asx.fn.I;
	import asx.fn._;
	import asx.fn.callProperty;
	import asx.fn.equalTo;
	import asx.fn.getProperty;
	import asx.fn.ifElse;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.fn.sequence;
	
	public class RTree extends Node
	{
		public function RTree(maxNodeLoad:int = 8)
		{
			this.maxNodeLoad = maxNodeLoad;
			
			super(new Rectangle());
		}
		
		protected var maxNodeLoad:int = 8;
		
		private static const elementIsNull:Function = sequence(
			getProperty('element'),
			partial(equalTo, Node.e)
		);
		
		override public function intersections(other:*):Array {
			return filter(flatten(search(
				super.intersections(other),
				getProperty('isEmpty'),
				callProperty('intersections', other)
			)), not(elementIsNull));
		}
		
		public function leaves():Array {
			return flatten(search(
				children,
				getProperty('isLeaf'),
				getProperty('children')
			));
		}
		
		public function values():Array {
			return filter(flatten(search(
				children, 
				getProperty('isEmpty'),
				getProperty('children')
			)), not(elementIsNull));
		}
		
		public function insert(elem:*, rect:Rectangle):Node {
			
			const env:Envelope = rect is Envelope ?
				(rect as Envelope) :
				new Envelope(rect);
			
			// computeInsert has two return signatures:
			// insertion: Tuple<Leaf, e>
			// split:     Tuple<Node, Node>
			const insertion:Array = computeInsert(elem, env, this, maxNodeLoad);
			
			// Can be either "Node.e" or the right-
			// associated Node from a split operation.
			const result:Object = last(insertion);
			
			// If result is e, an insertion was made.
			// If result is a Node, a root split was performed.
			return (result === Node.e ? first(insertion) : last(insertion)) as Node;
		}
		
		/**
		 * Recursive R-Tree map/reduce
		 */
		public function search(branch:Array,
							   traversalTerminator:Function, /*(Node):Boolean*/
							   reduction:Function = null     /*(Node):Array  */):Array {
			// Kinda reads like LISP. My work here is done.
			return map(branch, ifElse(
				traversalTerminator,
				I,
				sequence(
					reduction,
					partial(search, _, traversalTerminator, reduction)
				)
			));
		}
	}
}

import asx.array.first;
import asx.array.permutate;
import asx.array.reduce;
import asx.array.tail;
import asx.array.without;

import trxcllnt.ds.Envelope;
import trxcllnt.ds.Node;

internal function computeCost(a:Node, b:Node):Number {
	const ea:Envelope = a.envelope;
	const eb:Envelope = b.envelope;
	
	return ea.add(eb).area - ea.area - eb.area;
}

internal function computeDiff(e0:Envelope, e1:Envelope, env:Envelope):Number {
	return Math.abs(e0.computeInflation(env) - e1.computeInflation(env));
}

internal function computeInsert(element:*, env0:Envelope, n0:Node, maxNodeLoad:int):Array {
	
	var split_results:Array;
	var inserted:Node;
	
	// If the node is empty, appending is the same as prepending. This branch
	// can handle the cases where the node is either a leaf and empty.
	if(n0.isLeaf) {
		
		inserted = new Node(env0, element);
		
		n0.append(inserted);
		
		// Is this node overflowing?
		if(n0.length < maxNodeLoad) {
			return [inserted, Node.e]; // No, so return the inserted node.
		}
		
		// Otherwise, perform a split and return the containers.
		split_results = splitNodes(n0.children);
		
		n0.envelope = split_results[0][0];
		n0.children = split_results[0][1];
		
		inserted = new Node(split_results[1][0], null, split_results[1][1]);
		
		n0.append(inserted);
		
		return [ n0, inserted ];
	}
	
	// [leastAffectedNode, siblings, inflation] 
	const affected_results:Array = getLeastAffectedNode(env0, n0.children);
	
	const leastAffectedChild:Node = affected_results[0];
	const affectedSiblings:Array = affected_results[1];
	
	// [Node, Node.e] or [Node, Node]
	const insertion_result:Array = computeInsert(element, env0, leastAffectedChild, maxNodeLoad);
	
	// Will either be Node.e or a Node
	const result:Object = insertion_result[1];
	const min1:Node = insertion_result[0];
	
	if(result === Node.e)
		return [min1, Node.e];
	
	// If we hit this, we split a node underneath us but our current level
	// isn't overflowing. Return the new container node and Node.e to
	// indicate to our parent that the current level doesn't need to be split. 
	if (n0.length < maxNodeLoad)
		return [result, Node.e];
	
	// Perform a split and return the containers.
	split_results = splitNodes(insertion_result.concat(affectedSiblings));
	n0.envelope = split_results[0][0];
	n0.children = split_results[0][1];
	
	inserted = new Node(split_results[1][0], null, split_results[1][1]);
	n0.append(inserted);
	
	return [ n0, inserted ];
}

/**
 * Finds:
 * <ol>
 * 	<li>The Node whose area would be least affected by inserting the specified Envelope.</li>
 * 	<li>The Node's siblings.</li>
 * </ol>
 */
internal function getLeastAffectedNode(e0:Envelope, nodes:Array):Array {
	
	if(nodes.length == 0)
		throw new ArgumentError('Can\'t find a node that doesn\'t exist!');
	
	const nh:Node = first(nodes) as Node;
	const eh:Envelope = nh.envelope;
	
	return reduce(
		[ nh, [], e0.computeInflation(eh) ], 
		tail(nodes),
		function(triplet:Array, n1:Node):Array {
			
			const min:Node = triplet[0];
			const maxs:Array = triplet[1];
			const minEnlargement:Number = triplet[2];
			
			const e1:Envelope = n1.envelope;
			
			const enlargement:Number = e0.computeInflation(e1);
			
			maxs[maxs.length] = enlargement < minEnlargement ? min : n1;
			
			return enlargement < minEnlargement ?
				[n1, maxs, enlargement] : 
				[min, maxs, minEnlargement];
		}) as Array;
}

internal function splitNodes(nodes:Array):Array {
	
	const seeds:Array = findSplitSeeds(nodes);
	const n0:Node = seeds[0];
	const n1:Node = seeds[1];
	
	return partitionNodes(
		[n0], n0.envelope, 
		[n1], n1.envelope,
		without(nodes, n0, n1)
	);
}
internal function findSplitSeeds(nodes:Array):Array {
	
	if(nodes.length == 0)
		throw new ArgumentError('Can\'t compute split on an empty list');
	
	// cross product
	const products:Array = permutate(nodes);
	const headPair:Array = first(products) as Array;
	
	const seedsInfo:Array = reduce(
		[computeCost.apply(null, headPair), headPair],
		tail(products),
		function(tuple:Array, pair:Array):Array {
			
			const maxCost:Number = tuple[0];
			const cost:Number = computeCost.apply(null, pair);
			
			return cost > maxCost ? [cost, pair] : tuple;
		}
	) as Array;
	
	return seedsInfo.pop() as Array;
}

internal function partitionNodes(n0:Array, e0:Envelope, n1:Array, e1:Envelope, nodes:Array):Array {
	
	if(nodes.length == 0)
		return [[e0, n0], [e1, n1]];
	
	const next:Node = splitPickNext(e0, e1, nodes);
	const en:Envelope = next.envelope;
	
	const rest:Array = without(nodes, next);
	
	const ex:Number = en.computeInflation(e0);
	const ey:Number = en.computeInflation(e1);
	
	(ex < ey ? n0 : n1).unshift(next);
	
	return ex < ey ?
		partitionNodes(n0, en.add(e0), n1, e1, rest):
		partitionNodes(n0, e0, n1, en.add(e1), rest);
}

internal function splitPickNext(e0:Envelope, e1:Envelope, nodes:Array):Node {
	
	if(nodes.length == 0)
		throw new ArgumentError('Can\'t compute max diff on empty list');
	
	const  hn:Node = first(nodes) as Node;
	const  hDiff:Number = computeDiff(e0, e1, hn.envelope);
	
	const nextInfo:Array = reduce(
		[hDiff, hn],
		tail(nodes),
		function(tuple:Array, n:Node):Array {
			const maxDiff:Number = tuple[0];
			const diff:Number = computeDiff(e0, e1, n.envelope);
			
			return diff > maxDiff ? [diff, n] : tuple;
		}) as Array;
	
	return nextInfo.pop() as Node;
}
