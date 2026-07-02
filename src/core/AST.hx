package core;

import core.Tokens.StringKind;
import core.Tokens.Position;
import haxe.Constraints.Function;
import haxe.DynamicAccess;
import haxe.ds.Either;
import core.Tokens.Operator;

enum ExprDef {
  ENull;
  EBool(bool: Bool);
  ENumber(number: Float);
  EString(string: String, kind: StringKind);
	ELambda(arguments: Array<FunctionArgument>, body: Expr);

  EBlock(exprs: Array<Expr>, mode: BlockMode);

  EArray(array: Array<Expr>);
  EObject(map: Map<String, Expr>);

  ERange(min: Int, max: Int);

  EIdentifier(name: String);
  
  ECall(callee: Expr, arguments: Array<Expr>);
  EField(object: Expr, field: Expr);
  EIndex(object: Expr, index: Expr);
 
  EBinary(c1: Expr, op: Operator, c2: Expr);
  EAssign(target: Expr, value: Expr);

  EOptional(e: Expr);

  EMeta(name: String, expr: Expr);

  // superseded by EMeta("await", expr);
  // EAwait(e: Expr);

  // statements:
  // this should be abolished and become EOutput(out: Array<Expr>, raw: Bool)
  // EOutput(outs: Array<Expr>);

  EVar(name: String, value: Expr);
  EFinal(name: String, value: Expr);

  ESwitch(pattern: Expr, cases: Array<SwitchCase>);

  EFunction(name: String, arguments: Array<FunctionArgument>, body: Expr);
  EIf(condition: Expr, body: Expr, else_body: Expr); // !!!
  EFor(items: Expr, item: String, body: Expr);

  // SExpr(expr: Expr);
}

enum BlockMode {
  MImplicitLast;
  MConcat;
  MReturnOnly;
}

typedef ObjectType = Map<String, Value>;
typedef SwitchCase = {
  pattern: Expr,
  body: Expr
};

enum Value {
  VNull;
	VNumber(v: Float);
	VString(v: String);
	VBool(v: Bool);
	VObject(map: ObjectType);
  VArray(array: Array<Value>);
	VFunction(func: FunctionDef);
	VEnumValue(name: String, type: String, values: Array<String>);
	VUnknown(v: Dynamic);
	// VCustom(name: String, base: Value);
  
  VOptional(v: Value);

  VEmpty;
  
  VNativeClass(c: Dynamic);
}

// enum ValueType {
// 	VNull;
// 	VNumber;
// 	VString;
// 	VBool;
// 	VObject;
//   VArray(type: ValueType);
// 	VFunction(arguments: Array<FunctionArgument>, return_type: ValueType);
// 	VClass(c: Class<Dynamic>);
// 	VEnum(e: Enum<Dynamic>);
// 	// VCustom(name: String, base: ValueType);
// 	VUnknown;

//   VOptional(v: ValueType);
// }

typedef FunctionArgument = {
  name: String,
  type: String,
}
typedef FunctionArguments = Array<FunctionArgument>

@:structInit
class FunctionDef {
  public var name: String;
  public var params: Null<FunctionArguments>;
  public var body: Expr;
}

typedef Expr = {
  var expr: ExprDef;
  var pos: Position;
};