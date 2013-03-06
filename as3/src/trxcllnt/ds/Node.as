package trxcllnt.ds
{
	import flash.geom.Rectangle;
	
	import asx.array.filter;
	import asx.array.pluck;
	import asx.fn.getProperty;
	import asx.fn.sequence;
	import asx.number.sum;

	/**
	 * Node has an associated Envelope, Element, and child list.
	 */
	public class Node
	{
		public static const e:Object = {};
		
		public function Node(rect:Rectangle = null, object:* = null, array:Array = null) {
			
			env = cachedBoundingBox = cachedEnv = rect is Envelope ?
				(rect as Envelope) :
				new Envelope(rect);
			
			elem = object === null || object == undefined ? Node.e : object;
			children = array || kids;
		}
		
		private const kids:Array = [];
		public function get children():Array {
			return kids;
		}
		
		public function set children(values:Array):void {
			kids = values//.concat(); // defensive copy?
			boundingBoxInvalidated = true;
		}
		
		private var elem:* = Node.e;
		public function get element():* {
			return elem;
		}
		
		private var env:Envelope = null;
		private var cachedBoundingBox:Envelope = null;
		private var cachedEnv:Envelope = null;
		private var boundingBoxInvalidated:Boolean = false;
		
		public function get envelope():Envelope {
			
			const invalidated:Boolean = boundingBoxInvalidated;
			boundingBoxInvalidated = false;
			
			return invalidated && length ?
				(cachedEnv = env.add(cachedBoundingBox = minBoundingBox)) :
				cachedEnv;
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
		
		public function clone():Node {
			return new Node(env, elem, kids);
		}
		
		public function intersections(rect:Rectangle):Array {
			return filter(children, sequence(getProperty('envelope'), rect.intersects));
		}
		
		public function append(node:Node):Node {
			kids.push(node);
			children = kids;
			return this;
		}
		
		public function prepend(node:Node):Node {
			kids.unshift(node);
			children = kids;
			return this;
		}
	}
}