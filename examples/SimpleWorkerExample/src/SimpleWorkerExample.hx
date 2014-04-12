package;

import flash.display.*;
import flash.text.*;
import flash.Lib;

class SimpleWorkerExample extends Sprite{
	
	public static function main(){
		Lib.current.addChild(new SimpleWorkerExample());

		
		var traceField = new TextField();
		traceField.width = 500;
		Lib.current.addChild(traceField);
		haxe.Log.trace = function(v : Dynamic, ?inf : haxe.PosInfos){
			traceField.appendText("\n"+v);
		};
	}
	 
	public function new()
	{
		super();

		var obj = new ObjectInsideWorker();

		obj.nonStaticMethod(function(result){
			trace("Worker result: "+result);
		});

	}
}