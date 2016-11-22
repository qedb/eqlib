// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Function expression
class ExprFun extends Expr {
  final int id;
  final List<Expr> args;

  ExprFun(this.id, this.args) {
    assert(id != null && args != null); // Do not accept null as input.
    assert(args.isNotEmpty); // If there are no args, a ExprSym should be used.
  }

  ExprFun clone([Expr argCopy(Expr expr) = Expr.staticClone]) => new ExprFun(
      id, new List<Expr>.generate(args.length, (i) => argCopy(args[i])));

  bool equals(other) =>
      other is ExprFun &&
      other.id == id &&
      other.args.length == args.length &&
      ifEvery(other.args, args, (a, b) => a == b);
  int get expressionHash => hash2(id, hashObjects(args));

  ExprMatchResult matchSuperset(superset, generic) {
    if (superset is ExprNum) {
      return new ExprMatchResult.noMatch();
    } else if (superset is ExprSym) {
      return generic.contains(superset.id)
          ? new ExprMatchResult.genericMatch(superset.id, this)
          : new ExprMatchResult.noMatch();
    } else if (superset is ExprFun) {
      if (generic.contains(superset.id)) {
        return superset.args.length == args.length
            ? new ExprMatchResult.processGenericFunction(
                superset.id,
                this,
                args.length,
                (i) => args[i].matchSuperset(superset.args[i], generic))
            : new ExprMatchResult.noMatch();
      } else if (superset.id == id) {
        return new ExprMatchResult.processFunction(args.length,
            (i) => args[i].matchSuperset(superset.args[i], generic));
      } else {
        return new ExprMatchResult.noMatch();
      }
    } else {
      throw new ArgumentError(
          'superset type must be one of: ExprNum, ExprSym, ExprFun');
    }
  }

  Expr remap(mapping) => mapping.containsKey(id)
      ? mapping[id].clone()
      : clone((arg) => arg.remap(mapping));

  Expr subs(Eq equation, List<int> generic, W<int> index) {
    final result = matchSuperset(equation.left, generic);
    if (result.match && index.v-- == 0) {
      return equation.right.remap(result.mapping);
    }

    // Iterate through arguments, and try to substitute the equation there.
    for (var i = 0; i < args.length; i++) {
      args[i] = args[i].subs(equation, generic, index);
      if (index.v < 0) {
        // The substitution position has been found: terminate.
        break;
      }
    }

    return this;
  }

  num eval(canCompute, compute) {
    final numArgs = new List<num>(args.length);
    var allEval = true;
    for (var i = 0; i < args.length; i++) {
      final value = args[i].eval(canCompute, compute);
      if (value != null) {
        numArgs[i] = value;
        args[i] = new ExprNum(value);
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
