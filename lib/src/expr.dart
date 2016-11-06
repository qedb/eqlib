// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Function that should resolve an expression string into an integer.
typedef int ExprResolve(String expr);

/// Function that should compute a numeric value for the given expression ID
/// and arguments.
typedef num ExprCompute(int expr, List<num> args);

/// Function that can lookup whether a given expression can be computed.
typedef bool ExprCanCompute(int expr);

/// String printing entry function.
typedef String ExprPrinter(num value, bool isNumeric, List<Expr> args);

/// Expression of a variable or function
class Expr {
  /// Expression value
  ///
  /// The expression value can either be interpreted as expression ID, or as
  /// numeric value, [isNumeric] indicates if the latter is the case.
  final num value;

  /// Indicates if [value] is numeric.
  final bool isNumeric;

  /// Function arguments (should not be null!).
  final List<Expr> args;

  Expr(this.value, this.isNumeric, this.args) {
    // No field may be null.
    assert(value != null && isNumeric != null && args != null);

    // If isNumeric is true, args must be empty.
    assert(!isNumeric || args.isEmpty);

    // If value has type double, isNumeric must be true.
    assert(!(value is double) || isNumeric);
  }

  /// Construct numeric expression.
  Expr.numeric(this.value)
      : isNumeric = true,
        args = [];

  /// Construct by parsing the given expression.
  factory Expr.parse(String str, [ExprResolve resolver = defaultResolver]) {
    return parseExpressionUnsafe(
        new W<String>(str.replaceAll(new RegExp(r'\s'), '')), resolver);
  }

  /// Construct from an [Expression] instance from the `math_expressions`
  /// package.
  factory Expr.fromMathExpressions(mexpr.Expression expr,
      [ExprResolve resolver = defaultResolver]) {
    return _exprFromMexpr(expr, resolver);
  }

  /// Create deep copy.
  Expr clone() {
    return new Expr(value, isNumeric,
        new List<Expr>.generate(args.length, (i) => args[i].clone()));
  }

  /// Compare to another expression.
  bool operator ==(other) {
    if (other is Expr && args.length == other.args.length) {
      for (var i = 0; i < args.length; i++) {
        if (args[i] != other.args[i]) {
          return false;
        }
      }
      return other.value == value && other.isNumeric == isNumeric;
    } else {
      return false;
    }
  }

  /// Get unique hash code for this expression.
  int get hashCode => hash3(value, isNumeric, hashObjects(args));

  /// Match another [superset] expression against this expression. All labels
  /// in [generic] are considered generic variables, meaning that these
  /// variables (provided there are 0 arguments), can be mapped to any
  /// expression.
  Map<int, Expr> matchSuperset(Expr superset, List<int> generic) {
    // Store if the superset is generic.
    final isGeneric = generic.contains(superset.value);

    // If this is numeric, the superset must be generic or match this value.
    if (isNumeric) {
      if (isGeneric || superset.isNumeric && superset.value == value) {
        final mapping = new Map<int, Expr>();
        mapping[superset.value] = this;
        return mapping;
      } else {
        return null;
      }
    }

    // If this is not numeric but the superset is, there is no match either.
    else if (!superset.isNumeric) {
      // If the superset is generic, it maps to this.
      if (isGeneric) {
        assert(superset.args.length == 0); // Generics should not have args.
        final mapping = new Map<int, Expr>();
        mapping[superset.value] = this;
        return mapping;
      }

      // If the superset expression ID is equal to this, and the number of
      // arguments is equal, both expressions could be compatible.
      else if (superset.value == value && superset.args.length == args.length) {
        final mapping = new Map<int, Expr>();
        for (var i = 0; i < args.length; i++) {
          // Check for each argument if it matches with the complementary
          // superset argument.
          final argMapping = args[i].matchSuperset(superset.args[i], generic);
          if (argMapping == null) {
            // If one argument mismatches, the superset is incompatible.
            return null;
          } else {
            // Check if any existing mappings would be violated by merging with
            // the mapping resulting from the argument match.
            for (final key in argMapping.keys) {
              if (mapping.containsKey(key) && mapping[key] != argMapping[key]) {
                // Violation: immediate termination
                return null;
              }
            }
            mapping.addAll(argMapping);
          }
        }
        return mapping;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  /// If this expression is in the [mapping] table, this will return the new
  /// expression. Else this will remap all arguments.
  /// This method creates a new expression instance.
  Expr remap(Map<int, Expr> mapping) {
    if (mapping.containsKey(value)) {
      return mapping[value].clone();
    } else {
      return new Expr(value, isNumeric,
          new List<Expr>.generate(args.length, (i) => args[i].remap(mapping)));
    }
  }

  /// Substitute the given [expression] and remap it using the provided
  /// [mapping] table. Returns an instance of [Expr] where the equation is
  /// substituted.
  Expr _subs(Expr expression, Map<int, Expr> mapping) {
    // If the equation replacement is in the mapping table, use it and return.
    if (mapping.containsKey(expression.value)) {
      return mapping[expression.value];
    } else {
      return new Expr(
          expression.value,
          expression.isNumeric,
          new List<Expr>.generate(expression.args.length,
              (i) => expression.args[i].remap(mapping)));
    }
  }

  /// Substitute the given [equation] at the given superset [index].
  /// Returns an instance of [Expr] where the equation is substituted.
  /// Never returns null, instead returns itself if nothing is substituted.
  Expr subs(Eq equation, List<int> generic, W<int> index) {
    // Try to map to this expression.
    final mapping = matchSuperset(equation.left, generic);
    if (mapping != null) {
      // Decrement index.
      index.v--;

      // If the index was 0, it is now -1 due to the prevous decrement. In that
      // case we have to execute the substitution on this expression.
      if (index.v == -1) {
        return _subs(equation.right, mapping);
      }
    }

    // Iterate through arguments, and try to substitute the equation there.
    for (var i = 0; i < args.length; i++) {
      args[i] = args[i].subs(equation, generic, index);
      if (index.v == -1) {
        // This indicates the substitution position has been found, which means
        // we can break this loop.
        break;
      }
    }

    return this;
  }

  /// Compute numeric expressions.
  num eval(ExprCanCompute canCompute, ExprCompute computer) {
    // Check if this expression is numeric, in this case, return the numeric
    // value.
    if (isNumeric) {
      return value;
    }

    // Check if there is a resolver for this expression.
    else if (canCompute(value)) {
      var numArgs = new List<num>(args.length);

      // Collect all arguments as numeric values.
      for (var i = 0; i < args.length; i++) {
        // Try to resolve argument to a number.
        num value = args[i].eval(canCompute, computer);
        if (value == null) {
          numArgs = null;
        } else {
          if (numArgs != null) {
            numArgs[i] = value;
          }

          // Replace argument with numeric value.
          // TODO: this is a violation of the all fields final principle.
          args[i] = new Expr.numeric(value);
        }
      }

      // Return numeric expression with the numeric value, or null if it is not
      // possible to compute a numeric value.
      if (numArgs != null) {
        return computer(value, numArgs);
      } else {
        return null;
      }
    } else {
      // Return null, indicating that this expression cannot be resolved to a
      // numeric value.
      return null;
    }
  }

  /// Global string printer function.
  static ExprPrinter stringPrinter = defaultPrinter;

  /// Generate string representation.
  String toString() => stringPrinter(value, isNumeric, args);

  /// Add other expression.
  Expr operator +(other) => add(this, other);

  /// Subtract other expression.
  Expr operator -(other) => sub(this, other);

  /// Multiply with other expression.
  Expr operator *(other) => mul(this, other);

  /// Divide by other expression.
  Expr operator /(other) => div(this, other);
}
