package core;

import core.Tokenizer.TagOperator;
import core.Tokens.Operator;
import core.AST;

using haxe.EnumTools;

class Printer {
  public function new() {
    
  }

  public function print_exprs(exprs: Array<Expr>, separator: String = "") {
    var parsed = [];
    
    for(expr in exprs) {
      parsed.push(print_expr(expr));
    }

    return parsed.join(separator);
  }

  inline function output_or_not(expr: Expr, output: String, other: String) 
    return switch expr.expr {
      case EString(_, SKRaw): output;
      case _: other;
    }
  
  inline function tag(type: TagOperator, content: String)
    return '{$type$content}';

  public function print_expr(expr: Expr) {
    return switch expr.expr {
      case ENull: "null";
      case EBool(bool): '$bool';
      case ENumber(number): '$number';
      case EString(string, kind): switch kind {
        case SKQuote: '"$string"';
        case SKRaw: '$string';
      }
      case ELambda(arguments, body): '(${[for(arg in arguments) '${arg.name}: ${arg.type}'].join(", ")}) -> ${print_expr(body)}';

      // case EOutput(outs): [
      //   for(out in outs)
      //     switch out.expr {
      //       case EString(string, SKRaw): string;
      //       case _: '{${print_expr(out)}}';
      //     }
      // ].join("");

      case EIdentifier(name): name;

      case EBinary(c1, op, c2):
        '${print_expr(c1)} ${parse_operator(op)} ${print_expr(c2)}';
      // postfix
      case EAssign(target, value):
        '${print_expr(target)} = ${print_expr(value)}';

      case EVar(name, value):
        output_or_not(
          value,

          tag(START, 'var $name') + '${print_expr(value)}' + tag(END, 'var'),
          tag(START, 'var $name = ${print_expr(value)}')
        );

      case EIf(condition, body, else_body):
        '{#if ${print_expr(condition)}}${print_expr(body)}{:else}${print_expr(else_body)}{/end}';


      case _: '<unknown ${expr.expr.getName()}>';
    }
  }

  public function parse_operator(op: Operator) {
    return switch op {
      case OAssign: '=';
      case OEqual: '==';
      case ONotEqual: '!=';
      case OLess: '<';
      case OGreater: '>';
      case OLessEqual: '<=';
      case OGreaterEqual: '>=';
      case OIncrement: '++';
      case ODecrement: '--';
      case OAdd: '+';
      case OSubtract: '-';
      case OMultiply: '*';
      case ODivide: '/';
      case OPow: '^';
      case OModulo: '%';
      case ONot: '!';
      case OAnd: '&&';
      case OOr: '||';
      case _: '<?>';
    }
  }
}