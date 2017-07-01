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
              arguments.length, (i) => argCopy(arguments[i])));

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
    final list = new List<Expr>()..add(this);
    for (final arg in arguments) {
      list.addAll(arg.flatten());
    }
    return list;
  }

  @override
  void getFunctionIds(target) {
    target.add(id);
    for (final arg in arguments) {
      arg.getFunctionIds(target);
    }
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
          throw const EqLibException(
              'dependant variable count does not match the target substitutions');
        }

        final substitute = mapping.substitute[id];

        // Construct mapping.
        final innerMapping = new Map<int, Expr>();
        for (var i = 0; i < depVars.length; i++) {
          final argument = arguments[i];
          final depVarId = depVars[i];
          final targetExpr = mapping.substitute[depVarId];

          // Only add this to the mapping if the replacement is not the same as
          // the generic dependent variable.
          if (!(argument is FunctionExpr && argument.id == depVarId)) {
            // Target must be a symbol (else remapping cannot be done).
            if (targetExpr is FunctionExpr && targetExpr.isSymbol) {
              // Throw error if the substitute depends on other variables than this
              // one.
              if (ExprMapping.strictMode &&
                  !_exprOnlyDependsOn(targetExpr.id, substitute)) {
                throw const EqLibException(
                    'in strict mode the generic substitute can only depend on the variable that is remapped');
              }

              innerMapping[targetExpr.id] =
                  argument.remap(new ExprMapping({depVarId: targetExpr}));
            } else {
              throw const EqLibException(
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
    if (position.v-- == 0) {
      final mapping = new ExprMapping();
      if (compare(rule.left, mapping)) {
        return rule.right.remap(mapping);
      } else {
        throw const EqLibException('rule does not match at the given position');
      }
    } else {
      final newArguments =
          arguments.map((arg) => arg._substituteAt(rule, position));
      return new FunctionExpr(id, _generic, newArguments.toList());
    }
  }

  @override
  Expr _rearrangeAt(rearrange, position, rearrangeableIds) {
    if (position.v-- == 0) {
      if (rearrangeableIds.contains(id)) {
        return _rearrangeArguments(rearrange);
      } else {
        throw const EqLibException(
            'given position is not a rearrangeable function');
      }
    } else {
      final newArguments = arguments.map(
          (arg) => arg._rearrangeAt(rearrange, position, rearrangeableIds));
      return new FunctionExpr(id, _generic, newArguments.toList());
    }
  }

  /// Returns list of cloned arguments that are rearranged according to the
  /// given order.
  ///
  /// Routine:
  /// + The current children are numbered 0 to N in order of occurrence.
  /// + The format defines the new structure for these children.
  /// + This format is squeezed in a flat integer list so is is easier to store.
  /// + The number of arguments in this function is used as argument number for
  ///   all formed child functions (compliant with static argc convention).
  /// + `-1` in the format array means that the previous N arguments are wrapped
  ///   in a function. (e.g. `[2, [1, 0]]` becomes )
  Expr _rearrangeArguments(List<int> format) {
    final argc = arguments.length;

    /// Retrieve rearrangeable children.
    final children = getChildren();
    final used = new Set<int>();

    /// Render resulting format.
    final output = new List<Expr>();
    for (final value in format) {
      if (value == -1) {
        // Get last [argc] arguments from stack.
        final args = new List<Expr>.generate(argc, (_) => output.removeLast())
            .reversed
            .toList();

        // Wrap arguments in function.
        output.add(new FunctionExpr(id, _generic, args));
      } else {
        if (value >= 0 && value < children.length && used.add(value)) {
          output.add(children[value].expr);
        } else {
          throw const EqLibException('illegal value');
        }
      }
    }

    // Wrap final output in function.
    if (output.length != argc || used.length != children.length) {
      throw const EqLibException('malformed format');
    }

    return new FunctionExpr(id, _generic, output);
  }

  /// Used by [_rearrangeArguments].
  /// Returns low level children (descends functions with same ID).
  List<FunctionChild> getChildren([bool terminateFunctionsWithNull = false]) {
    final children = new List<FunctionChild>();
    var distanceSum = 1;
    for (final arg in arguments) {
      if (arg is FunctionExpr && arg.id == id) {
        final subchildren = arg.getChildren(terminateFunctionsWithNull);
        children.addAll(subchildren.map((child) => child != null
            ? new FunctionChild(child.expr, distanceSum + child.distance)
            : null));
        if (terminateFunctionsWithNull) {
          // This is a bit of a dirty trick, but it allows linear construction
          // of the rearrange format data in [_computeRearrangement].
          children.add(null);
        }
      } else {
        children.add(new FunctionChild(arg, distanceSum));
      }
      distanceSum += arg.size;
    }
    return children;
  }

  @override
  Expr evaluate(compute) {
    final newArguments = new List<Expr>();
    for (var i = 0; i < arguments.length; i++) {
      newArguments.add(arguments[i].evaluate(compute));
    }

    final numericValues = new List<num>();
    for (final expr in newArguments) {
      if (expr is NumberExpr) {
        numericValues.add(expr.value);
      }
    }

    if (numericValues.length == arguments.length) {
      final value = compute(id, numericValues);
      if (!value.isNaN) {
        return new NumberExpr(value);
      }
    }

    return new FunctionExpr(id, _generic, newArguments);
  }
}

/// Data for [FunctionExpr.getChildren].
class FunctionChild {
  final Expr expr;
  final int distance;
  FunctionChild(this.expr, this.distance);
}
