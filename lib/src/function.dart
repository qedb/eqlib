// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Grouping for both [FunctionExpr] and [SymbolExpr]
abstract class FunctionSymbolExpr extends Expr {
  final int id;
  final bool generic;
  FunctionSymbolExpr(this.id, this.generic);
}

/// Function expression
class FunctionExpr extends FunctionSymbolExpr {
  final List<Expr> args;

  FunctionExpr(int id, this.args, [bool generic = false]) : super(id, generic) {
    assert(id != null && args != null); // Do not accept null as input.
    assert(args.isNotEmpty); // Without args a SymbolExpr should be used.
  }

  @override
  FunctionExpr clone([Expr argCopy(Expr expr) = Expr.staticClone]) =>
      new FunctionExpr(
          id,
          new List<Expr>.generate(args.length, (i) => argCopy(args[i]),
              growable: false),
          generic);

  @override
  bool equals(other) =>
      other is FunctionExpr &&
      other.id == id &&
      other.args.length == args.length &&
      ifEvery(other.args, args, (a, b) => a == b);

  @override
  int get expressionHash => jFinish(
      jCombine(args.fold(0, (hash, arg) => jCombine(hash, arg.hashCode)), id));

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
        return new ExprMatchResult.processGenericFunction(superset, this);
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
  Expr remap(mapping, genericFunctions) {
    if (mapping.containsKey(id)) {
      if (isGeneric) {
        if (args.length != 1) {
          throw new EqLibException(
              'generic functions can only have a single argument');
        }

        // + If the first argument of the original function is a generic symbol
        //   (symbolA)
        // + If this generic symbol maps to another symbol
        //   (symbolB)
        //
        // Return the provided mapping for this function but first:
        // + Replace the b symbol with the remapped contents of this function
        if (genericFunctions.containsKey(id)) {
          final symbolA = genericFunctions[id].args.first;
          if (symbolA.isGeneric && symbolA is SymbolExpr) {
            final symbolB = mapping[symbolA.id];
            if (symbolB is SymbolExpr) {
              return mapping[id].remap({symbolB.id: args.first}, {}).remap(
                  mapping, genericFunctions);
            }
          }
        }
      }
      return mapping[id].clone();
    } else {
      return clone((arg) => arg.remap(mapping, genericFunctions));
    }
  }

  @override
  Expr substituteInternal(Eq equation, W<int> index) {
    final result = matchSuperset(equation.left);
    if (result.match && index.v-- == 0) {
      return equation.right.remap(result.mapping, result.genericFunctions);
    }

    // Iterate through arguments, and try to substitute the equation there.
    for (var i = 0; i < args.length; i++) {
      args[i] = args[i].substituteInternal(equation, index);
      if (index.v < 0) {
        // The substitution position has been found: terminate.
        break;
      }
    }

    return this;
  }

  @override
  num evaluateInternal(canCompute, compute) {
    final numArgs = new List<num>(args.length);
    var allEval = true;
    for (var i = 0; i < args.length; i++) {
      final value = args[i].evaluate(canCompute, compute);
      if (!value.isNaN) {
        numArgs[i] = value;
        args[i] = new NumberExpr(value);
      } else {
        allEval = false;
      }
    }

    if (allEval && canCompute(id)) {
      return compute(id, numArgs);
    } else {
      return double.NAN;
    }
  }
}
