package core;

import core.Tokens.Keyword;
import core.AST;
import core.Tokens.Token;
import core.Tokens.Operator;
import core.Tokens.TokenPos;

class Parser {
  var tokens: Array<TokenPos>;

  public function new(tokens: Array<TokenPos>) {
    this.tokens = tokens;
  }

  var pos: Int = 0;

  public function parse() {
    while(!is_eof()) {
      parse_statement();
    }
  }

  function parse_statement(): Dynamic {
    var token: TokenPos = peek();

    return switch token.token {
      case TKeyword(KIf):
        parse_if();
      
      case TKeyword(KFor):
        parse_for();
      
      case TKeyword(KVar), TKeyword(KFinal): 
        parse_variable();

      case TOut(TString(string)):
        advance();
        SOutput(string);

      case _: 
        SExpr(parse_expression());
    }
  } 

  // todo: add Block, if, for parsing
  // then interpretter time!!!!!


  function parse_variable(): Statement {
    var typeof = advance();

    var identifier = expect_identifier();

    expect(TOperator(OAssign), "no assign");
    
    var expr = parse_expression();

    trace('var $identifier = $expr');

    return SVar(identifier, expr);
  }

  function parse_if() {
    advance();

		var condition = parse_expression();

    var then_body = parse_block();

    var else_body = switch(peek().token) {
      case TKeyword(KElse):
        advance();

        if(check(TKeyword(KIf))) 
          [parse_if()];
        else
          parse_block();

      case _:
        parse_block();
    }

    advance();

    trace('if $condition { $then_body } else { $else_body }');
    return SIf(condition, then_body, else_body);
  }

  function parse_for() {
    advance();

    var item = parse_identifier();

    var token = peek();
    switch(token.token) {
      case TKeyword(KIn):
        advance();

        var items = parse_expression();
        var body = parse_block();

        advance();

        trace('for $item in $items {$body}');
        return SFor(items, item, body);
      
      case _:
        throw template_error('invalid operator ${token.token} (expected TKeyword(KIn))', token);
    }
  }

  function parse_identifier() {
    var token = peek();

    switch token.token {
      case TIdentifier(name):
        advance();

        return name;

      case _:
        throw template_error('not an TIdentifier (got $token)', token);
    }
  }

  function parse_block() {
    var statements: Array<Statement> = new Array();

    switch peek().token {
      case TLeftBrace: 
        advance();
        
        while(true) {
          if(!check(TRightBracket)) advance(); break;

          statements.push(parse_statement());
        }

      case _: 
        while(true) {
          switch peek().token {
            case TKeyword(KEnd(_)), TKeyword(KElse):
              break;

            case _: statements.push(parse_statement());
          }
        }
    }

    return statements;
  }


  function parse_expression(): Expr {
    var expr = parse_comparisons();

    return expr;
  }
  
  function parse_expression_arguments() {
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

  function parse_comparisons() {
    var left = parse_expression_postfix();

    while(true) {
      var token = peek();

      var op = switch token.token {
        case TOperator(OEqual): OEqual;
        case TOperator(ONotEqual): ONotEqual;

        case _: break;
      }
      advance();

			var right = parse_expression_postfix();

			left = EBinary(left, op, right);
    }

    return left;
  }

  //todo: actualy make it work + function call and member access/index, etc
  function parse_expression_postfix(): Expr {
    var expr = parse_expression_primatives();
    var looping = true;

    while(looping) {
      var token = peek();

      switch token.token {
        case TLeftParentheses:
          advance();
          var arguments = parse_expression_arguments();
          expect(TRightParentheses, "unclosed parentheses");

          return ECall(expr, arguments);

        case TDot:
          var fields: Array<String> = new Array();

          do {
            advance(); // skip dot

            var token = peek();

            advance();
            switch token.token {
              case TIdentifier(name):
                fields.push(name);

              case TDot:
                continue;

              case _token:
                throw template_error('invalid token `$_token` for object field accessing', token);
            }
          } while(check(TDot));

          return EField(expr, fields);

        case TOperator(OIncrement):
          advance();
          return EAssign(expr, EBinary(expr, OAdd, ENumber(1)));

        case TOperator(ODecrement):
          return EAssign(expr, EBinary(expr, OSubtract, ENumber(1)));

        default:
          looping = false;

          break;
      }
    }

    return expr;
  }

  function parse_expression_primatives(): Expr {
    var token = peek();

    return switch token.token {
      case TString(string):
        advance();
        EString(string);

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

      case TLeftBracket:
        advance();

        var array = parse_array();

        EArray(array); 

      case TLeftBrace:
        advance();

        var obj = parse_object();

        EObject(obj); 

      case token: throw template_error('unparsed token `$token`');
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
		var obj: Array<{key:Expr, value:Expr}> = new Array();

		do {
			if(check(TComma))
				advance();
			if(check(TRightBrace))
				break;

			var key = parse_expression();

			advance(); // colon

			var expr = parse_expression();
			obj.push({
				key: key,
				value: expr
			});
		} while(check(TComma));

		advance();

    return obj;
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
    if(check(typeof)) {
      return advance();
    } else {
      throw this.template_error(error);
    }
  }

	inline function check(typeof: Token) {
    if(is_eof())
			return false;
	
    return Type.enumEq(peek().token, typeof);
	}

  inline function template_error(error: String, token: TokenPos = null) {
    if(token == null) token = peek();

    return '$error at ${token.line}:${token.column}';
  }

  inline function is_eof()
    return peek().token == TEoF;

  inline function peek()
    return tokens[pos];
    
  inline function advance()
    return tokens[pos++];
}