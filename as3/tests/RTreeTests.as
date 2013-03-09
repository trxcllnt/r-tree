package 
{
	import flash.display.Sprite;
	
	import trxcllnt.ds.RTree;
	
	[SWF(width = "600", height = "500")]
	public class RTreeTests extends Sprite
	{
		public function RTreeTests()
		{
			super();
			
			new TreeTests(new RTree(), 100, stage.stageWidth, stage.stageHeight);
			
//			var enumerable:IEnumerable = Enumerable.range(0, 10).
//				map(function(i:int):Point {
//					return new Point(Math.random() * 100, Math.random() * 100);
//				});
//			
//			var itr:IEnumerator = enumerable.getEnumerator();
//			while(itr.moveNext())
//				trace(itr.current);
//			
//			var observable:IObservable = Observable.fromEvent(container, MouseEvent.MOUSE_MOVE).
//				map(function(event:MouseEvent):Point {
//					return new Point(event.stageX, event.stageY);
//				});
//			
//			observable.subscribe(function(point:Point):void {
//				trace(point);
//			});
		}
	}
}
