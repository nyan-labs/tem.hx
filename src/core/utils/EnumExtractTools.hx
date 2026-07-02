package core.utils;

// https://code.haxe.org/category/macros/extract-enum-value.html

#if macro 
import haxe.macro.Expr;
#end

class EnumExtractTools {
  public static macro function extract(value: ExprOf<EnumValue>, pattern: Expr): Null<Expr> {
    switch pattern {
      case macro $a => $b:
        return macro switch ($value) {
          case $a: $b;
          default: null;
        }
      default:
        throw new Error("Invalid enum value extraction pattern", pattern.pos);
    }
  }
}