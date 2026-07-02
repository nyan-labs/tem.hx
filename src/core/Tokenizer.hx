package core;

import core.Tokens.Position;
import core.Tokens.Keyword;
import core.Tokens.keywords;
import core.Tokens.Token;
import core.Tokens.TokenPos;

using StringTools;

enum State {
  Output;
  
  Tag(op: TagOperator);
}

enum abstract TagOperator(String) to String {
  var OUTPUT = "";

  var META = "@";
  var START = "#";
  var INNER = ":";
  var END = "/";
}

typedef TokenizerConfig = {}; 

// heavily inspired from: https://github.com/Kitsumizy/NxScript/blob/main/src/nx/script/Tokenizer.hx
class Tokenizer {
  public var data: String;

  final LINE_ENDING = "\n";

  public function new(data: String, config: TokenizerConfig = null) {
    this.data = data;

    // windows line-endings
    this.data = this.data.replace("\r\n", LINE_ENDING);
    this.data = this.data.replace("\r", LINE_ENDING);
  }

  var col: Int = 0;
  var line: Int = 1;

  inline function position(): Position {
    return {
      name: "?",
      line: line,
      column: col
    }
  }

  var pos: Int = 0;

  var queue: Array<TokenPos> = new Array();

  public function tokenize() {
    var tokens: Array<TokenPos> = new Array();

    while(!is_eof()) {
      final start_pos = position();

      final token = next_token();
      if(token == null) {
        while(queue.length > 0) {
          var token = queue.shift();

          tokens.push(token);
        }

        continue;
      } else {
        tokens.push({
          token: token,
          pos: start_pos
        });
      }
    }

    tokens.push({
      token: TEoF, 
      pos: position()
    });

    return tokens;
  }

  var state: State = Output;

  function check_state() {
    // trace('state ($state) check; peek ${peek()}; ${peek_next()}');
    switch state {
      case Output:
        // switch case? somehow?
        if(is_tag(START, false)) {
          advance();
          advance();
          skip_whitespace();

          state = Tag(START);
        } else if(is_tag(META, false)) {
          advance();
          skip_whitespace();

          state = Tag(META);
        } else if(is_tag(INNER, false)) {
          advance();
          advance();
          skip_whitespace();

          state = Tag(INNER);
        } else if(is_tag(END, false)) {
          advance();
          advance();
          skip_whitespace();

          state = Tag(END);
        } else if(is_tag(OUTPUT, false)) {
          advance();
          skip_whitespace();

          state = Tag(OUTPUT);
        }


      case Tag(op):
        if(is_tag(op, true)) {
          advance();
          state = Output;
        }
    }

    return state;
  }

  
  function is_tag(op: TagOperator, check_end: Bool = false) {
    if(check_end)
      if(peek() == "}") {
        return true;
      }
  
    return peek() == "{" && (peek_next() == op || op == OUTPUT);
  }

  function parse_inner_tag() {
    trace(peek());
    if(peek() == '\n') {
      advance();

      line++;
      col = 0;

      return TNewline;
    }

    if(is_number(peek(), peek_next()))
      return read_number();

    if(is_string_quote(peek()))
      return read_string();

    if(is_identifier(peek())) {
      return read_identifiers();
    }

    return read_delimiters_and_operators();
  }

  function next_token(): Null<Token> {
    if(is_eof())
      return null;

    // trace("cursor ", pos, col, peek());

    switch check_state() {
      case Tag(META):
        var depth = 0;

        while(!is_eof()) {
          skip_whitespace();

          if(is_whitespace(peek()) || peek() == "#")
            break;

          var start_pos = position();
            
          var token = parse_inner_tag();
          switch token {
            case TLeftBrace: depth++;
            case TRightBrace: depth--;

            case _: null;
          }
          
          if(depth <= -1)
            break;
          
          queue.push({
            token: token, 
            pos: start_pos
          });
          
          if(is_eof()) break;
        }
        
        if(peek() == "#") {
          advance();
          state = Tag(START);
        } else
          state = Tag(OUTPUT);

        return null;

      case Tag(START), Tag(INNER):
        var depth = 0;

        while(!is_eof()) {
          skip_whitespace();

          var start_pos = position();

          // fiiiiiiiix
          // bracketss pair it upppp somehowww
          // if(peek() == "{" && peek() == find) {
          //   var token = parse_inner_tag();
          //   queue.push({token: token, line: start_line, column: start_column});

          //   aaa("}");
          // } else if(find == "}") {            
            // }
            
          var token = parse_inner_tag();
          switch token {
            case TLeftBrace: depth++;
            case TRightBrace: depth--;

            case _: null;
          }
          
          if(depth <= -1)
            break;
          
          queue.push({
            token: token, 
            pos: start_pos
          });
          
          if(is_eof()) break;
        }

        state = Output;

        return null;

      case Tag(END):
        if(is_identifier(peek())) {
          var content = "";

          skip_whitespace();

          while(!is_eof() && check_state().match(Tag(END))) {
            if(!is_identifier(peek())) {
              break;
            }

            content += peek();

            advance();
          }
          if(content.length == 0)
            return null;

          var keyword = keywords.get(content);
          if(keyword == null)
            throw 'invalid closing tag `$content`';

          return TKeyword(KEnd(keyword));
        } else {
          throw 'invalid closing tag';
        }

      case Tag(OUTPUT):
        var depth = 0;

        while(!is_eof()) {
          skip_whitespace();

          var start_pos = position();
          
          var token = parse_inner_tag();
          if(token == TLeftBrace)
            depth++;
          else if(token == TRightBrace)
            depth--;

          if(depth <= -1)
            break;

          queue.push({
            token: token, 
            pos: start_pos
          });
        }

        state = Output;

        return null;

      case Output:
        var output = "";

        while(!is_eof()) {
          if(peek() == "\n") {
            line++;
            col = 0;
          }
          //escape
          if(peek() == '\\') {
            advance();
          }

          output += peek();

          advance();
          
          if(!check_state().match(Output))
            break;
        }

        if(output.length > 0)
          return TString(output, SKRaw);
        else return null;

      case state:
        throw 'unparsed state `$state`';
    }

    return null;
  }

  inline function is_string_quote(c: String)
    return c == "\"" || c == "'" || c == "`";

  function read_string() {
    var str = "";
    var quote = peek();

    final start_line = line;
    final start_col = col;

    advance(); // starting quote

    while(!is_eof() && peek() != quote) {
      var c = peek();

      if(c == "\\") {
        var to_escape = advance();

        switch to_escape {
          case 'n':
            str += '\n';
          case 'r':
            str += '\r';
          case 't':
            str += '\t';

          case '\\':
            str += '\\';

          default:
            str += to_escape;
        }
      } else {
        if(peek() == '\n') {
          line++;
          col = 0;
        }

        str += c;

        advance();
      }
    }

    if(is_eof())
      throw 'unterminated string at $start_line:$start_col';

    advance(); // ending quote

    return TString(str, SKQuote);
  }

  inline function is_number(c: String, cn: String)
    return is_digit(c) || ["."].contains(c) && is_digit(cn);

  function read_number() {
    var number = "";

    final start_line = line;
    final start_col = col;

    while(!is_eof()) {
      var c = peek();
      var cn = peek_next();

      if(!is_number(c, cn)) {
        if(is_whitespace(c))
          break;
        else if(is_ascii(c))
          throw 'unknown character `$c` at $start_line:$start_col';
        else
          break;
      }

      number += c;
      advance();
    }

    return TNumber(Std.parseFloat(number));
  }

  inline function is_identifier(c: String)
    return is_alphanumeric(c) || ["_", "$"].contains(c);

  function read_identifiers(): Null<Token> {
    var content = "";

    skip_whitespace();

    while(!is_eof()) {
      if(!is_identifier(peek())) {
        break;
      }

      content += peek();

      advance();
    }
    // trace('aaa `$content`');
    if(content.length == 0)
      return null;

    var keyword = keywords.get(content);

    if(keyword != null)
      switch keyword {
        case KTrue:
          return TBool(true);
        case KFalse:
          return TBool(false);
        case KNull:
          return TNull;

        case _:
          return switch state {
            case Tag(INNER): TKeyword(KInner(keyword));
            case _: TKeyword(keyword);
          };
      }

    return TIdentifier(content);
  }

  // todo: do pairs for some delimiters (like {}), because else {#if {} == {}} wont work at all!! meow.
  function read_delimiters_and_operators() {
    var c = peek();
    advance();

    switch (c) {
      case ";":
        return TSemiColon;
      case "(":
        return TLeftParentheses;
      case ")":
        return TRightParentheses;
      case "[":
        return TLeftBracket;
      case "]":
        return TRightBracket;
      case "{":
        return TLeftBrace;
      case "}":
        return TRightBrace;

      case "-" if(peek() == ">"):
        advance();
        return TArrow;
      case "=" if(peek() == ">"):
        advance();
        return TMapArrow;


      case "@":
        return TAt;

      case ":":
        return TColon;
      case ",":
        return TComma;
      case "|":
        return TVerticalBar;
      case "." if(peek() == "." && peek_next() == "."):
        advance();
        advance();
        return TRange;
      case ".":
        return TDot;

      case "^":
        return TOperator(OPow);

      case "!":
        return TOperator(ONot);

      case "=" if(peek() == "="):
        advance();
        return TOperator(OEqual);

      case "=":
        return TOperator(OAssign);

      case "+" if(peek() == "+"):
        advance();
        return TOperator(OIncrement);

      case "+":
        return TOperator(OAdd);
      
      case "-" if(peek() == "-"):
        advance();
        return TOperator(ODecrement);
        
      case "-":
        return TOperator(OSubtract);

      case _:
        throw 'unknown character `$c` at $line:$col';
    }
  }

  function is_eof() {
    if(pos >= data.length)
      return true;

    return false;
  }

  inline function peek() {
    return peek_step(0);
  }

  inline function peek_next() {
    return peek_step(1);
  }

  inline function peek_step(step: Int) {
    var pos = pos + step;

    if(is_eof())
      return '';

    return data.charAt(pos);
  }

  function advance() {
    col++;
    pos++;

    return peek();
  }

  function is_whitespace(c: String)
    return [" ", "\t"].contains(c);

  function skip_whitespace() {
    while(!is_eof()) {
      if(is_whitespace(peek()))
        advance();
      else
        break;
    }
  }

  inline function is_digit(c: String)
    return c >= "0" && c <= "9";

  inline function is_ascii(c: String)
    return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z");

  inline function is_alphanumeric(c: String)
    return is_ascii(c) || is_digit(c);
}
