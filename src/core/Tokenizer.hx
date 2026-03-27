package core;

import core.Tokens.Keyword;
import core.Tokens.keywords;
import core.Tokens.Token;
import core.Tokens.TokenPos;

using StringTools;

enum State {
  SNone;
  SStartTag;
  SEndTag;
}

// heavily inspired from: https://github.com/Kitsumizy/NxScript/blob/main/src/nx/script/Tokenizer.hx
class Tokenizer {
  public var data: String;

  final LINE_ENDING = "\n";

  public function new(data: String) {
    this.data = data;

    // windows line-endings
    this.data = this.data.replace("\r\n", LINE_ENDING);
    this.data = this.data.replace("\r", LINE_ENDING);
  }

  var col: Int = 0;
  var line: Int = 1;

  var pos: Int = 0;

  var queue: Array<TokenPos> = new Array();

  public function tokenize() {
    var tokens: Array<TokenPos> = new Array();

    while(!is_eof()) {
      final start_line = line;
      final start_column = col;

      final token = next_token();
      if(token == null) {
        while(queue.length > 0) {
          var token = queue.shift();

          tokens.push(token);
        }

        continue;
      } else {
        tokens.push({token: token, line: start_line, column: start_column});
      }
    }

    tokens.push({token: TEoF, line: line, column: col});

    return tokens;
  }

  var state: State = SNone;

  function check_state() {
    trace('state ($state) check peek ${peek()}; ${peek_next()}');
    switch state {
      case SNone:
        if(is_starting_tag(false)) {
          advance();
          advance();
          skip_whitespace();

          state = SStartTag;
        }
        else if(is_ending_tag(false)) {
          trace("END");
          advance();
          advance();
          skip_whitespace();

          state = SEndTag;
        }

      case SStartTag:
        if(is_starting_tag(true)) {
          advance();
          state = SNone;
        }

      case SEndTag:
        if(is_ending_tag(true)) {
          advance();
          state = SNone;
        }
    }

    return state;
  }

  // {#tag {}}; {:tag}; {/tag}
  function is_starting_tag(check_end: Bool = false) {
    if(check_end)
      if(peek() == "}") {
        return true;
      }

    // todo
    return peek() == "{" && (peek_next() == "#" || peek_next() == "@");
  }

  function is_ending_tag(check_end: Bool = false) {
    if(check_end)
      return peek() == "}";

    // todo
    return peek() == "{" && peek_next() == "/";
  }

  // {{ delimiter }} (TOOOOODOOOOOOOOOOOOOOOOOOOOOOO)
  function is_delimiter_output(check_end: Bool = false) {
    // %}
    if(check_end)
      return peek() == "}" && peek_next() == "}";

    // {%
    return peek() == "{" && peek_next() == "{";
  }

  function parse_inner_tag() {
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

    skip_whitespace();

    switch check_state() {
      case SStartTag:
        // ugly but it works
        var end_i = 0; // }
        var start_i = 0; // {

        do {
          skip_whitespace();

          var start_line = line;
          var start_column = col;

          var token = parse_inner_tag();

          // this exists for edge cases like {#var obj = {}},
          // where the first right brace ends up ending the tag
          if(token == TLeftBrace) {
            start_i++;
          } else if(token == TRightBrace) {
            end_i++;

            if(!(start_i >= end_i))
              break;
          }

          queue.push({token: token, line: start_line, column: start_column});
        }while(start_i >= end_i);

        state = SNone;

        return null;

      case SEndTag:
        if(is_identifier(peek())) {
          var content = "";

          skip_whitespace();

          while(!is_eof() && check_state().match(SEndTag)) {
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
            throw "invalid closing tag";

          return TKeyword(KEnd(keyword));
        } else {
          throw "invalid closing tag";
        }

      case SNone:
        var output = "";
        while(check_state().match(SNone) && !is_eof()) {
          if(peek() == "\n") {
            line++;
            col = 0;
          }

          output += peek();

          advance();
        }

        if(output.length > 0)
          return TOut(TString(output));
        else
          return null;

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

    return TString(str);
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
    return is_alphanumeric(c) || ["_", "$", "@"].contains(c);

  function read_identifiers(): Null<Token> {
    var content = "";

    skip_whitespace();

    while(!is_eof() && !is_starting_tag(true)) {
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
          return TKeyword(keyword);
      }

    return TIdentifier(content);
  }

  // todo: do pairs for some delimiters (like {}), because else {#if {} == {}} wont work at all!! meow.
  function read_delimiters_and_operators() {
    var c = peek();
    advance();

    switch (c) {
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

      case ":":
        return TColon;
      case ",":
        return TComma;
      case ".":
        if(peek() == ".") {
          advance();
          return TRange;
        }
        return TDot;

      case "=":
        // ==
        if(peek() == "=") {
          advance();
          return TOperator(OEqual);
        }

        return TOperator(OAssign);

      case "+":
        if(peek() == "+") {
          advance();
          return TOperator(OIncrement);
        }
        return TOperator(OAdd);
      case "-":
        if(peek() == "-") {
          advance();
          return TOperator(ODecrement);
        }
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
    trace("am i getting called too many times?");
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
