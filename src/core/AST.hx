package core;

import core.Tokens.Operator;


enum Expr {
  ENull;
  EBool(bool: Bool);
  ENumber(number: Float);
  EString(string: String);

  EArray(array: Array<Expr>);
  EObject(array: Array<{key: Expr, value: Expr}>);

  ERange(min: Int, max: Int);

  EIdentifier(name: String);
  
  ECall(callee: Expr, arguments: Array<Expr>);
  EField(object: Expr, field: Array<String>);
  EIndex(object: Expr, index: Expr);
 
  EBinary(identifier: Expr, op: Operator, value: Expr);
  EAssign(target: Expr, value: Expr);
}

enum Statement {
  SOutput(out: String);

  SVar(name: String, value: Null<Expr>);
  SFinal(name: String, value: Null<Expr>);

  SFunction(name: String, arguments: Array<String>, body: Array<Statement>);
  SIf(condition: Expr, body: Array<Statement>, else_body: Null<Array<Statement>>);
  SFor(items: Expr, item: String, body: Array<Statement>);

  SExpr(expr: Expr);
}