package core.utils;

import core.Tokens.TokenPos;
import core.Tokens.Token;
import haxe.PosInfos;
import haxe.Exception;
import haxe.exceptions.PosException;

class ParseError extends PosException {
  public final token: TokenPos;

	public function new(token: TokenPos, message: String, ?previous: Exception, ?pos:Null<PosInfos>) {
    super(message, previous, pos);
     
		this.token = token;
	}


	override function toString():String {
		return '${posInfos.fileName}:${posInfos.lineNumber} in ${posInfos.className}.${posInfos.methodName}: ${message} from ?:${token.pos.line}:${token.pos.column}';
	}
}