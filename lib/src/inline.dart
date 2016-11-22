// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.inline;

/// Expression used to point out where an equation is substituted when wrapping.
final innerExpr = new ExprSym(0);

/// Create a numeric expression from the given value.
Expr number(num value) => new ExprNum(value);

/// Create a symbol expression for the given label.
Expr symbol(String label) => new ExprSym(dfltExprEngine.resolve(label));

/// Expression generator for functions with two arguments.
Expr _twoArgsExpr(int code, dynamic a, dynamic b) =>
    new ExprFun(code, [new Expr.wrap(a), new Expr.wrap(b)]);

/// a + b
Expr add(dynamic a, dynamic b) =>
    _twoArgsExpr(dfltExprEngine.resolve('add'), a, b);

/// a - b
Expr sub(dynamic a, dynamic b) =>
    _twoArgsExpr(dfltExprEngine.resolve('sub'), a, b);

/// a * b
Expr mul(dynamic a, dynamic b) =>
    _twoArgsExpr(dfltExprEngine.resolve('mul'), a, b);

/// a / b
Expr div(dynamic a, dynamic b) =>
    _twoArgsExpr(dfltExprEngine.resolve('div'), a, b);

/// a ^ b
Expr pow(dynamic a, dynamic b) =>
    _twoArgsExpr(dfltExprEngine.resolve('pow'), a, b);

/// Quick syntax for equation contruction.
Eq eq(dynamic left, dynamic right) =>
    new Eq(new Expr.wrap(left), new Expr.wrap(right));

/// Generate a list of expression IDs for the given expressions.
List<int> exprIds(List<Expr> exprs) =>
    new List<int>.generate(exprs.length, (i) {
      final expr = exprs[i];
      return expr is ExprSym ? expr.id : expr is ExprFun ? expr.id : 0;
    });

/// Single argument expression generator
typedef Expr ExprGenerator1(Expr arg1);

/// Create single argument expression generator.
ExprGenerator1 fn1(String label) {
  final id = dfltExprEngine.resolve(label);
  return (arg1) => new ExprFun(id, [arg1]);
}

/// Double argument expression generator
typedef Expr ExprGenerator2(Expr arg1, Expr arg2);

/// Create double argument expression generator.
ExprGenerator2 fn2(String label) {
  final id = dfltExprEngine.resolve(label);
  return (arg1, arg2) => new ExprFun(id, [arg1, arg2]);
}
