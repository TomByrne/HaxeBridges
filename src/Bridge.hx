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