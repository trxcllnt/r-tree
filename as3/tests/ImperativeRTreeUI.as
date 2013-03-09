package 
{
	import flash.display.Sprite;
	
	import trxcllnt.ds.RTreeImperative;
	
	//	[SWF(width = "600", height = "500")]
	[SWF(width = "1000", height = "8000")]
	public class ImperativeRTreeUI extends Sprite
	{
		public function ImperativeRTreeUI()
		{
			super();
			
			addChild(new TreeUI(new RTreeImperative(), 500, stage.stageWidth, stage.stageHeight));
		}
	}
}