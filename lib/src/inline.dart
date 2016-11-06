// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.inline;

/// Expression used to point out where an equation is substituted when wrapping.
final innerExpression = new Expr(0, false, []);

/// Create a symbol expression for the given label.
Expr symbol(String label) => new Expr(defaultResolver(label), false, []);

/// Expression generator for functions with two arguments.
Expr _twoArgsExpr(int code, dynamic a, dynamic b) => new Expr(code, false, [
      a is num ? new Expr.numeric(a) : a as Expr,
      b is num ? new Expr.numeric(b) : b as Expr
    ]);

/// a + b
Expr add(dynamic a, dynamic b) => _twoArgsExpr(defaultResolver('add'), a, b);

/// a - b
Expr sub(dynamic a, dynamic b) => _twoArgsExpr(defaultResolver('sub'), a, b);

/// a * b
Expr mul(dynamic a, dynamic b) => _twoArgsExpr(defaultResolver('mul'), a, b);

/// a / b
Expr div(dynamic a, dynamic b) => _twoArgsExpr(defaultResolver('div'), a, b);

/// a ^ b
Expr pow(dynamic a, dynamic b) => _twoArgsExpr(defaultResolver('pow'), a, b);

/// Quick syntax for equation contruction.
Eq eq(dynamic left, dynamic right) => new Eq(
    left is num ? new Expr.numeric(left) : left as Expr,
    right is num ? new Expr.numeric(right) : right as Expr);

/// Quick syntax for numeric expression construction.
Expr n(num value) => new Expr.numeric(value);

/// Generate a list of expression IDs for the given expressions.
List<int> exprIds(List<Expr> exprs) =>
    new List<int>.generate(exprs.length, (i) => exprs[i].value.toInt());

typedef Expr ExprGenerator1(Expr arg1);

ExprGenerator1 fn1(String label) =>
    (arg1) => new Expr(defaultResolver(label), false, [arg1]);
