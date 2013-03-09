package 
{
	import flash.display.Sprite;
	
	import trxcllnt.ds.RTreeImperative;
	
	[SWF(width = "600", height = "500")]
	public class ImperativeRTreeTests extends Sprite
	{
		public function ImperativeRTreeTests()
		{
			super();
			
			new TreeTests(new RTreeImperative(), 100, stage.stageWidth, stage.stageHeight);
		}
	}
}
