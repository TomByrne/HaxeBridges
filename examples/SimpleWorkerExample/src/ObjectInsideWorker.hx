package;

class ObjectInsideWorker{
	

	public function new(){

	}

	public function nonStaticMethod():String{
		return "nonStaticMethod: "+Std.string(Math.round(Math.random() * 1000));
	}

}