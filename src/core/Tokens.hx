package core;

enum Keyword {
  KImport;

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
  KInner(keyword: Keyword);
}

final keywords = [
  "import" => KImport,

  "true" => KTrue,
  "false" => KFalse,
  "null" => KNull,

  "var" => KVar,
  "final" => KFinal,

  "function" => KFunction,
  // "func" => KFunction,
  // "endfunc" => KEnd(KFunction),

  "if" => KIf,
  "else" => KElse,
  "for" => KFor,

  "switch" => KSwitch,
  "case" => KCase,

  "in" => KIn,
];

enum Operator {
  OAssign; // =
  OEqual; // ==
  ONotEqual; // !=
  OLess; // <
  OGreater; // >
  OLessEqual; // <=
  OGreaterEqual; // >=

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

enum StringKind {
  SKRaw;
  SKQuote;
}

enum Token {
  TNull;
  TBool(bool: Bool);
  TNumber(number: Float);
  TString(string: String, kind: StringKind);

  TIdentifier(name: String);

  TOperator(op: Operator);

  TKeyword(keyword: Keyword);

  // TOutput(token: Token);

  TAt; // @
  TDot; // .
  TComma; // ,
  TColon; // :
  TRange; // ...
  TArrow; // ->
  TMapArrow; // =>
  TVerticalBar; // |
  
  TLeftParentheses; // (
  TRightParentheses; // )
  TLeftBrace; // {
  TRightBrace; // }
  TLeftBracket; // [
  TRightBracket; // ]
  TSemiColon; // ;

  TNewline;
  TEoF;
}

typedef TokenPos = {
  token: Token,
  pos: Position
}

typedef Position = {
  final name: String;
  final line: Int;
  final column: Int;
}