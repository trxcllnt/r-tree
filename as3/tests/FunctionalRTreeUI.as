package 
{
	import flash.display.Sprite;
	
	import trxcllnt.ds.RTreeFunctional;
	
//	[SWF(width = "600", height = "500")]
	[SWF(width = "1000", height = "8000")]
	public class FunctionalRTreeUI extends Sprite
	{
		public function FunctionalRTreeUI()
		{
			super();
			
			addChild(new TreeUI(new RTreeFunctional(), 500, stage.stageWidth, stage.stageHeight));
		}
	}
}