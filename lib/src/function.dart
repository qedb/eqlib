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
  final List<Expr> arguments;

  FunctionExpr(this.id, this._generic, this.arguments) {
    assert(id != null && arguments != null); // Do not accept null as input.
  }

  @override
  FunctionExpr clone([Expr argCopy(Expr expr) = Expr.staticClone]) =>
      new FunctionExpr(
          id,
          _generic,
          new List<Expr>.generate(
              arguments.length, (i) => argCopy(arguments[i]),
              growable: false));

  @override
  bool equals(other) =>
      other is FunctionExpr &&
      other.id == id &&
      const ListEquality().equals(other.arguments, arguments);

  @override
  int get expressionHash => jPostprocess(
      jMix(arguments.fold(0, (hash, arg) => jMix(hash, arg.hashCode)), id));

  @override
  bool get isGeneric => _generic;

  bool get isSymbol => arguments.isEmpty;

  @override
  List<Expr> flatten() {
    final List<Expr> list = [this];
    arguments.forEach((arg) => list.addAll(arg.flatten()));
    return list;
  }

  @override
  bool _compare(pattern, mapping) {
    if (pattern is NumberExpr) {
      return false;
    } else if (pattern is FunctionExpr) {
      if (pattern.isGeneric) {
        if (!mapping.addExpression(pattern.id, this, pattern.arguments)) {
          return false;
        } else {
          return true;
        }
      } else if (pattern.id == id &&
          pattern.arguments.length == arguments.length) {
        // Process arguments.
        for (var i = 0; i < arguments.length; i++) {
          if (!arguments[i].compare(pattern.arguments[i], mapping)) {
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
        if (depVars.length != arguments.length) {
          throw new EqLibException(
              'dependant variable count does not match the target substitutions');
        }

        final substitute = mapping.substitute[id];

        // Construct mapping.
        final innerMapping = new Map<int, Expr>();
        for (var i = 0; i < depVars.length; i++) {
          final depVarId = depVars[i];
          final targetExpr = mapping.substitute[depVarId];
          final argi = arguments[i];

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
  Expr _substituteAt(rule, position) {
    if (position.v == 0) {
      position.v--; // Set to -1 so it is clear the substitution is processed.
      final mapping = new ExprMapping();
      if (compare(rule.left, mapping)) {
        return rule.right.remap(mapping);
      } else {
        throw new EqLibException('rule does not match at given position');
      }
    } else {
      position.v--;

      // Walk through arguments.
      for (var i = 0; i < arguments.length; i++) {
        arguments[i] = arguments[i]._substituteAt(rule, position);
        if (position.v == -1) {
          break;
        }
      }

      return this;
    }
  }

  @override
  Expr evaluate(compute) {
    // It is possible to return immediately if there are no arugments.

    final numericArguments = new List<num>();
    for (var i = 0; i < arguments.length; i++) {
      final evaluated = arguments[i].evaluate(compute);
      arguments[i] = evaluated;
      if (evaluated is NumberExpr) {
        numericArguments.add(evaluated.value);
      }
    }

    if (numericArguments.length == arguments.length) {
      final value = compute(id, numericArguments);
      return !value.isNaN ? new NumberExpr(value) : this;
    } else {
      return this;
    }
  }
}
