package core;

// import core.runtime.types.BaseString;
import core.Tokens.Operator;
import core.utils.Stack;
import haxe.EnumTools;
import core.Tokens.Position;
import haxe.exceptions.NotImplementedException;
import haxe.DynamicAccess;
import core.runtime.Modules.INativeModule;
import core.runtime.std.Translation;
import haxe.Constraints.Function;
import haxe.ds.GenericStack;
import core.AST;
import core.utils.Stacks;

using core.utils.EnumExtractTools;
using StringTools;

typedef InterpreterConfig = {
}

final blank_pos: Position = {
  name: "?",
  line: -1,
  column: -1
}

@:nullSafety(Strict)
@:analyzer(optimize, local_dce)
class Interpreter {
  public final stacks: Stacks = new Stacks();
  public final globals: Map<String, Value> = new Map();

  public var config: InterpreterConfig;
  public var output: Array<Value> = new Array();

  public function new(config: InterpreterConfig = null) {
    this.config = config ?? {};
  }

  // final globals: Map<String, Value> = new Map();

  public function load_module(module: INativeModule) {
    trace(module.__module_name, module.__module_fields);

    var module_value = haxe_to_value(module);
    globals.set(module.__module_name, module_value);
  }

  inline function debug(...text: String) {
    #if tem_hx.interp.debug
    trace(text);
    #end
  }
  inline function debug_expr(expr: Expr, ...texts: String) {
    #if tem_hx.interp.debug
    var column = expr.pos.column;
    var line = expr.pos.line;

    var text = texts.toArray().join(", ");

    trace('${expr.expr.getName()} on ?stack?:$line:$column: $text');
    #end
  }

  // public function execute(exprs: Array<Expr>, ?scope: Scope): Value {
  //   scope = scope ?? {};
  //   stack.add(scope);

  //   var ret = VNull; // do we add a VNone or VVoid just to avoid output conflicts?

  //   // todo: parse statements and run them in functions from VM (like vm.if, vm.for, blah)
  //   for(e in exprs) {
  //     if(e.expr == null) 
  //       continue;

  //     trace('${e.pos.line}:${e.pos.column}: ${e.expr}');
  //     switch e.expr {
  //       case ESwitch(pattern, cases):
  //         var ret = parse_switch(pattern, cases);
  //         if(ret != null)
  //           execute(ret);

  //       case EVar(name, value):
  //         do_var(name, value);
  
  //       case EFor(expr_to_value(_) => items, item, body):
  //         switch items {
  //           case VArray(array):
  //             for(i in array) {
  //               scope.set(item, i);
    
  //               execute(body);
  //             }

  //           case _: throw "nope";
  //         }

  //       case EIf(condition, body, else_body):
  //         var body = do_if(condition, body, else_body);
  //         if(body != null) 
  //           execute(body);

  //       case _:
  //         var value = expr_to_value(e);
  //         trace(value);

  //         // if(scope.is_output) {
  //           // var hx_value = value_to_haxe(value);
  //           // if(hx_value == VNull) throw '$value WHAT HTE SHIT';

  //           // output.append(cast hx_value);
          
  //           // if(scope.is_implicit_return) {
  //             // ret = value;
  //             // break;
  //           // }

  //         // } else if(scope.is_implicit_return) {
  //           output.push(value);
  //           ret = value;
  //           // break;

  //         // } else value;

  //       // case _:
  //         // return null;
  //         // throw 'unknown statement `${statement.statement}` at ${statement.line}:${statement.column}';
  //     }
  //   }

  //   stack.pop();

  //   return ret;
  // }

  public function run(exprs: Array<Expr>, ?stack: Stack, ?caller: String = "unknown.tem") {
    var stack = stack ?? new Stack();
    stacks.add(stack);
    
    for(expr in exprs) {
      var column = expr.pos.column;
      var line = expr.pos.line;
      
      debug_expr(expr, "expr_to_value");
      output.push(expr_to_value(expr));
    }

    stacks.pop();
  }

  public function output_raw()
    return output.map((v) -> value_to_haxe(v)).join("");

  function parse_switch(pattern: Expr, cases: Array<SwitchCase>) {
    var fallback = Lambda.find(cases, (c) -> c.pattern.expr.match(EIdentifier(_)));
    if(fallback != null)
      cases.remove(fallback);

    var body: Null<Expr> = null;

    for(c in cases) {
      // todo
      var pattern = expr_to_value(pattern);
      var case_pattern = expr_to_value(c.pattern);

      trace(c.body);

      var match = switch pattern {
        case VEnumValue(name, type, value):
          var pattern_values = case_pattern.getParameters();
          true;

        case _:
          true;
      }
      // var match = pattern.expr.match(case_.pattern.expr);

      if(match)
        body = c.body;
    }

    if(fallback != null && body == null)
      body = fallback.body;

    // if(body != null) {
      // do we do a parse_switch (also applies for do_if and such) which lets the statements and exprs decide waht they want to do
      // var ret = expr_to_value(body[0]);
      // trace(ret);
      // var ret = execute(body, {
      //   var scope: Scope = {
      //     is_implicit_return: true,
      //     // do_output_raw_string: false // how do i make this work for {#switch} and not just {#var a = switch}
      //   };

      //   // todo: funny stuff for like `case Enum(hi): trace(hi)` or `case hi: trace(hi)`
      //   // scope.set(, VString("hi"));

      //   scope;
      // });

      // ret;
    // } else
      // VNull;
    return body;
  }

  function do_var(name: String, expr: Expr) {
    var stack = stacks.first();
  
    if(stack != null)
      stack.memory.set(name, expr);
  }


  function do_if(condition: Expr, body: Expr, else_body: Expr): Expr {
    var condition = expr_to_value(condition);
  
    return switch condition {
      case VBool(true) if(body != null): 
        body;

      case VBool(false) if(else_body != null): 
        else_body;

      case _: throw "a non-bool condition, this should be caught at one point in the parser right..? or something i dunno";
    };
  }

  inline function read_identifier(expr: Expr) {
    return switch expr.expr {
      case EIdentifier(name): name;

      case _: null;
    };
  }

  // reads stuff like obj.field1.field2.field3 into an array
  // we should maybe keep .pos ?
  inline function read_fields(field: Expr) {
    var fields: Array<Expr> = new Array(); 

    var accessor: Expr = field;
    while(accessor != null) {
      switch accessor.expr {
        case EField(var object, field):
          fields.push(object);

          trace(field);
          accessor = field;

        case _:
          fields.push(accessor);
          // throw 'unknown field accessor $accessor';
          break;
      };
    }

    return fields;
  }

  // function call_function(
  //   func: Function, 
  //   func_arguments: Array<FunctionArgument>, 
  //   return_type: Value, 
  //   call_arguments: Array<Expr>
  // ): Value {
  //   var parsed_arguments = parse_arguments(call_arguments, func_arguments);
  //   final arguments: Array<Dynamic> = new Array();

  //   for(parsed in parsed_arguments) {
  //     final native = value_to_haxe(parsed); 
  //     arguments.push(native);
  //   }
  //   // var locale = Value.to_haxe(arguments[1]);
  //   trace(func_arguments, arguments);

  //   final return_value: Dynamic = Reflect.callMethod(this, func, arguments);

  //   // todo: haxe_to_value
  //   return haxe_to_value(return_value);
  //   // return { 
  //   //   type: return_type,
  //   //   value: return_value 
  //   //   // value: translations.get(object.value, data, cast locale)
  //   // }; 
  // }

  function object_to_struct(object: ObjectType): DynamicAccess<Dynamic> {
    var struct: DynamicAccess<Dynamic> = {};

    for(key => value in object) {
      final value: Dynamic = switch value {
        case map if(map is haxe.ds.StringMap):
          object_to_struct(object);

        case v: v;
      }

      struct.set(key, value);
    }

    return struct;
  }
  
  // hi js i hate you
  #if js @:nullSafety(Off) #end
  function __Type_getClass<T>(o:T):Class<T>
    return Type.getClass(o);

  function get_field(access: Value, field: Expr): Value { 
    return switch access {
      case VString(string):
        // how do we separate this..
        // dude i hate my life
        // maybe into std? SOMEWHERE ELSE
        // but without weird hacky bullshit where u have to pass interp (this), so prob all in this class?
        //!!!! add a way to extend a Value's functions tho, this might make it 100x better to implement this

        switch field.expr {
          case ECall(callee, arguments):
            // turn into func, std func idk
            switch callee.expr {
              case EIdentifier(name): switch name {
                case "translate", "trans": 
                  var object_expr = arguments[0];
                  var object = expr_to_haxe(object_expr);

                  var t_global = globals.get("Translation"); 
                  if(t_global == null) throw "bwo";

                  var translation = value_to_haxe(t_global);

                  var translated = translation.get(string, object_to_struct(object));
                  
                  VString(translated);                  
                case _: throw "such string methods are yet not implemented (this is a WIP error)";
              }

              case _: throw "can't access such a field on a string (this is a WIP error)";
            } 
          case _:  throw "this field access is not supported on strings";
        }
        
      // partially implemented
      case VNativeClass(c):
        switch field.expr {
          case ECall(callee, arguments):
            var field: Dynamic = null;
            
            var class_type: Class<Any> = __Type_getClass(c);

            var fields = Type.getInstanceFields(class_type) ?? Type.getClassFields(class_type) ?? Reflect.fields(c);
            for(field_name in fields) {
              switch callee.expr {
                case EIdentifier(name):
                  if(field_name == name) {
                    field = Reflect.field(c, field_name);
                    break;  
                  } else continue;

                case _: 
                  throw 'what r u even doing ${callee.expr}';
              }
            }

            var value = if(field == null) null else Reflect.callMethod(c, field, [for(a in arguments) expr_to_haxe(a)]);
            return VUnknown(value);
          case _: throw "this field access is not supported on native classes";
        }

      // dunno if this works
      case VObject(map):
        var field = field;
        var value = access;
        
        while(field != null) {
          var current_field: Null<ExprDef> = null;

          while(current_field == null) {
            switch field.expr {
              case EField(var object, next_field): 
                current_field = object.expr;

                field = next_field;

              case _: current_field = field.expr;
            };
          }

          var key = switch current_field {
            case EString(string, SKQuote): string;
            case EIdentifier(name): name;
            
            case _: throw "cunt";
          }

          switch value {
            case VObject(map):
              var v = map.get(key);
              if(v != null) 
                value = v;
            case _:
              break;
          }
        }

        value;

      // case VObject(map):
      //   var fields = read_fields(field);
        
      //   var i = 0;
      //   var field_value: Value = null;
        
      //   var object: Expr = cast object;
      //   while(object != null) {
      //     var key = object[i].key;
      //     var value = object[i].value;
      //     if(fields.length <= 1) {
      //       field_value = value;
      //       object = null;
      //       break;
      //     }

      //     i++;
      //     var first = fields[0];
      //     // fields.shift();
      //     switch first {
      //       case EIdentifier(name) if(key == name):
      //         object = value.value;
      //         i = 0;
      //         fields.shift();

      //       case _: 
      //         break; // how do eror handle..
      //     }
      //   }
      //   field_value;

      case VNull:
        throw "can't access on null";

      case _:
        throw template_error('accessing a field like this isn\'t supported/implemented. (field `${field.expr}` on access `$access`)', field.pos);
    }
  }

  inline function check_arguments(call_arguments: Array<Expr>, func_arguments: Array<FunctionArgument>) {
    final arguments: Array<Value> = new Array();
            
    for(i => func_argument in func_arguments) {
      final call_argument = call_arguments[i];
      if(call_argument == null) break;

      // todo: make a Type class for checking types and stuff
      final is_unknown = func_argument.type == "Unknown";
      final is_matching_type = true; // func_argument.type == call_argument;
      final is_optional = func_argument.type == "?";

      trace(is_unknown, is_optional, is_matching_type);
      if(is_unknown || (is_optional || is_matching_type)) {
      } else {
        throw 'incorrect type for argument `${func_argument.name}` (have: ${call_argument}, want: ${func_argument.type})';
      }
    }

    return arguments;
  }

  function call_function(callee: Value, arguments: Array<Expr>): Value {
    return switch callee {
      case VFunction(func):
        var params = func.params ?? [];
        check_arguments(arguments, params);

        // todo: lambda or function for VFunction so we know the diff
        var block = switch func.body.expr {
          case EBlock(exprs, mode): 
            for(i => a in arguments)
              exprs.unshift({
                pos: a.pos,
                expr: EVar(params[i].name, a)
              });

            EBlock(exprs, mode);
          case _:
            var exprs = [func.body];

            for(i => a in arguments)
              exprs.unshift({
                pos: a.pos,
                expr: EVar(params[i].name, a)
              });
            
            EBlock(exprs, MImplicitLast);
        }

        expr_to_value({
          pos: func.body.pos,
          expr: block
        });

        // try {
        //   final value: Value = 

        //   value;
        // } catch(e) {
        //   throw 'could not call function `${func.name}` for reason: $e';
        // }

        // args need to be parsed to a haxe value ig? slow, lets just try to make hte function accept Value
        // final value: Value = Reflect.callMethod(func, func.body, arguments);
        
      // should error?
      case _: VNull;
    } 
  }


  inline function expr_to_haxe(value: Expr): Dynamic {
    return value_to_haxe(expr_to_value(value));
  }

  // todo: put in a helper or smth
  function haxe_to_value(value: Dynamic): Value {
    return switch value {
      case null: VNull;
      case n if(n is Int || n is Float): VNumber(n);
      case s if(s is String): VString(s);
      case b if(b is Bool): VBool(b);
      case a if(a is Array): VArray([
        for(i in (a : Array<Dynamic>)) haxe_to_value(a)
      ]);
      case m if(m is haxe.ds.StringMap): VObject([
        for(key => value in (m : ObjectType))
          key => value_to_haxe(value)
      ]);

      case c if(Reflect.isObject(c) && __Type_getClass(c) != null):
        VNativeClass(c);
      
      // todo: native function
      case f if(Reflect.isFunction(f)):
        VFunction({
          name: "<native>",
          params: [],
          body: f
        });

      case _: VUnknown(value);
    }
  }

  function value_to_haxe(value: Value): Dynamic {
    return switch value {
      case VNull: null;
      case VNumber(v): v;
      case VString(v): v;
      case VBool(v): v;
      case VArray(array): [
        for(i in array) value_to_haxe(i)
      ];
      case VObject(map): [
        for(key => value in map)
          key => value_to_haxe(value)
      ];
      case VUnknown(v): v;
      case VOptional(v): value_to_haxe(v);

      case VFunction(func): 
        func.body;

      case VNativeClass(c): c;

      case VEmpty: "";

      case _: throw "not possible";
    }
  }

  function expr_to_value(expr: Expr): Value {
    return switch expr.expr {
      case ENull: VNull;
      case EBool(bool): VBool(bool);
      case ENumber(number): VNumber(number);
      case EString(string, kind): switch kind {
        case SKRaw:
          VString(string);
        case SKQuote:
          VString(string); // todo: sanitize with xss thing
      }
      case EArray(array): VArray([
        for(i in array) expr_to_value(i)
      ]);
      case EObject(map): VObject([
        for(key => expr in map) {
          var value = expr_to_value(expr);

          key => value;
        }
      ]);
      case EField(var object, field): 
        var object = expr_to_value(object);
        var value = get_field(cast object, field);

        value;


      case ELambda(arguments, body): final id = "<lambda 0>"; VFunction({
        name: id,
        params: arguments,
        body: body
        // {
        //   var stack = new Stack(id);

        //   trace(arguments);
        //   for(i => arg_type in arguments)
        //     stack.memory.set(arg_type.name, args[i]);

        //   stack;
        // }
      });

      case ECall(expr_to_value(_) => callee, arguments):
        call_function(callee, arguments);

      //todo: classes
      case EIdentifier(name):
        var from_stack = stacks.get(name); 
        var from_global = globals.get(name);
          
        if(from_stack != null)
          expr_to_value(from_stack);
        else if(from_global != null) 
          from_global
        else
          throw 'unknown variable `$name`';

      case ERange(min, max): VArray([
        for(i in min...max) VNumber(i)
      ]);
      
      // also is postfix
      case EAssign(target, value): VNull; // todo

      case EVar(name, expr):
        var stack = stacks.first();
        if(stack != null)
          stack.memory.set(name, expr);

        VEmpty; // todo: VVoid;

      // please excuse the horribleness
      case EFor(items, item_name, body):
        var body_exprs = new Array<Expr>();

        var block_exprs = body.expr.extract(EBlock(exprs, _) => exprs) ?? throw "can't extract body exprs";
        var block_mode = body.expr.extract(EBlock(_, mode) => mode) ?? throw "can't extract body mode";
        
        while(true) switch items.expr {
          case ERange(min, max):
            for(i in min...max) {
              var local_block_exprs = block_exprs.copy();

              local_block_exprs.unshift({
                pos: items.pos,
                expr: EVar(item_name, { 
                  pos: items.pos,
                  expr: ENumber(i)
                })
              });

              body_exprs.push({
                pos: body.pos,
                expr: EBlock(local_block_exprs, block_mode)
              });
            }

            break;

          case EIdentifier(name):
            var expr = stacks.get(name);

            if(expr == null)
              throw "err";

            items = expr;

          case _: throw 'cant $items';
        };

        var body = {
          pos: items.pos,
          expr: EBlock(body_exprs, block_mode)
        };

        expr_to_value(body);


      case EIf(condition, body, else_body):
        var body = do_if(condition, body, else_body); 
        expr_to_value(body);

      case ESwitch(pattern, cases):
        var body = parse_switch(pattern, cases);

        // the options are the issue, we should eliminate this me thinks
        // {#if} and {#var name = if}, we return the body always
        // but im seeing {#keyword} as non outputtable, i shouldn't see it that way.
        if(body != null) expr_to_value(body) else VNull;

      // not sure if `identifier` and `value` are named right? shouldn't it be c1 and c2?
      case EBinary(var identifier, op, value):  // even more todo!
        parse_binary_operation(identifier, op, value);

      // todo:
      case EMeta(name, expr):
        trace(name, expr);
        expr_to_value(expr);

      // case EOutput(outs):
      //   var output = [
      //     for(out in outs) {
      //       var value = expr_to_haxe(out);

      //       value;
      //     }
      //   ].join("");

      //   VString(output);

      case EBlock(exprs, mode):
        switch mode {        
          case MConcat:
            var concat: Array<String> = [];
            for(expr in exprs) {
              var val = '${expr_to_haxe(expr)}';
              
              concat.push(val);
            }

            VString(concat.join(""));

          case MImplicitLast:
            var ret = VNull;
            for(expr in exprs) {
              var value = expr_to_value(expr);
              
              ret = value;
            }
            ret;
            
          case MReturnOnly:
            throw "erm";
        }

      case _: throw 'unknown expression `$expr` cannot be converted to a value';
    }
  }
  function parse_binary_operation(identifier: Expr, op: Operator, value: Expr) {
    switch op {
      case ONot:
        var e1 = expr_to_value(value);

        return e1.extract(VBool(v) => VBool(!v)) ?? e1;

      case OPow:
        var e1 = expr_to_value(identifier);
        var e2 = expr_to_value(value);

        var c1 = e1.extract(VNumber(n) => n) ?? throw "not a number";
        var c2 = e2.extract(VNumber(n) => n) ?? throw "not a number";

        var res = Math.pow(c1, c2);

        return VNumber(res);

      case OEqual:
        var c1 = expr_to_value(identifier);
        var c2 = expr_to_value(value);

        // ehh?
        return VBool(c1.equals(c2));

      case OAdd:
        var c1 = expr_to_value(identifier);
        var c2 = expr_to_value(value);

        // we assume by the first comparator
        switch c1 {
          // string concat
          case VString(v):
            // questionable
            return VString(v + c2.getParameters()[0]);

          case VNumber(v):
            // questionable 2
            return VNumber(v + c2.getParameters()[0]);

          case _:
            throw 'can\'t do add operation on $c1';
        }

      case _:
        throw 'invalid binary operator `$op`';
    }
  }

  // function expr_to_value(expr: Null<Expr>): Value {
  //   return switch expr {
  //     case ENull: { type: VNull, value: null };
  //     case EBool(bool): { type: VBool, value: bool };
  //     case EString(string): new TemString(VString, string);
  //     case ENumber(number): { type: VNumber, value: number };
  //     case EArray(array): { type: VArray(VUnknown), value: array.map((i) -> parse_expr(i)) };

  //     case ELambda(arguments, body):
  //       // { type: VFunction(parse_expr(arguments), VUnknown), value: () -> execute(body) };
  //       // todo: add types
  //       { type: VFunction(arguments, VUnknown), value: (args: Array<Dynamic>) -> execute(body) };

  //     case EObject(array): { type: VObject, value: array.map((o) -> { 
  //       key: switch o.key {
  //         case EString(string): string;
  //         case EIdentifier(name): name;
  //         case _: throw "nope";
  //       }, 
  //       value: parse_expr(o.value) 
  //     }) };

  //     case ERange(min, max): 
  //       { type: VArray(VNumber), value: [for(i in min...max) i] };
      
  //     case EIdentifier(name):
  //       var entry = stack.get(name);
  //       entry;
      
  //     // make this a function
  //     case ECall(parse_expr(_) => callee, call_arguments):
  //       call_function(callee, call_arguments);
      
  //     // src/core/Interpreter.hx:192: 
  //     //  [{key: waa, value: {type: VObject, value: [{key: wee, value: {type: <...>, value: <...>}}]}}],
  //     //  EField(EIdentifier(waa),EIdentifier(wee))

  //     // obj.a[0] ????????
  //     // implement sillly object field accessing by 
  //     //  1. first reading the field enums and placing it into a stack
  //     //     we will recursively read the enums till the last enums possible (an identifier), 
  //     //     then place that into a stack, 
  //     //  2. from there onwards we will back track to the caller, 
  //     //     where we place the object ( EField(object, field) ) into the stack aswell. 
  //     //     now we can loop our object array (the first layer) and check the top stack for the key, 
  //     //     then slowly remove the top stack bits as we go through the nested arrays. 
  //     //     then once we emptied the stack, we return the object. simple, right?
  //     case EField(var object, field): 
  //       var object = parse_expr(object);
  //       var value = get_field(cast object, field);

  //       value;

  //     // case EIndex(object, index): 

  //     case EBinary(var identifier, op, value):  // even more todo!
  //       switch op {
  //         case OEqual:
  //           var c1 = parse_expr(identifier).value;
  //           var c2 = parse_expr(value).value;

  //           return { type: VBool, value: c1 == c2 };
          
  //         case _: 
  //           throw 'invalid operator `$op` for comparing';
  //       }

  //     // for postfix shit liek ++
  //     case EAssign(target, value): { type: VNull, value: null }; // todo

      

  //     // case value:
  //     //   value;

  //     case _:
  //       throw 'unknown expression `$expr`';
  //   }
  // }

  inline function template_error(error: String, pos: Position) {
    var script_name = "unknown.tem";
    return '$script_name:${pos.line}:${pos.column}: $error';
  }
}