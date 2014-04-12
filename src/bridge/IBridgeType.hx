package bridge;

#if macro

import haxe.macro.Expr;

interface IBridgeType{
	
    public function isBridgeSingleton():Bool;

    public function getInstExpr(bridgeId:Int):Expr;
}

#else

interface IBridgeType{

}

#end