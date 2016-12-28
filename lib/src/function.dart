// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Function expression
class FunctionExpr extends Expr {
  final int id;
  final bool generic;
  final List<Expr> args;

  FunctionExpr(this.id, this.args, [this.generic = false]) {
    assert(id != null && args != null); // Do not accept null as input.
    assert(
        args.isNotEmpty); // If there are no args, a SymbolExpr should be used.
  }

  @override
  FunctionExpr clone([Expr argCopy(Expr expr) = Expr.staticClone]) =>
      new FunctionExpr(
          id,
          new List<Expr>.generate(args.length, (i) => argCopy(args[i])),
          generic);

  @override
  bool equals(other) =>
      other is FunctionExpr &&
      other.id == id &&
      other.args.length == args.length &&
      ifEvery(other.args, args, (a, b) => a == b);

  @override
  int get expressionHash => hash2(id, hashObjects(args));

  @override
  bool get isGeneric => generic;

  @override
  ExprMatchResult matchSuperset(superset) {
    if (superset is NumberExpr) {
      return new ExprMatchResult.noMatch();
    } else if (superset is SymbolExpr) {
      return superset.isGeneric
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch();
    } else if (superset is FunctionExpr) {
      if (superset.isGeneric) {
        return superset.args.length == args.length
            ? new ExprMatchResult.processGenericFunction(superset.id, this,
                args.length, (i) => args[i].matchSuperset(superset.args[i]))
            : new ExprMatchResult.noMatch();
      } else if (superset.id == id) {
        return new ExprMatchResult.processFunction(
            args.length, (i) => args[i].matchSuperset(superset.args[i]));
      } else {
        return new ExprMatchResult.noMatch();
      }
    } else {
      throw new ArgumentError(
          'superset type must be one of: NumberExpr, SymbolExpr, FunctionExpr');
    }
  }

  @override
  Expr remap(mapping) => mapping.containsKey(id)
      ? mapping[id].clone()
      : clone((arg) => arg.remap(mapping));

  @override
  Expr subsInternal(Eq equation, W<int> index) {
    final result = matchSuperset(equation.left);
    if (result.match && index.v-- == 0) {
      return equation.right.remap(result.mapping);
    }

    // Iterate through arguments, and try to substitute the equation there.
    for (var i = 0; i < args.length; i++) {
      args[i] = args[i].subsInternal(equation, index);
      if (index.v < 0) {
        // The substitution position has been found: terminate.
        break;
      }
    }

    return this;
  }

  @override
  num _eval(canCompute, compute) {
    final numArgs = new List<num>(args.length);
    var allEval = true;
    for (var i = 0; i < args.length; i++) {
      final value = args[i].eval(canCompute, compute);
      if (value != null) {
        numArgs[i] = value;
        args[i] = new NumberExpr(value);
      } else {
        allEval = false;
      }
    }

    if (allEval && canCompute(id)) {
      return compute(id, numArgs);
    } else {
      return null;
    }
  }
}
