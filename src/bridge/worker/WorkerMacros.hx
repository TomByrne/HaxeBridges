package bridge.worker;


#if macro
import haxe.macro.Expr;

class WorkerMacros implements IBridgeType{

	private	static var buildCount : Int = 0;
	private static var entryPaths:Array<String> = [];

    public function new(){

    }

    public function isBridgeSingleton():Bool{
    	return false;
    }

    public function getInstExpr(bridgeId:Int):Expr{

		var args = Sys.args();
		if(args.indexOf("-swf")!=-1){
			return macro {new bridge.worker.WorkerBridge(haxe.Resource.getBytes("worker_"+$v{bridgeId}).getData());};
		}else if(args.indexOf("-js")!=-1){
			return macro {new bridge.worker.WorkerBridge("worker_"+$v{bridgeId}+".js");};
		}else{
			throw "Unsupported target";
		}
	   	
    }
	

    public static function build(bridgeId:Int, totalClasses:Int, classPath:String) : Array<Field>{
        var pos = haxe.macro.Context.currentPos();
        var fields = haxe.macro.Context.getBuildFields();
        var bridgeFields = new Array<Field>();

        entryPaths.push(classPath);

        var count = 0;
        for(i in 0 ... fields.length){
        	var field = fields[i];

        	if(field.access.indexOf(AStatic)!=-1 || field.access.indexOf(AMacro)!=-1 || field.access.indexOf(APrivate)!=-1 || field.access.indexOf(AInline)!=-1 || field.access.indexOf(ADynamic)!=-1)continue;

        	switch(field.kind){
        		case FVar(t,e):
        			// ignore for now
        		case FProp(get,set,t,e):
        			// ignore for now
        		case FFun(f ):


        			var retType = f.ret;

        			var args : Array<FunctionArg> = f.args.concat([]);
        			var resName:String = "result";
        			var collided = 0;
        			var i = 0;
        			var argList:Array<Expr> = [];
        			while(i < f.args.length){
        				var arg = f.args[i];
        				argList.push(macro $i{arg.name});
        				if(arg.name==resName){
        					collided++;
        					resName = "result"+collided;
        					i = 0;
        				}else{
        					i++;
        				}
        			}

        			var fieldId:Int;
        			var funcBlock:Expr;
		        	if(field.name=="new"){
	        			fieldId = 0;

				       	funcBlock = macro {
				       		_instId = LAST_INST++;
					       	_gateway = bridge.BridgeLookup.getBridge($v{bridgeId});
				       	};
		        	}else{
		        		fieldId = ++count;

				       	funcBlock = macro {};
		        	}
		        	if(retType==null)retType = macro : Null<Dynamic>;
        			var handlerType = macro : $retType -> Void;
        			args.push({name:resName, type: handlerType, opt:true});

        			var expr : Expr = (macro {$funcBlock;_gateway.call($v{buildCount}, _instId, $v{fieldId}, [$a{argList}], $i{resName});});
        			var ffun = FFun({ret:(macro : Void), params:f.params, args:args, expr:expr});
        			bridgeFields.push({name: field.name, pos:field.pos, meta:field.meta, kind:ffun, doc:field.doc, access:field.access});
	        		
        	}
        }

       	bridgeFields.push({name: "LAST_INST", pos:pos, meta:[], kind:FVar( macro : Int, macro 0),access:[APrivate, AStatic]});
       	bridgeFields.push({name: "_gateway", pos:pos, meta:[], kind:FVar( macro : bridge.worker.WorkerBridge),access:[APrivate]});
       	bridgeFields.push({name: "_instId", pos:pos, meta:[], kind:FVar( macro : Int),access:[APrivate]});


    	++ buildCount;
    	if(buildCount==totalClasses){

			var outputDir:String = haxe.macro.Compiler.getOutput();
			var slashIndex:Int = outputDir.lastIndexOf("/");
			if(Sys.systemName()=="Windows"){
				var slashIndex2:Int = outputDir.lastIndexOf("\\");
				if(slashIndex2>slashIndex)slashIndex = slashIndex2;
			}
			var target:String;
			var args = Sys.args();
			if(args.indexOf("-swf")!=-1){
				target = "swf";
			}else if(args.indexOf("-js")!=-1){
				target = "js";
			}

			var bridgeOutput:String = outputDir.substring(0, slashIndex) + "/worker_"+bridgeId+"."+target;

			var classPaths:Array<String> = haxe.macro.Context.getClassPath();
			var cp:String = "";
			for(i in 0...classPaths.length){
				cp += " -cp '"+classPaths[i]+"'";
			}

			var cmd = "haxe -"+target+" '"+bridgeOutput+"'"+cp+" -main bridge.worker.WorkerRoot --macro bridge.worker.WorkerMacros.complete\\(\\'"+entryPaths.join(",")+"\\'\\)";
			if(args.indexOf("-debug")!=-1){
				cmd += " -debug";
			}
			if(target=="swf"){
				var swfVersIndex = args.indexOf("-swf-version");
				var swfVers:String;
				if(swfVersIndex!=-1){
					swfVers = args[swfVersIndex+1];
				}else{
					swfVers = "11.4"; // earliest FP with workers
				}
				cmd += " -swf-version "+swfVers;
			}

			trace("\n\nBEGINNING WORKER COMPILE #"+bridgeId+": \n"+cmd);
      		var ret = Sys.command(cmd);
      		if(ret==0)
				trace("\nWORKER COMPILE #"+bridgeId+" FINISHED\n");
			else
				throw("\nWORKER COMPILE #"+bridgeId+" FAILED\n");

			if(target=="swf"){
				haxe.macro.Context.addResource("worker_"+bridgeId, sys.io.File.getBytes(bridgeOutput));
				sys.FileSystem.deleteFile(bridgeOutput);
			}
    	}

        return bridgeFields;
    }

    public static function complete(classes:String){
    	haxe.macro.Compiler.define("entryClasses", classes);
    	/*var classPaths:Array<String> = classes.split(",");
    	for(path in classPaths){
    		haxe.macro.Compiler.include(path);
    		haxe.macro.Compiler.keep(path);	
    	}*/
    	haxe.macro.Compiler.addMetadata( "@:build(bridge.worker.WorkerMacros.buildTypeMap('"+classes+"'))", "bridge.worker.WorkerRoot");	
    }
    public static function buildTypeMap(classes:String):Array<Field>{
        var pos = haxe.macro.Context.currentPos();
        var fields = haxe.macro.Context.getBuildFields();
    	var classPaths:Array<String> = classes.split(",");
    	var classList:Array<Expr> = [];
    	for(classPath in classPaths){
    		classList.push(macro $i{classPath});
    		haxe.macro.Compiler.addMetadata( "@:build(bridge.worker.WorkerMacros.buildFieldMap('"+classPath+"'))", classPath);
    	}

       	fields.push({name: "classes", pos:pos, meta:[], kind:FVar( macro : Array<Dynamic>, macro [$a{classList}]), access:[APrivate, AStatic]});
        return fields;
    }
    public static function buildFieldMap(classPath:String):Array<Field>{
        var pos = haxe.macro.Context.currentPos();
        var fields = haxe.macro.Context.getBuildFields();

        var newExpr:Expr;
        var nonStaticExprs:Array<Case> = [];
        var count = 0;
        for(i in 0 ... fields.length){
        	var field = fields[i];

        	if(field.access.indexOf(AStatic)!=-1 || field.access.indexOf(AMacro)!=-1 || field.access.indexOf(APrivate)!=-1 || field.access.indexOf(AInline)!=-1 || field.access.indexOf(ADynamic)!=-1)continue;

        	switch(field.kind){
        		case FVar(t,e):
        			// ignore for now
        		case FProp(get,set,t,e):
        			// ignore for now
        		case FFun(f ):


        			var retType = f.ret;

        			var argDefs : Array<FunctionArg> = f.args;
        			var args:Array<Expr> = [];
        			for(i in 0...argDefs.length){
        				args.push(macro params[$v{i}]);
        			}
		        	if(field.name=="new"){
		        		newExpr = macro (Type.createInstance($i{classPath}, [$a{args}]));
		        	}else{
		        		count++;
		        		nonStaticExprs.push({values:[macro $v{count}], expr:macro return Reflect.callMethod(inst, Reflect.field(inst, $v{field.name}), [$a{args}])});
		        	}
	        		
        	}
        }

        var pathParts = classPath.split(".");
        var typeName = pathParts.pop();
        var collectionType = TPath({name:"Map", pack:[], params:[TPType(TPath({name:"Int", pack:[], params:[]})), TPType(TPath({name:typeName, pack:pathParts, params:[]}))]});
       	fields.push({name: "_instances", pos:pos, meta:[], kind:FVar( collectionType, macro new Map()), access:[APrivate, AStatic]});

       	var nonStaticSwitch = {expr:ESwitch(macro field, nonStaticExprs, macro throw "Unknown field index: "+field), pos:pos};
       	var resultExpr = macro {
       		if(field==0){
				// constructor
				_instances.set(instId, $newExpr);
			}else if(field<0){
				// static function, not done yet
				switch(field){
					default: throw "Unknown field index: "+field;
				}
			}else{
				// non-static function
				var inst = _instances.get(instId);
				${nonStaticSwitch}
			}
			return null;
       	}
       	fields.push({name: "_getResult", pos:pos, meta:[], kind:FFun({ret:macro : Dynamic, params:[], args:[{name:"instId", opt:false, type: macro : Int}, {name:"field", opt:false, type: macro : Int}, {name:"params", opt:false, type: macro : Array<Dynamic>}], expr:resultExpr}), access:[APrivate, AStatic]});


    	return fields;
    }

}
#end
