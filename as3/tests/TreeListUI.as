package
{
	import flash.geom.Rectangle;
	
	import asx.number.snap;
	
	import trxcllnt.ds.RTree;

	public class TreeListUI extends TreeUI
	{
		override protected function getRect(i:int):Rectangle {
			return new Rectangle(i % 10 * 100, snap(i / 10, 1) * 100, 90, 90);
		}
		
		public function TreeListUI(tree:RTree, numRects:int, width:Number, height:Number)
		{
			super(tree, numRects, width, height);
		}
	}
}