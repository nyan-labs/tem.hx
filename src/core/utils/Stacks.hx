package core.utils;

import haxe.ds.StringMap;
import core.AST.Value;
import haxe.ds.GenericStack;

class Stacks extends GenericStack<Stack> {
  public function new() {
    super();
  }

  public function get(key: String) {
    for(s in this.iterator()) {
      if(s.memory.exists(key))
        return s.memory.get(key);
    }

    return null;
  }

  // public inline function set(scope: Int, id: String, value: Value) {
  //   if(!this.data.exists(scope))
  //     this.data.set(scope, new Map());

  //   final scope = this.data.get(scope);
  //   scope.set(id, value);
  // }
}