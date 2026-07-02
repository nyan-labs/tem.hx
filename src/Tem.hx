package;

import haxe.Exception;
import haxe.macro.Compiler;
import haxe.io.Bytes;
import core.Printer;
import core.runtime.std.Translation;
import core.runtime.std.Translation.Locale;
import haxe.Timer;
import core.Tokenizer;
import core.Interpreter;
import core.Parser;

typedef TemConfig = {
  var ?tokenizer: TokenizerConfig;
  var ?parser: ParserConfig;
  var ?interp: InterpreterConfig;
}

class Tem {
  // TODO!! TESTSs!!!! PLEASE

  // use MConcat on IFs or any {#keyword}HERE {"SHIT"} GOES{/keyword} tag, for like {#meow = { var meow = "a"; meow; }}, we do MImplicitLast
  // idk u figure it out 

  // ok now do binary and stuff yeah u need to do those yeah

  static var TEMPLATE_1 = '
{#import kitten.Meow}

{#var meow = "test"}
{#var state = (a: String, b: String) -> "meow " + a + b }
{#var name = state("0", "hoe")}
{#var wao = 0}
{#var buh = wao++}
{#var nya = { waa: { wee: "PENIS" } } }
{#var buaaasas = nya.waa.wee}
{#var range = 0...2}

{#var the_await = @await buh}

wao({wao}): inc({buh}, should be 1)

his name? {name}

we accessed `nya` and the result was shocking: {buaaasas}

{"index.greeting".trans({ username: "pidar" })}

{#for(i in range)}
  {i}awa
{/for}

{#var noise = "meow"}
{#var aaa = switch noise}
  {:case "meow"}
    {#var meeew = if(false)}
      {"a"}
    {:else}
      {"b"}
    {/if}
    <h1>{meeew}</h1>

  {:case _}
    <i>unknown noise</i>
{/switch}a
{aaa}

{@html #var emeow}
  hi {noise}
{/var}

emeow:{emeow}

{Translation.get("index.cat.name", {})}

!true: {!true}
!!!true: {!!!true}
{2^2}

do more binops, then cleanup?
  oh dont forget otehr statements, i mean exprs
    yeah and blocks, like \\{\\#var meow = () -> \\{ "hi"; }}
    oh and \\{\\@trim #function hi(who: String)}
      hi \\{who}
\\{/function} 

  and also.. errors? async? no whiles cuz i hate the idea of it being in a templating lang.. null coalesce?
  compilation so its more optimized and faster while serving? like how twig does it with cache? idk
  and string interpolation like haxe does (and escaping)
  and fields.. like "hi".reverse() (JUST USE HAXE STUFF >:C) and metas..
  oh and add USING because.. its goood and cool yes 
  and more for loop iterators
  and more more more more
  and haxe [for(i in 0...1) i] stuff.. everythin\'s exprs (maps?)f
  no classes. no.
  importing other templates?
  OH AND TYPES DONT FORGET THE TYPES
  and safety plz make this try  not to error alot.. its bad to have that here 

{!"🐾"}
{()}
meow == "test": {meow == "test"}
{#if(meow == "test")}
  {#var meow = "mrrp"}
  paw + { state("hiii", "") }
{/if}';
/*
<div>
  <greeting>{@trans "index.greeting"} {#trans "index.cat.name"}</greeting>
</div>

{@trans "index.greeting"}
{@trans("index.greeting")}
{"index.greeting"|trans}



{@macro expr}
{@macro expr => expr:uppercase()} | {@trans(".keyword", { bla: "qzip" }, "en-us"):uppercase()}
{#keyword expr}
{{ expr }}

{#await meow}
awa
{:then val}
promis {promise}
{/await}

addr reactivity too (parse html`)

*/
/*'
{% var arr = ["a", "b"] %}
{% var name = @state("mraow", "hoe") %}
{% var buh = wao++ %}
{% var meow = { waa: { wee: "PENIS" } } %}
{% var buaaasas = meow.waa.wee %}

{% var aa = 0..5 %}

{% for a in pa %}

{% endfor %}

{% if @name == "mraow" %}
  {% var a = "" %}
  kity sounds normal
{% else if 1 == 1 %}
bih
{% else %}
  kity is weird
{% endif %}
';*/


  public static var translations = new Translation()
    .load(en_us, [
      "index.greeting" => "hi %username%",
      "index.cat.name" => "orbl"
    ])
    .load(lt_lt, [
      "index.greeting" => "labas %username%"
    ]);

  public static function test(data: String, config: TemConfig = null) {
		var all_timestamp_start = Timer.stamp();
    
    final config: TemConfig = config ?? {
      interp: {
      }
    };

    var tokenizer = new Tokenizer(data, config.tokenizer);

    var tokens = tokenizer.tokenize();
    trace("=== tokenizer:");
    trace(tokens);
		var tokenizer_timestamp_end = Timer.stamp();

		var parser_timestamp_start = Timer.stamp();
    var parser = new Parser(tokens, config.parser);
    var statements = parser.parse();
    trace("=== parser:");
    trace(statements);
		var parser_timestamp_end = Timer.stamp();
		
    var interp_timestamp_start = Timer.stamp();
    var interpreter = new Interpreter(config.interp);
    interpreter.load_module(translations);

    // massive todo
    var exprs = switch statements { 
      case Success(exprs): 
        exprs;
         
      case Error(exprs, errors): 
        // var errors = errors.map((e) -> 'unknown.tem:${e.token.pos.line}:${e.token.pos.column}: ${e.message}').join("\n");
        throw errors.join("\n");
    }

    var printer = new Printer();

    trace('exprs: \n ${printer.print_exprs(exprs)}');

    interpreter.run(exprs);
		var all_timestamp_end = Timer.stamp();

    final output = interpreter.output_raw();

    return {
      time: {
        all: all_timestamp_end - all_timestamp_start,
        interp: all_timestamp_end - interp_timestamp_start,
        parser: parser_timestamp_end - parser_timestamp_start,
        tokenizer: tokenizer_timestamp_end - all_timestamp_start,
      },
      output: output
    };
  }

  public static function main() {
    var test_1 = test(TEMPLATE_1);
    trace('------ TEST1 ------');
    trace('all time: ${test_1.time.all * 1000}ms');
    trace('tokenizer time: ${test_1.time.tokenizer * 1000}ms');
    trace('parser time: ${test_1.time.parser * 1000}ms');
    trace('interp time: ${test_1.time.interp * 1000}ms');
    trace('output:');
    trace(test_1.output);
    trace('------  END  ------');
  }
}