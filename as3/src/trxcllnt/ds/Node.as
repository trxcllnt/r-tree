package trxcllnt.ds
{
	import flash.geom.Rectangle;
	
	import asx.array.contains;
	import asx.array.filter;
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.without;
	import asx.fn.callProperty;
	import asx.fn.setProperty;
	import asx.number.sum;

	/**
	 * Node has an associated Envelope, Element, and child list.
	 */
	public class Node
	{
		public static const e:Object = {};
		
		public function Node(rect:Rectangle = null, object:* = null, array:Array = null, parentNode:Node = null) {
			
			env = cachedEnv = rect is Envelope ?
				(rect as Envelope) :
				new Envelope(rect);
			
			this.element = object === null || object == undefined ? Node.e : object;
			parent = parentNode;
			
			children = array || kids;
		}
		
		public var parent:Node = null;
		
		private var kids:Array = [];
		public function get children():Array {
			return kids;
		}
		
		public function set children(values:Array):void {
			kids = values.concat(); // defensive copy
			forEach(kids, setProperty('parent', this));
			invalidateBoundingBox();
		}
		
		public var element:* = Node.e;
		
		private var env:Envelope = null;
		private var cachedEnv:Envelope = null;
		
		public function get envelope():Envelope {
			
			const invalidated:Boolean = boundingBoxInvalidated;
			boundingBoxInvalidated = false;
			
			return invalidated && !isEmpty ?
				(cachedEnv = env.add(minBoundingBox)) :
				cachedEnv;
		}
		
		public function set envelope(val:Envelope):void {
			invalidateBoundingBox();
			env = val;
		}
		
		public function get length():int {
			return kids.length;
		}
		
		public function get minBoundingBox():Envelope {
			return Envelope.fromNodes(kids);
		}
		
		public function get isEmpty():Boolean {
			return length == 0;
		}
		
		public function get isLeaf():Boolean {
			return isEmpty || (size - length) == 0;
		}
		
		public function get size():int {
			return length + sum(pluck(children, 'size'));
		}
		
		public function clone(deep:Boolean = false):Node {
			return new Node(env, element, deep ? map(kids, callProperty('clone')) : kids, parent);
		}
		
		public function append(node:Node):Node {
			kids.push(node);
			children = kids;
			return this;
		}
		
		public function container(node:Node):Node {
			if(contains(children, node))
				return this;
			
			var container:Node = null;
			
			for(var i:int = 0, n:int = kids.length; i < n; ++i) {
				container = kids[i].container(node);
				
				if(container != null)
					return container;
			}
			
			return null;
		}
		
		public function intersects(other:*):Boolean {
			return other is Rectangle ?
				envelope.intersects(other) :
				envelope.intersects(other.envelope);
		}
		
		public function intersections(other:*):Array {
			return filter(children, callProperty('intersects', other));
		}
		
		public function prepend(node:Node):Node {
			kids.unshift(node);
			children = kids;
			return this;
		}
		
		public function remove(element:*):Node {
			if(element is Node) {
				children = without(kids, element);
				element.parent = null;
			}
			
			return this;
		}
		
		private var boundingBoxInvalidated:Boolean = false;
		private function invalidateBoundingBox():Boolean {
			boundingBoxInvalidated = true;
			
			return parent ?
				parent.invalidateBoundingBox() :
				boundingBoxInvalidated;
		}
	}
}