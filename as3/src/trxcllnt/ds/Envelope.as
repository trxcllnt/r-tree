package trxcllnt.ds
{
	import flash.geom.Rectangle;
	
	import asx.array.pluck;
	import asx.array.reduce;
	
	public class Envelope extends Rectangle
	{
		public function Envelope(...args)
		{
			var r:Rectangle = new Rectangle();
			
			if(args[0] is Number) {
				r.x = args[0];
				r.y = args[1];
				r.width = args[2];
				r.height = args[3];
			} else if(args[0] is Rectangle) {
				r = args[0];
			}
			
			super(r.x, r.y, r.width, r.height);
		}
		
		public static function fromNodes(nodes:Array):Envelope {
			return reduce(null, pluck(nodes, 'envelope'), function(union:Envelope, env:Envelope):Envelope {
				return union ? union.add(env) : env;
			}) as Envelope;
		}
		
		override public function intersects(toIntersect:Rectangle):Boolean {
			return (toIntersect == this) || super.intersects(toIntersect);
		}
		
		public function add(other:Rectangle):Envelope {
			return new Envelope(union(other));
		}
		
		public function addMany(envelopes:Array, ...args):Envelope {
			return envelopes.reduce(this, function(memo:Envelope, env:Envelope):Envelope {
				return memo.add(env);
			}) as Envelope;
		}
		
		public function get area():Number {
			return width * height;
		}
	}
}
