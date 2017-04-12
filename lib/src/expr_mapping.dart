// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Mapping data.
class ExprMapping {
  /// When strict mode is enabled only some cases of generic internal remapping
  /// are allowed to prevent loopholes.
  /// Currently we offer no way to disable strict mode.
  static const strictMode = true;

  /// Map of from function ID to expression that is to be substituted.
  final Map<int, Expr> substitute;

  /// Map of from generic function ID to dependant variables.
  /// Used for remapping substituted generic function expressions.
  final Map<int, List<int>> dependantVars;

  ExprMapping([Map<int, Expr> substitute, Map<int, List<Expr>> dependantVars])
      : substitute = substitute ?? new Map<int, Expr>(),
        dependantVars = dependantVars ?? new Map<int, List<int>>();

  /// Add generic expression. Returns false if another expression is set.
  bool addExpression(int id, Expr targetExpr,
      [List<Expr> targetVars = const []]) {
    if (targetVars.isNotEmpty) {
      if (strictMode && targetVars.length > 1) {
        throw new EqLibException(
            'in strict mode multiple dependant variables are not allowed');
      }

      // Collect symbol IDs.
      final ids = new List<int>();
      for (final arg in targetVars) {
        if (arg is FunctionExpr && arg.isGeneric && arg.isSymbol) {
          ids.add(arg.id);
        } else {
          // Generic function arguments may only contain generic symbols.
          throw new EqLibException(
              'dependant variables must be generic symbols');
        }
      }

      if (dependantVars.containsKey(id)) {
        if (!const ListEquality().equals(dependantVars[id], ids)) {
          throw new EqLibException(
              'generic functions must have the same arguments');
        }
      } else {
        dependantVars[id] = ids;
      }
    }

    if (substitute.containsKey(id)) {
      return substitute[id] == targetExpr;
    } else {
      substitute[id] = targetExpr;
      return true;
    }
  }

  /// Finalize mapping.
  /// Generic function arguments that are not already mapped to an expression
  /// are mapped to the argument of this function (when both have 1 argument).
  void finalize() {
    dependantVars.forEach((fnId, ids) {
      if (ids.length == 1) {
        final id = ids.first;
        if (!substitute.containsKey(id)) {
          final fn = substitute[fnId];
          if (fn is FunctionExpr && fn.arguments.length == 1) {
            substitute[id] = fn.arguments.first;
          }
        }
      }
    });
  }
}
