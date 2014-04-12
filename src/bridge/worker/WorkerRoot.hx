package bridge.worker;

#if !macro
import flash.events.Event;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
#end

using Reflect;

class WorkerRoot
{
	macro static function addValue( key : String ) { 
	   return macro $v{haxe.macro.Context.definedValue(key)}; 
	} 

#if !macro
	private static var mainToWorker:MessageChannel;
	private static var workerToMain:MessageChannel;
	
	private static var worker:Worker;
	
	public static function main()
	{

		mainToWorker = Worker.current.getSharedProperty("mainToWorker");
		workerToMain = Worker.current.getSharedProperty("workerToMain");
		//Listen for messages from the mian thread
		mainToWorker.addEventListener(Event.CHANNEL_MESSAGE, onMainToWorker);
	}
			
	//Main >> Worker
	private static function onMainToWorker(event:Event):Void {

		while(mainToWorker.messageAvailable){
			var id = mainToWorker.receive();
			var typeId = mainToWorker.receive();
			var instId = mainToWorker.receive();
			var field = mainToWorker.receive();
			var params = mainToWorker.receive();

			var type = classes[typeId];
			var result:Dynamic = type._getResult(instId, field, params);

			if(id!=-1){
				workerToMain.send(id);
				workerToMain.send(result);
			}
		}
	}
	/*private static function getResult(instId:Int, field:Int, params:Array<Dynamic>):Dynamic{
		if(field==0){
			// constructor
			var type = classes[typeId];
			instances.set(typeId+"_"+instId) = ;
		}else if(field<0){
			var type = classes[typeId];
			// static function, not done yet
			switch(typeId){
				default: throw "Unknown field index: "+field;
			}
		}else{
			// non-static function
			var inst = instances.get(typeId+"_"+instId);
			switch(typeId){
				case 0: return obj.nonStaticMethod();
				default: throw "Unknown field index: "+field;
			}
		}
		return null;
	}*/
#end
}
