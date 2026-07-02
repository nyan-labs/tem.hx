package core;

import core.utils.ParseException.ParseError;
import haxe.Exception;
import haxe.PosInfos;
import haxe.exceptions.PosException;
import core.Tokens.Position;
import haxe.ds.Either;
import core.Tokens.Keyword;
import core.AST;
import core.Tokens.Token;
import core.Tokens.Operator;
import core.Tokens.TokenPos;

typedef ParserConfig = {};

// todo: throw multiple parser errs by having an array to push errs into

enum Result {
  Success(exprs: Array<Expr>);
  Error(exprs: Array<Expr>, errors: Array<ParseError>);
}

class Parser {
  var tokens: Array<TokenPos>;

  var errors: Array<ParseError>;
  function error(token: TokenPos, message: String, ?pos:Null<PosInfos>) {
    // should be a compiler cond
    trace('[PARSER_ERROR] ${token.token}', message);

    var error = new ParseError(token, message, null, pos);

    errors.push(error);
  }

  public function new(tokens: Array<TokenPos>, config: ParserConfig = null) {
    this.tokens = tokens;
    this.errors = new Array();
  }

  // change cuz i hate this name
  // like idk cursor?
  var pos: Int = 0;

  public function parse() {
    var exprs: Array<Expr> = new Array();
    while(!is_eof()) {
      var expr = parse_statement();

      // trace(expr);

      exprs.push(expr);
    }

    return if(errors.length == 0) Success(exprs) else Error(exprs, errors);
  }

  function parse_statement(): Expr {
    var token: TokenPos = peek();

    return {
      expr: switch token.token {
        // make this a function not inline
        case TKeyword(KImport):
          advance();
          
          var import_path = {
            var path = new Array<String>();
            
            var token = peek();
            while(!is_eof()) {
              switch token.token {
                case TDot: null;

                case TIdentifier(name):
                  path.push(name);

                case _: break;
              }

              advance();
              token = peek();
            }
            
            path.join(".");
          }
          EString('<import path="${import_path}">', SKRaw);

        // case TKeyword(KIf):
          // parse_if();

        case TKeyword(KFor):
          parse_for();

        case TKeyword(KVar), TKeyword(KFinal):
          parse_variable();

        // case TOutput(_):
        //   var out: Array<Expr> = new Array();

        //   var old_pos = pos;
        //   var max_pos = pos;

        //   var token = token;
        //   while(!is_eof()) {
        //     switch token.token {
        //       case TOutput(out_token):
        //         tokens[pos] = {
        //           token: out_token,
        //           pos: token.pos
        //         };
        //         advance();

        //       case _:
        //         max_pos = pos;
        //         break;
        //     }

        //     token = peek();
        //   };

        //   pos = old_pos;

        //   while(!is_eof() && pos < max_pos) {
        //     var expr = parse_statement();

        //     out.push(expr);
        //   };
        //   trace(out);

        //   EOutput(out);

        // case TString(string, SKRaw):
        //   advance();
          // EString(string, SKRaw);

        case TNewline: 
          trace("!!!", peek());
          advance();
          trace("!!!", peek());
          ENull;

        case TEoF:
          trace(is_eof());
          ENull;
          
        case _:
          parse_expression().expr;
      },
      pos: token.pos
    }
  }

  // todo: add Block, if, for parsing
  // then interpretter time!!!!!

  function parse_variable(): ExprDef {
    var typeof = advance();

    var identifier = expect_identifier();

    var token = peek();
    // should this be a helper?
    var expr = switch token.token {
      case TOperator(OAssign):
        advance();

        var expr = parse_expression();
        expr;
      case TString(content, SKRaw):
        var exprs = new Array<Expr>();

        while(!is_eof()) {
          if(peek().token.equals(TKeyword(KEnd(KVar))))
            break;

          var e = parse_expression();
          exprs.push(e);
        }

        expect(TKeyword(KEnd(KVar)), "missing ending tag");

        {
          pos: token.pos,
          expr: EBlock(exprs, MConcat)
        };
      case _: 
        error(token, "no assign");
        {
          pos: token.pos,
          expr: ENull
        };
    }
    

    trace('var $identifier = $expr');

    return EVar(identifier, expr);
  }

  function parse_if() {
    advance();

    expect(TLeftParentheses, "condition must be in parentheses");

		var condition = parse_expression();

    expect(TRightParentheses, "condition must be in parentheses");

    var then_body = parse_block_tag_end(MConcat);
    trace(peek());

    var token = peek();
    var else_body = switch token.token {
      case TKeyword(KInner(KElse)):
        advance();

        if(check(TKeyword(KIf))) {
          var if_pos = peek().pos;

          {
            pos: if_pos,
            expr: parse_if()
          };
        } else parse_block_tag_end(MConcat);
      case _:
        {
          pos: token.pos,
          expr: EBlock([], MConcat)
        };
    }

    expect(TKeyword(KEnd(KIf)), "missing ending if");

    trace('if $condition { $then_body } else { $else_body }');
    return EIf(condition, then_body, else_body);
  }

  function parse_for() {
    advance();

    expect(TLeftParentheses, "condition must be in parentheses");

    var item = parse_identifier();

    var token = peek();
    switch(token.token) {
      case TKeyword(KIn):
        advance();

        var items = parse_expression();

        expect(TRightParentheses, "condition must be in parentheses");

        var body = parse_block_tag_end(MConcat);

        expect(TKeyword(KEnd(KFor)), "missing ending for");

        trace('for $item in $items {$body}');
        return EFor(items, item, body);
      
      case _:
        advance();

        error(token, 'invalid operator ${token.token} (expected TKeyword(KIn))');
        return ENull;
    }
  }

  function parse_identifier() {
    var token = peek();

    switch token.token {
      case TIdentifier(name):
        advance();

        return name;

      case _:
        error(token, 'not an TIdentifier (got $token)');
        return "";
    }
  }

  function parse_block(?mode: BlockMode = MImplicitLast) {
    var exprs: Array<Expr> = new Array();

    var block_pos = peek().pos;

    switch peek().token {
      case TLeftBrace:
        while(!is_eof()) {
          switch peek().token {
            case TKeyword(KEnd(_)):
              break;
          
            case token:
              exprs.push(parse_statement());
          }
        }

      case token: 
        throw 'invalid block (got $token, expected TLeftBrace)';
    }

    return {
      pos: block_pos,
      expr: EBlock(exprs, mode)
    }
  }

  function parse_block_tag_end(?mode: BlockMode = MConcat) {
    var exprs: Array<Expr> = new Array();

    var block_pos = peek().pos;

    while(!is_eof()) {
      var token = peek();
      
      switch token.token {
        case TKeyword(KEnd(_)), TKeyword(KInner(_)):
          break;
          
        case token:
          exprs.push(parse_statement());
      }
    }

    return {
      pos: block_pos,
      expr: EBlock(exprs, mode)
    }
  }


  function parse_expression(): Expr {
    var token = peek();
    return switch token.token {
      // we don't want any prefix, comparisons or postfixes with this
      case TString(string, SKRaw):
        advance();
        {
          pos: token.pos,
          expr: EString(string, SKRaw)
        };

      case _: parse_expression_prefix();
    }
  }

  inline function parse_type(): String {
    var token = peek();
    advance();

    return switch token.token {
      case TIdentifier(name):
        return name;
        // return switch name {
        //   case "String": VString;
        //   case "Number": VNumber;
        //   case "Object": VObject;
        //   case "Null": VNull;
        //   case "Function": VFunction([], VUnknown); // todo with Function<args, return>
        //   case "Bool": VBool;
        //   case "Enum": VEnum(null);
          
        //   case _: VUnknown;
        // };

      case _:
        error(token, "not a type");
        return "";
    }
  }
  
  function parse_function_arguments() {
    var arguments: Array<FunctionArgument> = new Array();

    if(check(TRightParentheses))
      return arguments;
    
    do {
      if(check(TComma)) {
        advance();
      }
      
      var token = peek();
      var expr: String = switch token.token {
        case TIdentifier(name): name;
        
        case _: 
          error(token, 'invalid argument `${token.token}`');
          "";
      };
      advance();

      var type: String = null;
      
      if(check(TColon)) {
        advance();

        type = parse_type();
      }
      
      arguments.push({
        type: type,
        name: expr
      });
      
      if(check(TRightParentheses))
        break;
    } while(check(TComma));

    return arguments;
  }
  function parse_function_call_arguments() {
    var arguments: Array<Expr> = new Array();

    if(check(TRightParentheses))
      return arguments;

    do {
      if(check(TComma)) {
        advance();
      }
      
      var expr = parse_expression();
      arguments.push(expr);
      
      if(check(TRightParentheses))
        break;
    } while(check(TComma));

    return arguments;
  }

  function parse_expression_prefix() {
    var token = peek();
    var op = switch token.token {
      case TOperator(ONot): ONot;

      case _: null;
    }

    if(op != null) {
      advance();

      var expr = parse_expression();

      return { 
        pos: expr.pos, 
        expr: EBinary({
          pos: expr.pos, 
          expr: ENull 
        }, op, expr) 
      };
    } else return parse_expression_infix();
  }

  function parse_expression_infix() {
    var left = parse_expression_postfix();

    while(!is_eof()) {
      var token = peek();

      var op = switch token.token {
        case TOperator(OAdd): OAdd;
        case TOperator(OSubtract): OAdd;
        case TOperator(ODivide): ODivide;
        case TOperator(OMultiply): OMultiply;

        case TOperator(OEqual): OEqual;
        case TOperator(ONotEqual): ONotEqual;
        case TOperator(OLess): OLess;
        case TOperator(OLessEqual): OLessEqual;
        case TOperator(OGreater): OGreater;
        case TOperator(OGreaterEqual): OGreaterEqual;
        
        case TOperator(OPow): OPow;
        case TOperator(OModulo): OModulo;
        
        case TOperator(OAnd): OAnd;
        case TOperator(OOr): OOr;

        case _: break;
      }
      advance();

			var right = parse_expression_postfix();

			left = { expr: EBinary(left, op, right), pos: left.pos };
    }

    return left;
  }

  //todo: actualy make it work + function call and member access/index, etc
  function parse_expression_postfix(): Expr {
    var expr = parse_expression_primatives();

    while(!is_eof()) {
      var token = peek();

      switch token.token {
        case TLeftParentheses:
          advance();

          var arguments = parse_function_call_arguments();
          expect(TRightParentheses, "unclosed parentheses");

          return {
            expr: ECall(expr, arguments),
            pos: token.pos
          }

        case TDot:
          advance(); // skip dot

          var token = peek();

          switch token.token {
            case TDot:
              continue;

            case TIdentifier(_):
              return {
                expr: EField(expr, parse_expression()),
                pos: token.pos
              };

            case _:
              error(token, 'invalid token `${token.token}` for object field accessing');
              continue;
          }

        case TOperator(OIncrement):
          advance();
          return {
            expr: EAssign(expr, {
              expr: EBinary(expr, OAdd, { expr: ENumber(1), pos: token.pos }),
              pos: token.pos
            }),
            pos: token.pos
          }

        case TOperator(ODecrement):
          advance();
          return {
            expr: EAssign(expr, {
              expr: EBinary(expr, OSubtract, { expr: ENumber(1), pos: token.pos }),
              pos: token.pos
            }),
            pos: token.pos
          }

        default:
          break;
      }
    }

    return expr;
  }

  function parse_expression_primatives(): Expr {
    var token = peek();

    return {
      expr: switch token.token {
        case TString(string, kind):
          advance();
          EString(string, kind);

        case TBool(bool):
          advance();
          EBool(bool);

        case TNull:
          advance();
          ENull;

        case TNumber(number):
          advance();
          if(peek().token == TRange) {
            advance();

            var token = peek();
            advance();

            var max: Float = Type.enumParameters(token.token)[0];

            ERange(Std.int(number), Std.int(max));
          } else ENumber(number);

        case TIdentifier(name):
          advance();
          EIdentifier(name);

        case TRightParentheses: null;

        case TLeftParentheses:
          advance();

          var is_lambda = false;
          var old_pos = pos;

          parse_function_arguments();

          if(check(TRightParentheses)) {
            advance();

            if(check(TArrow))
              is_lambda = true;
            else
              is_lambda = false;
          } else
            is_lambda = false;

          pos = old_pos;
          if(!is_lambda) {
            var expr = parse_expression();
            expect(TRightParentheses, "unclosed parentheses");
            expr;
          }

          var arguments = parse_function_arguments();

          expect(TRightParentheses, "unclosed parentheses");

          expect(TArrow, "expected an arrow for lambda");

          if(check(TLeftBrace)) {
            var body = parse_block();

            ELambda(arguments, body);
          } else {
            var expr = parse_expression();

            ELambda(arguments, expr);
          }

        case TKeyword(KIf):
          parse_if();

        case TKeyword(KSwitch):
          advance();
          var cases = new Array<SwitchCase>();

          var switch_pattern = parse_expression();

          // throw '${tokens.slice(0, pos+5)}';

          while(!is_eof()) {
            var token = peek();
            switch token.token {
              case TKeyword(KEnd(KSwitch)):
                advance();
                break;
              
              case TKeyword(KInner(KCase)):
                advance(); 
              
                
                var body = new Array<Expr>();
                var pattern_token = peek();
                var pattern = parse_expression(); // we need to get the variable from an enum or like purely the variable idk idkd ikd 

                switch pattern.expr {
                  case EIdentifier(name) if(is_name_class_or_enum(name)):
                    error(pattern_token, 'we dont support enums yet (never will for classes) ${pattern.expr}');

                  case EIdentifier(name):
                    body.push({
                      pos: pattern.pos,
                      expr: EVar(name, switch_pattern)
                    });

                  case _:
                    null;
                }
                
                var body_pos: Position = null;

                // todo: add if and stuff support {:case Stinky(text) if(text == "orbl")}

                // todo: use parse_block_end_tag()
                while(!is_eof()) {
                  if(check(TKeyword(KInner(KCase))) || check(TKeyword(KEnd(KSwitch)))) break;
                  
                  var expr = parse_statement();
                  if(body_pos == null)
                    body_pos = expr.pos;

                  body.push(expr);
                }

                cases.push({
                  pattern: pattern,
                  body: {
                    pos: body_pos ?? pattern.pos,
                    expr: EBlock(body, MConcat)
                  }
                });

              // there should be a helper func for this i swear
              case TString(string, SKRaw):
                advance(); 
                // whitespace, we skip :3

              case _: 
                error(token, 'only cases are allowed in switch');
                break;
            }
          }

          ESwitch(switch_pattern, cases);



        case TLeftBracket:
          advance();

          var array = parse_array();

          EArray(array);

        case TLeftBrace:
          advance();

          var obj = parse_object();

          EObject(obj);

        case TAt:
          advance();
          var name = parse_identifier();

          EMeta(name, parse_statement());

        case _: 
          advance();
          error(token, 'unparsed token `${token.token}`');
          ENull;
      },
      pos: token.pos
    }
  }

	function parse_array() {
		var array: Array<Expr> = new Array();

		do {
			if(check(TComma))
				advance();
			if(check(TRightBracket))
				break;

			var expr = parse_expression();
			array.push(expr);
		} while(check(TComma));

		advance();
    
    return array;
	}

	function parse_object() {
		var obj: Map<String, Expr> = new Map();

		do {
			if(check(TComma))
				advance();
			if(check(TRightBrace))
				break;

      var token = peek(); // wrong !
			var key = switch parse_expression().expr {
        case EString(string, SKQuote): string;
        case EIdentifier(name): name;
        case key: 
          error(token, 'invalid key $key for object');
          "";
      }

			advance(); // colon

			var expr = parse_expression();
			obj.set(key, expr);
		} while(check(TComma));

		advance();

    return obj;
	}

  function is_name_class_or_enum(name: String) {
    var first_char = name.charAt(0);
    if(
      first_char.toUpperCase() == first_char && 
      first_char.toLowerCase() != first_char
    )
      return true;
    
    return false;
  }

  function is_identifier() {
    var token = peek();
    return switch token.token {
      case TIdentifier(name): true;
      case _: false;
    }
  }

  function expect_identifier() {
    var token = peek();
    return switch token.token {
      case TIdentifier(name):
        advance();
        name;
      case _:
        this.template_error('expected an identifier');
    }
  }


  inline function expect(typeof: Token, error: String) {
    if(!check(typeof)) {
      this.error(peek(), error);
    }
    return advance();
  }

	inline function check(typeof: Token) {
    if(is_eof())
			return false;
	
    return Type.enumEq(peek().token, typeof);
	}

  inline function template_error(error: String, token: TokenPos = null) {
    if(token == null) token = peek();

    return '$error at ${token.pos.line}:${token.pos.column}';
  }

  inline function is_eof()
    return peek().token == TEoF;

  inline function peek()
    return tokens[pos];

  inline function advance()
    return tokens[pos++];
}