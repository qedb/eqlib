// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

// Expression of a variable or function
class Expr {
  /// Label
  String label;

  /// Arguments (for functions)
  var args = new List<Expr>();

  Expr();

  /// Construct from the given label and arguments.
  Expr.from(this.label, this.args);

  /// Construct by parsing the given expression.
  factory Expr.parse(String str) {
    return new Expr()..parseUnsafe(str.replaceAll(' ', ''));
  }

  /// Parse an expression string.
  /// Note: the given string should not contain white spaces.
  String parseUnsafe(String str) {
    final lblre = new RegExp('([-.%a-z0-9]+)');
    label = lblre.matchAsPrefix(str).group(1);
    str = str.substring(label.length);
    if (str.startsWith('(')) {
      str = str.substring(1);
      while (!str.startsWith(')')) {
        args.add(new Expr());
        str = args.last.parseUnsafe(str);
        if (str.startsWith(',')) {
          str = str.substring(1);
        }
      }
      str = str.substring(1);
      return str;
    } else {
      return str;
    }
  }

  /// Create deep copy.
  Expr clone() {
    return new Expr.from(
        label, new List<Expr>.generate(args.length, (i) => args[i].clone()));
  }

  /// Compare to another expression.
  bool operator ==(other) {
    if (other is Expr && args.length == other.args.length) {
      for (var i = 0; i < args.length; i++) {
        if (args[i] != other.args[i]) {
          return false;
        }
      }
      return other.label == label;
    } else {
      return false;
    }
  }

  /// Get unique hash code for this expression.
  int get hashCode => hash2(label, hashObjects(args));

  /// Match another [superset] expression against this expression. All labels
  /// in [generic] are considered generic variables, meaning that these
  /// variables (provided there are 0 arguments), can be mapped to any
  /// expression.
  Map<String, Expr> matchSuperset(Expr superset, List<String> generic) {
    // If the superset has no args, it is compatible.
    // Else, the label has to be the same and all arguments must match.
    if ((generic.contains(superset.label) || superset.label == label) &&
        superset.args.isEmpty) {
      return {superset.label: this};
    } else if (superset.label == label && superset.args.length == args.length) {
      final mapping = new Map<String, Expr>();
      for (var i = 0; i < args.length; i++) {
        final m = args[i].matchSuperset(superset.args[i], generic);
        if (m == null) {
          return null;
        } else {
          // Check if any existing mappings would be violated.
          for (final key in m.keys) {
            if (mapping.containsKey(key) && mapping[key] != m[key]) {
              // Violation: immediate termination
              return null;
            }
          }
          mapping.addAll(m);
        }
      }
      return mapping;
    }
    return null;
  }

  /// If this expression is in the [mapping] table, this will return the new
  /// expression. Else this will remap all arguments.
  /// This method creates a new expression instance.
  Expr remap(Map<String, Expr> mapping) {
    if (mapping.containsKey(label)) {
      return mapping[label].clone();
    } else {
      return new Expr.from(label,
          new List<Expr>.generate(args.length, (i) => args[i].remap(mapping)));
    }
  }

  /// Replace the data by the data from another expression.
  void _replace(Expr other) {
    label = other.label;
    args.clear();
    for (final arg in other.args) {
      args.add(arg.clone());
    }
  }

  /// Forced substitute the given [equation] right hand side and remap it using
  /// the provided [mapping] table.
  void _sub(Eq equation, Map<String, Expr> mapping) {
    // If the equation replacement is in the mapping table, use it and return.
    if (mapping.containsKey(equation.r.label)) {
      _replace(mapping[equation.r.label]);
    } else {
      label = equation.r.label;
      args.clear();
      // Copy all arguments
      for (final arg in equation.r.args) {
        args.add(arg.remap(mapping));
      }
    }
  }

  /// Substitute the given [equation] at the given superset [index].
  int sub(Eq equation, List<String> generic, int index) {
    // Try to map to this expression.
    final mapping = matchSuperset(equation.l, generic);
    if (mapping != null) {
      // If the index is 0, execute the substitution on this expression.
      if (index == 0) {
        _sub(equation, mapping);
        return -1;
      } else {
        index--;
      }
    }

    // Iterate through arguments, and try to substitute the equation there.
    for (final expr in args) {
      index = expr.sub(equation, generic, index);
      if (index == -1) {
        return -1;
      }
    }

    return index;
  }

  /// Check if this expression is numeric.
  /// TODO: clearner and more efficient approach.
  bool get isNumeric => args.isEmpty && num.parse(label, (_) => null) != null;

  /// Compute numeric expressions.
  num compute(ExprResolver resolver) {
    // Check if this expression is numeric, in this case, return the numeric value.
    if (isNumeric) {
      return num.parse(label);
    }

    // Check if there is a resolver for this expression.
    else if (resolver.canResolve(label)) {
      var numArgs = new List<num>(args.length);

      // Collect all arguments as numeric values.
      for (var i = 0; i < args.length; i++) {
        // Try to resolve argument to a number.
        num value = args[i].compute(resolver);
        if (value == null) {
          numArgs = null;
        } else {
          numArgs[i] = value;

          // Replace argument with numeric value.
          args[i] = new Expr.from(value.toString(), []);
        }
      }

      // Return numeric expression with the numeric value, or null if it is not
      // possible to compute a numeric value.
      if (numArgs != null) {
        return resolver.resolve(label, numArgs);
      } else {
        return null;
      }
    } else {
      // Return null, indicating that this expression cannot be resolved to a
      // numeric value.
      return null;
    }
  }

  /// Generate string representation.
  String toString() => args.isEmpty ? label : '$label(${args.join(',')})';
}
