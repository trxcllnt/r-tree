package
{
	import flash.geom.Rectangle;
	
	import asx.number.snap;
	
	import trxcllnt.ds.RTree;

	public class TreeGridUI extends TreeUI
	{
		override protected function getRect(i:int):Rectangle {
			return new Rectangle(i % 10 * 100, Math.floor(i / 10) * 100, 90, 90);
		}
		
		public function TreeGridUI(tree:RTree, numRects:int, width:Number, height:Number)
		{
			super(tree, numRects, width, height);
		}
	}
}