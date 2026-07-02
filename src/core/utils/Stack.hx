package core.utils;

import core.AST.Expr;

typedef Memory = Map<String, Expr>;

class Stack {
  public final name = "<unknown>";
  public final memory = new Memory();

  public function new(?name: String) {
    this.name = name;
  }
}