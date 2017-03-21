// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.inline;

/// Ugly, but fine for testing.
final inlineCtx = new SimpleExprContext();

/// Caution, this is EXTREMELY ugly glue to inherit expression operators for
/// writing nice tests without having to pollute the main implementation.
class ExprOperators {
  static int _opId(String char) => inlineCtx.assignId(char, false);

  /// Add other expression.
  FunctionExprOps operator +(dynamic other) => new FunctionExprOps(
      _opId('+'), false, [new Expr.from(this), new Expr.from(other)]);

  /// Subtract other expression.
  FunctionExprOps operator -(dynamic other) => new FunctionExprOps(
      _opId('-'), false, [new Expr.from(this), new Expr.from(other)]);

  /// Multiply by other expression.
  FunctionExprOps operator *(dynamic other) => new FunctionExprOps(
      _opId('*'), false, [new Expr.from(this), new Expr.from(other)]);

  /// Divide by other expression.
  FunctionExprOps operator /(dynamic other) => new FunctionExprOps(
      _opId('/'), false, [new Expr.from(this), new Expr.from(other)]);

  /// Power by other expression.
  FunctionExprOps operator ^(dynamic other) => new FunctionExprOps(
      _opId('^'), false, [new Expr.from(this), new Expr.from(other)]);

  /// Negate expression.
  FunctionExprOps operator -() =>
      new FunctionExprOps(_opId('~'), false, [new Expr.from(this)]);
}

class NumberExprOps extends NumberExpr with ExprOperators {
  NumberExprOps(num value) : super(value);
}

class FunctionExprOps extends FunctionExpr with ExprOperators {
  FunctionExprOps(int id, bool generic, List<Expr> args)
      : super(id, generic, args);
}

/// Expression used to point out where an equation is substituted when
/// enveloping.
FunctionExprOps envelopeInner() => new FunctionExprOps(0, false, []);

/// Create a numeric expression from the given value.
NumberExprOps number(num value) => new NumberExprOps(value);

/// Create a symbol expression for the given label.
FunctionExprOps symbol(String label, {bool generic: false}) =>
    new FunctionExprOps(inlineCtx.assignId(label, generic), generic, []);

/// Alias for creating generic symbols.
FunctionExprOps generic(String label) => symbol(label, generic: true);

/// Quick syntax for equation contruction.
Eq eq(dynamic left, dynamic right) =>
    new Eq(new Expr.from(left), new Expr.from(right));

typedef FunctionExprOps ExprGenerator1(dynamic arg1);
typedef FunctionExprOps ExprGenerator2(dynamic arg1, dynamic arg2);
typedef FunctionExprOps ExprGenerator3(
    dynamic arg1, dynamic arg2, dynamic arg3);

/// Create single argument expression generator.
ExprGenerator1 fn1(String label, {bool generic: false}) {
  final id = inlineCtx.assignId(label, generic);
  return (arg1) => new FunctionExprOps(id, generic, [new Expr.from(arg1)]);
}

/// Create double argument expression generator.
ExprGenerator2 fn2(String label) {
  final id = inlineCtx.assignId(label, false);
  return (arg1, arg2) => new FunctionExprOps(
      id, false, [new Expr.from(arg1), new Expr.from(arg2)]);
}

/// Create double argument expression generator.
ExprGenerator3 fn3(String label) {
  final id = inlineCtx.assignId(label, false);
  return (arg1, arg2, arg3) => new FunctionExprOps(id, false,
      [new Expr.from(arg1), new Expr.from(arg2), new Expr.from(arg3)]);
}
