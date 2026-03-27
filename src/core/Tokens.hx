package core;

enum Keyword {
  KTrue;
  KFalse;
  KNull;

  KVar; // variable
  KFinal; // constant variable

  KFunction;

  KIf;
  KElse;
  KFor;

  KIn;

  KSwitch;
  KCase;
  
  KEnd(keyword: Keyword);
}

final keywords = [
  "true" => KTrue,
  "false" => KFalse,
  "null" => KNull,

  "var" => KVar,
  "endvar" => KEnd(KVar),
  "final" => KFinal,
  "endfinal" => KEnd(KFinal),

  "function" => KFunction,
  "endfunction" => KEnd(KFunction),
  "func" => KFunction,
  "endfunc" => KEnd(KFunction),

  "if" => KIf,
  "else" => KElse,
  "endif" => KEnd(KIf),
  "for" => KFor,
  "endfor" => KEnd(KFor),

  "switch" => KSwitch,
  "case" => KCase,

  "in" => KIn
];

enum Operator {
  OAssign; // =
  OEqual; // ==
  ONotEqual; // !=
  OLess; // <
  OGreater; // >
  OLessEqual; // <=
  OGresterEqual; // >=

  OIncrement; // ++
  ODecrement; // --
  OAdd; // +
  OSubtract; // -
  OMultiply; // *
  ODivide; // /
  OPow; // ^
  OModulo; // %

  // do we do literal words (ex: ! - not; && - and)
  ONot; // !
  OAnd; // &&
  OOr; // ||
}

enum Token {
  TNull;
  TBool(bool: Bool);
  TNumber(number: Float);
  TString(string: String);

  TIdentifier(name: String);

  TOperator(op: Operator);

  TKeyword(keyword: Keyword);

  TOut(out: Token);

  TDot; // .
  TComma; // ,
  TColon; // :
  TRange; // ..
  TArrow; // ->
  TMapArrow; // =>
  
  TLeftParentheses; // (
  TRightParentheses; // )
  TLeftBrace; // {
  TRightBrace; // }
  TLeftBracket; // [
  TRightBracket; // ]

  TNewline;
  TEoF;
}

typedef TokenPos = {
  token: Token,

	line: Int,
	column: Int
}