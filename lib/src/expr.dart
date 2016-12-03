// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression of a variable or function
abstract class Expr {
  Expr();

  /// Transform the given value into an expression if it is not an expression
  /// already.
  factory Expr.wrap(dynamic value) {
    if (value is Expr) {
      return value;
    } else if (value is num) {
      return new ExprNum(value);
    } else {
      throw new ArgumentError('value type must be one of: Expr, num');
    }
  }

  /// Create deep copy.
  Expr clone();

  static Expr staticClone(Expr input) => input.clone();

  /// Compare to other expression.
  bool equals(Expr other);
  bool operator ==(other) => other is Expr && equals(other);

  /// Get expression hash (used by [hashCode])
  int get expressionHash;
  int get hashCode => expressionHash;

  /// Superset pattern matching
  ///
  /// Match another [superset] expression against this expression. All labels in
  /// [generic] are considered generic variables, meaning that these variables
  /// (provided there are 0 arguments), can be mapped to any expression.
  ExprMatchResult matchSuperset(Expr superset, List<int> generic);

  /// Expression remapping
  ///
  /// If this expression is in the [mapping] table, this will return the new
  /// expression. Else this will remap all arguments.
  ///
  /// This method always returns a new expression instance (deep cody).
  Expr remap(Map<int, Expr> mapping);

  /// Substitute the given [equation] at the given pattern [index].
  /// Returns a new instance of [Expr] where the equation is substituted.
  /// Never returns null, instead returns itself if nothing is substituted.
  Expr subs(Eq equation, List<int> generic, W<int> index) {
    final result = matchSuperset(equation.left, generic);
    return result.match && index.v-- == 0
        ? equation.right.remap(result.mapping)
        : this;
  }

  /// Appemts to evaluate this expression to a number using the given compute
  /// functions. Returns null if this is unsuccessful.
  ///
  /// TODO: find a way to avoid `null` as return value.
  num eval(ExprCanCompute canCompute, ExprCompute compute);

  // Standard operator IDs used by built-in operators.
  static int opAddId = standaloneResolve('add');
  static int opSubId = standaloneResolve('sub');
  static int opMulId = standaloneResolve('mul');
  static int opDivId = standaloneResolve('div');
  static int opPowId = standaloneResolve('pow');

  /// Add other expression.
  Expr operator +(other) => new ExprFun(opAddId, [this, new Expr.wrap(other)]);

  /// Subtract other expression.
  Expr operator -(other) => new ExprFun(opSubId, [this, new Expr.wrap(other)]);

  /// Multiply by other expression.
  Expr operator *(other) => new ExprFun(opMulId, [this, new Expr.wrap(other)]);

  /// Divide by other expression.
  Expr operator /(other) => new ExprFun(opDivId, [this, new Expr.wrap(other)]);

  /// Power by other expression.
  Expr operator ^(other) => new ExprFun(opPowId, [this, new Expr.wrap(other)]);

  /// Global string printer function.
  static ExprPrint stringPrinter = dfltExprEngine.print;

  /// Generate string representation.
  String toString() => stringPrinter(this);
}

/// Return data of [Expr.matchSuperset].
class ExprMatchResult {
  bool match;

  final mapping = new Map<int, Expr>();

  ExprMatchResult.exactMatch() : match = true;

  ExprMatchResult.noMatch() : match = false;

  ExprMatchResult.genericMatch(int generic, Expr ref) : match = true {
    mapping[generic] = ref;
  }

  ExprMatchResult.processGenericFunction(
      int id, Expr fnref, int argsLength, ExprMatchResult matchArg(int i)) {
    mapping[id] = fnref;
    match = _processFunction(argsLength, matchArg);
  }

  ExprMatchResult.processFunction(
      int argsLength, ExprMatchResult matchArg(int i)) {
    match = _processFunction(argsLength, matchArg);
  }

  bool _processFunction(int argsLength, ExprMatchResult matchArg(int i)) {
    for (var i = 0; i < argsLength; i++) {
      final result = matchArg(i);

      // If this argument does not match, terminate.
      if (!result.match) {
        return false;
      }

      // Check if any existing mappings would be violated by merging with
      // the mapping resulting from the argument match.
      for (final key in result.mapping.keys) {
        if (mapping.containsKey(key) && mapping[key] != result.mapping[key]) {
          // Violation: terminate.
          return false;
        }
      }

      // Merge argument mapping into this mapping.
      mapping.addAll(result.mapping);
    }
    return true;
  }
}
