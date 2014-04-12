package;


#if macro

import haxe.macro.Expr;
import bridge.IBridgeType;

class Bridge{

    private static var bridgeClasses:Array<String> = [];

    private static var shortcuts:Map<String, String> = [
        "Worker" => "bridge.worker.WorkerMacros"

    ];

	public static function add( entryClasses : String, bridgeClass : String ) {

        if(shortcuts.exists(bridgeClass)){
            bridgeClass = shortcuts.get(bridgeClass);
        }

        var bridgeId = bridgeClasses.length;
        var classList:Array<String> = entryClasses.split(",");
        for(i in 0 ... classList.length){
        	var classPath:String = classList[i];
           haxe.macro.Compiler.addMetadata( "@:build("+bridgeClass+".build("+bridgeId+","+classList.length+",'"+classPath+"'))" , classPath);
        }
		haxe.macro.Compiler.addMetadata( "@:build(Bridge.createLookup())" , "bridge.BridgeLookup");
		haxe.macro.Compiler.include(bridgeClass);
		bridgeClasses.push(bridgeClass);
    }


    public static function createLookup():Array<Field>{
        var pos = haxe.macro.Context.currentPos();

    	var lookupFields:Array<Field> = [];
    	var getSwitch:Array<Case> = [];
    	for(i in 0...bridgeClasses.length){
    		var bridgeTypeName = bridgeClasses[i];
			var bridgeType:IBridgeType = Type.createInstance(Type.resolveClass(bridgeTypeName), []);
			var switchExpr:Expr;
			if(bridgeType.isBridgeSingleton()){
				// not done yet
			}else{
		       	switchExpr = bridgeType.getInstExpr(i);
			}
		    getSwitch.push({values:[macro $v{i}], expr:macro return $switchExpr});
    	}
    	var funcBody:Expr = {pos:pos, expr:ESwitch(macro bridgeId, getSwitch, macro return null)};
	   	lookupFields.push({name: "getBridge", pos:pos, meta:[], kind:FFun({ret:(macro : Dynamic), params:[], args:[{name:"bridgeId", opt:false, type:(macro : Int	)}], expr:funcBody}), access:[APublic, AStatic]});
    	var fields = haxe.macro.Context.getBuildFields();
    	return fields.concat(lookupFields);
    }
}

#end