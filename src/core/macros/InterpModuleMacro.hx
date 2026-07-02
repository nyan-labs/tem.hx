package core.macros;

import core.AST.FunctionArgument;
import haxe.macro.Expr;
import core.AST.FunctionArguments;
import core.runtime.Modules.ModuleField;
import haxe.macro.Context;
import haxe.macro.Expr.Field;

class InterpModuleMacro {
  public static function build(): Array<Field> {
    final current_pos = Context.currentPos();

    final cls = Context.getLocalClass().get();

    var fields: Array<Field> = new Array();

    var module_name = cls.name; 
    for(meta in cls.meta.get()) {
      switch meta.name {
        case ":module.name":
          for(param in meta.params) switch param.expr {
            case EConst(CString(string, _)):
              module_name = string;  

              break;

            case _: break;
          }
      }
    }
  
    fields.push({
      name: "__module_name",
      kind: FVar(macro: String, macro $v{module_name}),
      pos: current_pos,
      access: [APublic, AFinal]
    });

    // fields that get exposed to tem as a module
    var module_fields: Array<Expr> = new Array();

    for(field in Context.getBuildFields()) {
      var export = false;
      
      var alias: Array<String> = new Array();
      var prototype: String = null;
      var args: Array<Expr> = new Array();
      var ret: Null<ComplexType> = null;

      switch field.kind {
        case FFun(f):
          for(arg in f.args) {
            args.push(macro {
              name: $v{arg.name},
              type: $v{arg.type.getName()} // todo
            });
          }
          ret = f.ret;
        case _: null;
      };

      for(meta in field.meta) {
        switch meta.name {
          case ":field.alias":
            for(param in meta.params) switch param.expr {
              case EConst(CIdent(s)), EConst(CString(s)): 
                alias.push(s);
              case _: break;
            }
          
          case ":field.prototype":
            var param = meta.params[0];
            if(param != null) switch param.expr {
              case EConst(CIdent(s)): 
                prototype = s;
              case _: null;
            }
          
          case ":field.export":
            export = true;
        }
        
        if(export) {
          trace(args);
          var module_field = macro {
            name: $v{field.name},

            prototype: $v{prototype},
            args: $a{args},
            ret: $v{ret},
            alias: $v{alias}
          }; 
          module_fields.push(module_field);

          continue;
        }
      }
      fields.push(field);
    }

    fields.push({
      name: "__module_fields",
      pos: current_pos,
      kind: FVar(macro: Array<core.runtime.Modules.ModuleField>, macro $a{module_fields}),
      access: [APublic, AFinal]
    });

    return fields;
  }
}
