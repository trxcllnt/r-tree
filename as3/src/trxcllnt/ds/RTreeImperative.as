package trxcllnt.ds
{
	import flash.geom.Rectangle;
	
	import asx.array.filter;
	import asx.array.flatten;
	import asx.array.head;
	import asx.array.last;
	import asx.array.map;
	import asx.array.pluck;
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
	
	public class RTreeImperative extends RTreeFunctional implements RTree
	{
		public function RTreeImperative(maxNodeLoad:int = 8)
		{
			super(maxNodeLoad);
		}
		
		override public function insert(elem:*, rect:Rectangle):Node {
			
			const env:Envelope = rect is Envelope ?
				(rect as Envelope) :
				new Envelope(rect);
			
			// computeInsert has two return signatures:
			// insertion: Tuple<Leaf, e>
			// split:     Tuple<Node, Node>
			computeInsert(elem, env, this, maxNodeLoad);
			
			// Can be either "Node.e" or the right-
			// associated Node from a split operation.
			const result:Object = last(insertion_result);
			
			// If result is e, an insertion was made.
			// If result is a Node, a split was performed.
			return (result === Node.e ? head(insertion_result) : result) as Node;
		}
	}
}

import asx.array.head;
import asx.array.length;
import asx.array.map;
import asx.array.permutate;
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

internal function computeDiff(e0:Envelope, e1:Envelope, env:Envelope):Number {
	return Math.abs(e0.computeInflation(env) - e1.computeInflation(env));
}

// Impure stateful (but more performant) implementation.
// 
// It's the absolute worst thing to mutate state like this, but I've
// already written the mathematically correct implementation. I'm on my second
// pass to optimize the runtime performance by using state where it doesn't
// affect the mathematical integrity of the algorithm. It's more performant
// to use single static Arrays to store computational results, rather than
// create new ones just to return multuple values.

internal const insertion_result:Array = [null, null];
internal const affected_results:Array = [null, [], 0];
internal const split_seeds_results:Array = [];
internal const partition_results:Array = [[], []];

internal function computeInsert(element:*, env0:Envelope, n0:Node, maxNodeLoad:int):Array {
	
	// If the node is empty, appending is the same as prepending. This branch
	// can handle the cases where the node is either a leaf and empty.
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
	
	// The calls to getLeastAffectedNode and computeInsert update the internal
	// static "affected_results" and "insertion_result" tuples.
	
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
	affected_results[1].length = 0;
	affected_results[2] = e0.computeInflation(head(nodes).envelope);
	
	for(var i:int = 1; i < n; ++i) {
		const n1:Node = nodes[i];
		
		const min:Node = affected_results[0];
		const maxs:Array = affected_results[1];
		const minAmount:int = affected_results[2];
		
		const amount:int = e0.computeInflation(n1.envelope);
		
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
	
	if(nodes.length == 0) {
		
		partition_results[0][0] = e0;
		partition_results[0][1] = n0;
		
		partition_results[1][0] = e1;
		partition_results[1][1] = n1;
		
		return partition_results;
	}
	
	const next:Node = splitPickNext(e0, e1, nodes);
	const en:Envelope = next.envelope;
	
	nodes.splice(nodes.indexOf(next), 1);
	
	const ex:Number = en.computeInflation(e0);
	const ey:Number = en.computeInflation(e1);
	
	(ex < ey ? n0 : n1).unshift(next);
	
	return ex < ey ?
		partitionNodes(n0, en.add(e0), n1, e1, nodes):
		partitionNodes(n0, e0, n1, en.add(e1), nodes);
}

internal function splitPickNext(e0:Envelope, e1:Envelope, nodes:Array):Node {
	
	if(nodes.length == 0)
		throw new ArgumentError('Can\'t compute max diff on empty list');
	
	var selected:Node = head(nodes) as Node;
	var maxDiff:Number = computeDiff(e0, e1, selected.envelope);
	
	const n:int = nodes.length;
	
	for(var i:int = 1; i < n; ++i) {
		
		const n0:Node = nodes[i] as Node;
		const diff:Number = computeDiff(e0, e1, n0.envelope);
		
		selected = diff > maxDiff ? n0 : selected;
		maxDiff = diff > maxDiff ? diff : maxDiff;
	}
	
	return selected;
}
