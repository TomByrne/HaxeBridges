package;

class SimpleWorkerExample_js {
	
	public static function main(){
		new SimpleWorkerExample_js();
	
	}
	 
	public function new()
	{	

		var obj = new ObjectInsideWorker();

		obj.nonStaticMethod(function(result){
			trace("Worker result: "+result);
		});

	}
}