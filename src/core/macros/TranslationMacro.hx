package core.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
// import haxe.macro.;

using StringTools;

class TranslationMacro {
  static macro function build_locale(resource: String): Array<Field> {
    // Context.registerModuleDependency(haxe.macro.Context.getLocalModule(), path);
    return try {
      var json = haxe.Json.parse(haxe.Resource.getString(resource));

      var fields = Context.getBuildFields();
      
      for(key in Reflect.fields(json)) {
        var locale: Field = {
          name: key.toLowerCase(),
          pos: Context.currentPos(),
          kind: FVar(macro: String, macro $v{key.replace("_", "-").toLowerCase()}),
          access: [APublic],
        };
  
        fields.push(locale);
      }
      
      return fields;
    } catch (e) {
      haxe.macro.Context.error('Failed to load json: $e', haxe.macro.Context.currentPos());
    }
  }
}
