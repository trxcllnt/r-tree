package 
{
	import flash.display.Sprite;
	
	import trxcllnt.ds.RTree;
	
//	[SWF(width = "600", height = "500")]
	[SWF(width = "1000", height = "8000")]
	public class RTreeUI extends Sprite
	{
		public function RTreeUI()
		{
			super();
			
//			addChild(new TreeUI(new RTree(), 250, stage.stageWidth, stage.stageHeight));
//			addChild(new TreeListUI(new RTree(), 250, stage.stageWidth, stage.stageHeight));
			addChild(new TreeGridUI(new RTree(), 250, stage.stageWidth, stage.stageHeight));
		}
	}
}