package trxcllnt.ds
{
	import flash.geom.Rectangle;
	
	import asx.array.filter;
	import asx.array.flatten;
	import asx.array.head;
	import asx.array.last;
	import asx.array.map;
	import asx.fn.I;
	import asx.fn.K;
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
		
		private var maxNodeLoad:int = 8;
		
		private static const elementIsNull:Function = sequence(
			getProperty('element'),
			partial(equalTo, Node.e)
		);
		
		override public function intersections(rect:Rectangle):Array {
			return search(
				children,
				getProperty('isLeaf'),
				callProperty('intersections', rect),
				not(elementIsNull)
			);
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
			// If result is a Node, a split was performed.
			return (result === Node.e ? head(insertion) : result) as Node;
		}
		
		/**
		 * Recursive R-Tree map/filter
		 */
		public function search(branch:Array,
							   traversalTerminator:Function,   /*(Node):Boolean*/
							   mapPredicate:Function = null,/*(Node):Object */
							   filterPredicate:Function = null/*(Node):Boolean*/):Array {
			
			// Create a closure to proxy calls to the expansion function.
			// 
			// We have to do this because the expansion function can't reference
			// itself as it's not closed over in this context.
			const recurse:Function = function(...args):* { return expand.apply(null, args); };
			
			// TODO: Could I modify the signature of search to call it recursively?
			// const recurse:Function = partial(search, _, traversalTerminator, mapPredicate, reducer);
			
			// Kinda reads like LISP
			const expand:Function = ifElse(
				traversalTerminator,
				mapPredicate || I, 
				sequence(
					getProperty('children'),
					partial(map, _, recurse)
				)
			);
			
			// map -> aggregate -> filter -> results
			return filter(flatten(map(branch, recurse)), filterPredicate || K(true));
		}
		
		public function leaves():Array {
			return search(children, getProperty('isLeaf'));
		}
		
		public function values():Array {
			return search(children, getProperty('isEmpty'), null, not(elementIsNull));
		}
	}
}

import asx.array.head;
import asx.array.length;
import asx.array.map;
import asx.array.permutate;
import asx.array.reduce;
import asx.array.tail;
import asx.array.without;
import asx.fn._;
import asx.fn.distribute;
import asx.fn.partial;
import asx.object.newInstance_;

import trxcllnt.ds.Envelope;
import trxcllnt.ds.Node;

internal function computeCost(a:Node, b:Node):Number {
	const ea:Envelope = a.envelope;
	const eb:Envelope = b.envelope;
	
	return ea.add(eb).area - ea.area - eb.area;
}

internal function inflation(a:Envelope, b:Envelope):Number {
	return a.add(b).area - a.area;
}

// Impure stateful (but more performant) implementations. Pure Functional implementations below.

internal const insertion_result:Array = [];
internal const affected_results:Array = [];
internal const split_seeds_results:Array = [];
internal const partition_results:Array = [];

internal function computeInsert(element:*, env0:Envelope, n0:Node, maxNodeLoad:int):Array {
	
	// This condition is unnecessary, see condition below it.
	// Keeping this comment here to explain the change.
	// if(n0.isEmpty) {
	//	n0.append(inserted = new Node(env0, element));
	//	
	//	insertion_result[0] = inserted;
	//	insertion_result[1] = Node.e;
	//	
	//	return insertion_result;
	// }
	
	// If the node is empty, appending is the same as prepending. This code
	// branch can handle the cases where the node is empty or a leaf. 
	if(n0.isLeaf) {
		
		const inserted:Node = new Node(env0, element);
		
		n0.prepend(inserted);
		
		if(n0.length >= maxNodeLoad) {
			n0.children = map(
				splitNodes(n0.children), 
				distribute(partial(newInstance_, Node, _, null, _))
			);
		}
		
		insertion_result[0] = inserted;
		insertion_result[1] = Node.e;
		
		return insertion_result;
	}
	
	// The functionally pure implementation of the stateful way I've switched
	// to. See comment below.
//	const affected_results:Array = getLeastAffectedNode(env0, n0.children);
//	const leastAffectedChild:Node = affected_results[0];
//	const mostAffectedSiblings:Array = affected_results[1];
//	
//	const insertion:Array = computeInsert(element, env0, leastAffectedChild, maxNodeLoad);
//	const min1:Node = insertion[0];
//	const result:Object = insertion[1];
	
	// The calls to getLeastAffectedNode and computeInsert update the internal
	// static "affected_results" and "insertion_result" tuples.
	// 
	// It's the absolute worst thing to mutate state like this, but I've
	// already proven the algorithm is correct. I'm making a second pass to
	// optimize the runtime performance by using state where it doesn't affect
	// the mathematical integrity of the algorithm, and it's more performant
	// to use single static Arrays rather than create new ones just to return
	// multuple values.
	
	// [leastAffectedNode, siblings, inflation] 
	getLeastAffectedNode(env0, n0.children);
	
	const leastAffectedChild:Node = affected_results[0];
	const mostAffectedSiblings:Array = affected_results[1];
	
	// [Node, Node.e] or [Node, Node]
	computeInsert(element, env0, leastAffectedChild, maxNodeLoad);
	
	// Will either be Node.e or a Node
	const result:Object = insertion_result[1];
	const min1:Node = insertion_result[0];
	
	if(result === Node.e) {
		insertion_result[0] = min1;
		insertion_result[1] = Node.e;
	} else if(min1 && (mostAffectedSiblings.length + 2) < maxNodeLoad) {
		// If we hit this, we split a node underneath us. Leave the
		// insertion_result alone, it already contains the split result.
		// 
		// Keep the conditional so we don't throw the else Error below.
	} else if(min1) {
		
		// Split the node
		n0.children = map(
			splitNodes(insertion_result.concat(mostAffectedSiblings)),
			distribute(partial(newInstance_, Node, _, null, _))
		);
		
		insertion_result[0] = n0.children[0];
		insertion_result[1] = n0.children[1];
	} else {
		throw new Error('Couldn\'t insert. This should be impossible.');
	}
	
	return insertion_result;
}

/**
 * Finds:
 * <ol>
 * 	<li>The Node whose area would be least affected by inserting the specified Envelope.</li>
 * 	<li>The Node's siblings.</li>
 * </ol>
 */
internal function getLeastAffectedNode(e0:Envelope, nodes:Array):Array {
	
	const n:int = length(nodes);
	
	if(n <= 0)
		throw new ArgumentError('Can\'t find a node that doesn\'t exist!');
	
	affected_results[0] = head(nodes);
	affected_results[1] = [];
	affected_results[2] = inflation(e0, head(nodes).envelope);
	
	for(var i:int = 1; i < n; ++i) {
		const n1:Node = nodes[i];
		
		const min:Node = affected_results[0];
		const maxs:Array = affected_results[1];
		const minAmount:int = affected_results[2];
		
		const amount:int = inflation(e0, n1.envelope);
		
		maxs.unshift(amount < minAmount ? min : n1);
		
		affected_results[0] = amount < minAmount ? n1 : min;
		affected_results[2] = Math.min(amount, minAmount);
	}
	
	return affected_results;
}

internal function splitNodes(nodes:Array):Array {
	
	findSplitSeeds(nodes);
	
	const n0:Node = split_seeds_results[1][0];
	const n1:Node = split_seeds_results[1][1];
	
	return partitionNodes(
		[n0], n0.envelope, 
		[n1], n1.envelope,
		without(nodes, n0, n1)
	);
}

internal function findSplitSeeds(nodes:Array):Array {
	
	if(length(nodes) <= 0)
		throw new ArgumentError('Can\'t compute split on an empty list');
	
	// cross product
	const products:Array = permutate(nodes);
	const n:int = length(products);
	
	split_seeds_results[1] = head(products);
	split_seeds_results[0] = computeCost.apply(null, split_seeds_results[1]);
	
	for(var i:int = 1; i < n; ++i) {
		
		const maxConst:int = split_seeds_results[0];
		const cost:int = computeCost.apply(null, products[i]);
		
		split_seeds_results[0] = cost > maxConst ? cost : maxConst;
		split_seeds_results[1] = cost > maxConst ? products[i] : split_seeds_results[1];
	}
	
	return split_seeds_results;
}

internal function partitionNodes(n0:Array, e0:Envelope, n1:Array, e1:Envelope, nodes:Array):Array {
	
	if(nodes.length == 0)
		return [[e0, n0], [e1, n1]];
	
	const next:Node = splitPickNext(e0, e1, nodes);
	const en:Envelope = next.envelope;
	
	const rest:Array = without(nodes, next);
	
	const ex:Number = inflation(en, e0);
	const ey:Number = inflation(en, e1);
	
	(ex < ey ? n0 : n1).unshift(next);
	
	return ex < ey ?
		partitionNodes(n0, en.add(e0), n1, e1, rest):
		partitionNodes(n0, e0, n1, en.add(e1), rest);
}

internal function splitPickNext(e0:Envelope, e1:Envelope, nodes:Array):Node {
	
	if(nodes.length == 0)
		throw new ArgumentError('Can\'t compute max diff on empty list');
	
	const computeDiff:Function = function(env:Envelope):Number {
		return Math.abs(inflation(e0, env) - inflation(e1, env));
	};
	
	const  hn:Node = head(nodes) as Node;
	const  hDiff:Number = computeDiff(hn.envelope);
	
	const nextInfo:Array = reduce(
		[hDiff, hn],
		tail(nodes),
		function(tuple:Array, n:Node):Array {
			const maxDiff:Number = tuple[0];
			const diff:Number = computeDiff(n.envelope);
			
			return diff > maxDiff ? [diff, n] : tuple;
	}) as Array;
	
	return nextInfo.pop() as Node;
}

// Proper Functional implementations:
// 
//internal function getLeastAffectedNode(e0:Envelope, nodes:Array):Array {
//	
//	if(nodes.length == 0)
//		throw new ArgumentError('Can\'t find a node that doesn\'t exist!');
//	
//	const nh:Node = head(nodes) as Node;
//	const eh:Envelope = nh.envelope;
//	
//	return reduce(
//		[ nh, [], inflation(e0, eh) ], 
//		tail(nodes),
//		function(triplet:Array, n1:Node):Array {
//			
//			const min:Node = triplet[0];
//			const maxs:Array = triplet[1];
//			const minEnlargement:Number = triplet[2];
//			
//			const e1:Envelope = n1.envelope;
//			
//			const enlargement:Number = inflation(e0, e1);
//			
//			maxs.unshift(enlargement < minEnlargement ? min : n1);
//			
//			return enlargement < minEnlargement ?
//				[n1, maxs, enlargement] : 
//				[min, maxs, minEnlargement];
//		}) as Array;
//}
//
//internal function splitNodes(nodes:Array):Array {
//	
//	const seeds:Array = findSplitSeeds(nodes);
//	const n0:Node = seeds[0];
//	const n1:Node = seeds[1];
//	
//	return partitionNodes(
//		[n0], n0.envelope, 
//		[n1], n1.envelope,
//		without(nodes, n0, n1)
//	);
//}
//internal function findSplitSeeds(nodes:Array):Array {
//	
//	if(nodes.length == 0)
//		throw new ArgumentError('Can\'t compute split on an empty list');
//	
//	// cross product
//	const products:Array = permutate(nodes);
//	const headPair:Array = head(products) as Array;
//	
//	const seedsInfo:Array = reduce(
//		[computeCost.apply(null, headPair), headPair],
//		tail(products),
//		function(tuple:Array, pair:Array):Array {
//			
//			const maxCost:Number = tuple[0];
//			const cost:Number = computeCost.apply(null, pair);
//			
//			return cost > maxCost ? [cost, pair] : tuple;
//		}
//	) as Array;
//	
//	return seedsInfo.pop() as Array;
//}
//
//internal function partitionNodes(n0:Array, e0:Envelope, n1:Array, e1:Envelope, nodes:Array):Array {
//	
//	if(nodes.length == 0)
//		return [[e0, n0], [e1, n1]];
//	
//	const next:Node = splitPickNext(e0, e1, nodes);
//	const en:Envelope = next.envelope;
//	
//	const rest:Array = without(nodes, next);
//	
//	const ex:Number = inflation(en, e0);
//	const ey:Number = inflation(en, e1);
//	
//	(ex < ey ? n0 : n1).unshift(next);
//	
//	return ex < ey ?
//		partitionNodes(n0, en.add(e0), n1, e1, rest):
//		partitionNodes(n0, e0, n1, en.add(e1), rest);
//}
