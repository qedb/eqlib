// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Maps mexpr types to default function strings.
final _mexprMap = new Map<Type, String>.from({
  mexpr.Plus: 'add',
  mexpr.Minus: 'sub',
  mexpr.Times: 'mul',
  mexpr.Divide: 'div'
});

Expr _exprFromMexpr(mexpr.Expression expr, ExprResolve resolver) {
  if (expr is mexpr.Literal) {
    // If the expression value is a string, resolve it, else create a numeric
    // expression.
    if (expr is mexpr.Variable) {
      return new Expr(resolver(expr.name), false, []);
    } else if (expr is mexpr.Number) {
      return new Expr.numeric(expr.value);
    } else {
      throw new UnsupportedError(
          'mexpr.Literal of type ${expr.runtimeType} is not supported.');
    }
  } else if (expr is mexpr.UnaryMinus) {
    return mul(-1, expr.exp);
  } else if (expr is mexpr.BinaryOperator) {
    // Try to resolve using _mexprMap.
    if (_mexprMap.containsKey(expr.runtimeType)) {
      return new Expr(resolver(_mexprMap[expr.runtimeType]), false, [
        _exprFromMexpr(expr.first, resolver),
        _exprFromMexpr(expr.second, resolver)
      ]);
    } else {
      throw new UnimplementedError(
          'mexpr.BinaryOperator of type ${expr.runtimeType} is not implemented');
    }
  } else if (expr is mexpr.MathFunction) {
    return new Expr(
        resolver(expr.name),
        false,
        new List<Expr>.generate(
            expr.args.length, (i) => _exprFromMexpr(expr.args[i], resolver)));
  } else {
    throw new UnsupportedError(
        'expr type ${expr.runtimeType} is not supported.');
  }
}
