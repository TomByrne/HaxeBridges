/****
* Copyright 2014 tbyrne.org All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without modification, are
* permitted provided that the following conditions are met:
* 
*    1. Redistributions of source code must retain the above copyright notice, this list of
*       conditions and the following disclaimer.
* 
*    2. Redistributions in binary form must reproduce the above copyright notice, this list
*       of conditions and the following disclaimer in the documentation and/or other materials
*       provided with the distribution.
* 
* THIS SOFTWARE IS PROVIDED BY TBYRNE.ORG "AS IS" AND ANY EXPRESS OR IMPLIED
* WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
* FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TBYRNE.ORG OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
****/

package bridge.worker;

#if (!macro && flash)
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

#if (!macro && flash)
	private static var mainToWorker:MessageChannel;
	private static var workerToMain:MessageChannel;
	
	private static var worker:Worker;
	
	public static function main()
	{

		mainToWorker = Worker.current.getSharedProperty("mainToWorker");
		workerToMain = Worker.current.getSharedProperty("workerToMain");
		//Listen for messages from the mian thread
		mainToWorker.addEventListener(Event.CHANNEL_MESSAGE, onMainToWorker);


					       	
		haxe.Log.trace = function(v : Dynamic, ?inf : haxe.PosInfos){
			workerToMain.send("trace");
			workerToMain.send(v);
			workerToMain.send(inf);
		};
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
#end


#if (!macro && js)
	
	public static function main()
	{
km.
		untyped __js__("self.onmessage = this.onMainToWorker");

		haxe.Log.trace = function(v : Dynamic, ?inf : haxe.PosInfos){
			untyped __js__("self.postMessage( ['trace', v, inf] )");
		};
	}
			
	//Main >> Worker
	private static function onMainToWorker(event:js.html.MessageEvent):Void {

		var message:Array<Dynamic> = event.data;

		var id : Int = message[0];
		var typeId = message[1];
		var instId = message[2];
		var field : Int = message[3];
		var params = message[4];

		var type:Dynamic = classes[typeId];
		var result:Dynamic = type._getResult(instId, field, params);

		if(id!=-1){
			untyped __js__("self.postMessage( [id, result] )");
		}
	}

#end
}
