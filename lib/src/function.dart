// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Function expression
///
/// Note on generic functions:
/// Generic functions can map to only one expression. When arguments are
/// provided, these are used for additional substitutions in the expression the
/// generic function maps to.
class FunctionExpr extends Expr {
  final int id;
  final bool _generic;
  final List<Expr> args;

  FunctionExpr(this.id, this._generic, this.args) {
    assert(id != null && args != null); // Do not accept null as input.
  }

  @override
  FunctionExpr clone([Expr argCopy(Expr expr) = Expr.staticClone]) =>
      new FunctionExpr(
          id,
          _generic,
          new List<Expr>.generate(args.length, (i) => argCopy(args[i]),
              growable: false));

  @override
  bool equals(other) =>
      other is FunctionExpr &&
      other.id == id &&
      const ListEquality().equals(other.args, args);

  @override
  int get expressionHash => jPostprocess(
      jMix(args.fold(0, (hash, arg) => jMix(hash, arg.hashCode)), id));

  @override
  bool get isGeneric => _generic;

  bool get isSymbol => args.isEmpty;

  @override
  bool _compare(pattern, mapping) {
    if (pattern is NumberExpr) {
      return false;
    } else if (pattern is FunctionExpr) {
      if (pattern.isGeneric) {
        if (!mapping.addExpression(pattern.id, this, pattern.args)) {
          return false;
        } else {
          return true;
        }
      } else if (pattern.id == id && pattern.args.length == args.length) {
        // Process arguments.
        for (var i = 0; i < args.length; i++) {
          if (!args[i].compare(pattern.args[i], mapping)) {
            return false;
          }
        }
        return true;
      } else {
        return false;
      }
    } else {
      throw unsupportedType('pattern', pattern, ['NumberExpr', 'FunctionExpr']);
    }
  }

  @override
  Expr remap(mapping) {
    if (mapping.substitute.containsKey(id)) {
      if (isGeneric) {
        final depVars = mapping.dependantVars[id] ?? [];
        if (depVars.length != args.length) {
          throw new EqLibException(
              'dependant variable count does not match the target substitutions');
        }

        final substitute = mapping.substitute[id];

        // Construct mapping.
        final innerMapping = new Map<int, Expr>();
        for (var i = 0; i < depVars.length; i++) {
          final depVarId = depVars[i];
          final targetExpr = mapping.substitute[depVarId];
          final argi = args[i];

          // Only add this to the mapping if the replacement is not the same as
          // the generic dependent variable.
          if (!(argi is FunctionExpr && argi.id == depVarId)) {
            // Target must be a symbol (else remapping cannot be done).
            if (targetExpr is FunctionExpr && targetExpr.isSymbol) {
              // Throw error if the substitute depends on other variables than this
              // one.
              if (ExprMapping.strictMode &&
                  !_exprOnlyDependsOn(targetExpr.id, substitute)) {
                throw new EqLibException(
                    'in strict mode the generic substitute can only depend on the variable that is remapped');
              }

              innerMapping[targetExpr.id] =
                  argi.remap(new ExprMapping({depVarId: targetExpr}));
            } else {
              throw new EqLibException(
                  'generic function inner mapping must map from a symbol');
            }
          }
        }

        return substitute.remap(new ExprMapping(innerMapping));
      } else {
        return mapping.substitute[id].clone();
      }
    } else {
      return clone((arg) => arg.remap(mapping));
    }
  }

  @override
  Expr substituteInternal(Eq equation, W<int> index) {
    final mapping = new ExprMapping();
    if (compare(equation.left, mapping) && index.v-- == 0) {
      return equation.right.remap(mapping);
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
  num evaluate(compute) {
    final numArgs = new List<num>(args.length);
    var allEval = true;
    for (var i = 0; i < args.length; i++) {
      final value = args[i].evaluate(compute);
      if (!value.isNaN) {
        numArgs[i] = value;
        args[i] = new NumberExpr(value);
      } else {
        allEval = false;
      }
    }

    if (allEval) {
      return compute(id, numArgs);
    } else {
      return double.NAN;
    }
  }
}
