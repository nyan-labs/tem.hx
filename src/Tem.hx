package;

import core.Parser;

class Tem {
  // TODO!! TESTSs!!!! PLEASE
  static var TEMPLATE_1 = '
{#var meow = "test"}
{#var name = @state("mraow", "hoe")}
{#var buh = wao++}
{#var meow = { waa: { wee: "PENIS" } } }
{#var buaaasas = meow.waa.wee}
{#var range = 0..6}

{#if meow == "test"}
  buttsex
{/if}';
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

  public static function main() {
    var tokenizer = new core.Tokenizer(TEMPLATE_1);

    var tokens = tokenizer.tokenize();
    trace(tokens);

    var parser = new Parser(tokens);

    parser.parse();
  }
}