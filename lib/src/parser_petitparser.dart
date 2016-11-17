// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// EqEx grammar.
class EqExGrammar extends GrammarParser {
  EqExGrammar() : super(const EqExGrammarDefinition());
}

/// EqEx grammar definition.
class EqExGrammarDefinition extends GrammarDefinition {
  const EqExGrammarDefinition();

  Parser start() => ref(lvl1).end();
  Parser token(p) => p.flatten().trim();

  Parser lvl1() => (ref(add) | ref(sub)) | ref(lvl2);
  Parser lvl2() => (ref(mul) | ref(div)) | ref(lvl3);
  Parser lvl3() => ref(power) | ref(lvl4);
  Parser lvl4() => ref(fn) | ref(term);

  Parser add() => ref(lvl2).seq(ref(token, char('+'))).seq(ref(lvl1));
  Parser sub() => ref(lvl2).seq(ref(token, char('-'))).seq(ref(lvl1));
  Parser mul() => ref(lvl3).seq(ref(token, char('*'))).seq(ref(lvl2));
  Parser div() => ref(lvl3).seq(ref(token, char('/'))).seq(ref(lvl2));
  Parser power() => ref(lvl4).seq(ref(token, char('^'))).seq(ref(lvl3));

  Parser fn() => (ref(fnName) &
      ref(token, char('('))
          .seq(ref(fnArgs))
          .seq(ref(token, char(')')))
          .optional());
  Parser fnName() => ref(
      token, letter().seq((word() | char('_') | char('{') | char('}')).star()));
  Parser fnArgs() =>
      ref(lvl1).separatedBy(ref(token, char(',')), includeSeparators: false);

  Parser term() => ref(token, char('('))
      .seq(ref(lvl1))
      .seq(ref(token, char(')')))
      .or(ref(number));

  Parser number() => ref(
      token,
      (char('-').optional() &
          char('0').or(digit().plus()) &
          char('.').seq(digit().plus()).optional()));
}

/// EqEx parser.
class EqExParser extends GrammarParser {
  EqExParser([ExprResolve resolver = standaloneResolve])
      : super(new EqExParserDefinition(resolver));
}

/// EqEx parser definition.
class EqExParserDefinition extends EqExGrammarDefinition {
  final ExprResolve resolver;

  const EqExParserDefinition(this.resolver);

  Parser number() =>
      super.number().map((value) => new Expr.numeric(num.parse(value)));

  Parser add() => super.add().map((values) => values[0] + values[2]);
  Parser sub() => super.sub().map((values) => values[0] - values[2]);
  Parser mul() => super.mul().map((values) => values[0] * values[2]);
  Parser div() => super.div().map((values) => values[0] / values[2]);
  Parser power() => super.power().map((values) => values[0] ^ values[2]);

  Parser fn() => super.fn().map((values) {
        final code = resolver(values.first);
        if (values[1] is List && values[1][1] is List) {
          final List args = values[1][1];
          return new Expr.function(
              code, new List<Expr>.generate(args.length, (i) => args[i]));
        } else {
          return new Expr.function(code, []);
        }
      });

  Parser term() => super.term().map((value) {
        if (value is List) {
          // Discard parenthesis.
          return value[1];
        } else {
          return value;
        }
      });
}
