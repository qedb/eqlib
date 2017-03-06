// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.inline;

/// Expression used to point out where an equation is substituted when
/// enveloping.
final innerExpr = new SymbolExpr(0);

/// Create a numeric expression from the given value.
Expr number(num value) => new NumberExpr(value);

/// Create a symbol expression for the given label.
Expr symbol(String label, {bool generic: false}) =>
    new SymbolExpr(Expr.defaultContext.assignId(label, generic), generic);

/// Alias for creating generic symbols.
Expr generic(String label) => symbol(label, generic: true);

/// Quick syntax for equation contruction.
Eq eq(dynamic left, dynamic right) =>
    new Eq(new Expr.from(left), new Expr.from(right));

/// Single argument expression generator
typedef Expr ExprGenerator1(dynamic arg1);

/// Create single argument expression generator.
ExprGenerator1 fn1(String label, {bool generic: false}) {
  final id = Expr.defaultContext.assignId(label, generic);
  return (arg1) => new FunctionExpr(id, [new Expr.from(arg1)], generic);
}

/// Double argument expression generator
typedef Expr ExprGenerator2(dynamic arg1, dynamic arg2);

/// Create double argument expression generator.
ExprGenerator2 fn2(String label) {
  final id = Expr.defaultContext.assignId(label, false);
  return (arg1, arg2) =>
      new FunctionExpr(id, [new Expr.from(arg1), new Expr.from(arg2)], false);
}

/// Triple argument expression generator
typedef Expr ExprGenerator3(dynamic arg1, dynamic arg2, dynamic arg3);

/// Create double argument expression generator.
ExprGenerator3 fn3(String label) {
  final id = Expr.defaultContext.assignId(label, false);
  return (arg1, arg2, arg3) => new FunctionExpr(id,
      [new Expr.from(arg1), new Expr.from(arg2), new Expr.from(arg3)], false);
}

/// We don't want to pollute the global namespace with this in the main library.
TreeDiffResult difference(Expr a, Expr b) => computeTreeDiff(a, b);
