package core.runtime;

import haxe.macro.Expr.FunctionArg;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Function;
import haxe.macro.Expr.TypeParamDecl;
import core.AST.FunctionArguments;

@:autoBuild(core.macros.InterpModuleMacro.build())
interface INativeModule {
  final __module_name: String;
  final __module_fields: Array<ModuleField>;

  // final methods = {}
}
typedef ModuleField = {
  var name: String;
  var alias: Array<String>;

  var args: FunctionArguments;
  var ret: Null<ComplexType>;
  var prototype: Null<String>;
}