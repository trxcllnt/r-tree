package trxcllnt.ds
{
	import flash.geom.Rectangle;

	public interface RTree
	{
		function container(node:Node):Node;
		
		function insert(elem:*, rect:Rectangle):Node;
		
		function intersections(other:*):Array;
		
		function search(branch:Array,
						traversalTerminator:Function, /*(Node):Boolean*/
						reduction:Function = null     /*(Node):Array  */):Array;
		
		function leaves():Array
		function values():Array
	}
}