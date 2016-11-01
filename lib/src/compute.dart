// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.compute;

/// All computable functions that are implemented by default.
enum ComputableExpr { add, subtract, multiply, divide }

/// Expr labels for all default computable functions.
const Map<String, ComputableExpr> defaultExprLabels = const {
  'add': ComputableExpr.add,
  'sub': ComputableExpr.subtract,
  'mul': ComputableExpr.multiply,
  'div': ComputableExpr.divide,
};

/// Printer expression dictionary.
final defaultPrinterDict = new Map<int, String>();

/// Default implementation of [ExprPrinter].
String defaultPrinter(num value, bool isNumeric, List<Object> args) {
  if (isNumeric) {
    return value.toString();
  } else {
    assert(value is int);
    if (value - 1 < ComputableExpr.values.length) {
      switch (ComputableExpr.values[value - 1]) {
        case ComputableExpr.add:
          assert(args.length == 2);
          return '${args[0]} + ${args[1]}';
        case ComputableExpr.subtract:
          assert(args.length == 2);
          return '${args[0]} - ${args[1]}';
        case ComputableExpr.multiply:
          assert(args.length == 2);
          return '{${args[0]}}*{${args[1]}}';
        case ComputableExpr.divide:
          assert(args.length == 2);
          return '{${args[0]}}/{${args[1]}}';
        default:
          throw new Exception('this is 100% impossible');
      }
    } else if (args.isEmpty) {
      return '${defaultPrinterDict[value]}';
    } else {
      return '${defaultPrinterDict[value]}(${args.join(',')})';
    }
  }
}

/// Default implementation of [ExprResolve] that uses [defaultExprLabels] and
/// [String.hashCode].
int defaultResolver(String expr) {
  if (expr == '%') {
    // % is reserved to represent expression code 0, which is used for
    // substitutions.
    return 0;
  } else if (defaultExprLabels.containsKey(expr)) {
    // Add 1 because 0 is a reserved expression code.
    return defaultExprLabels[expr].index + 1;
  } else {
    // In order to work with the default printer, we need to keep a dictionary
    // of all expression strings.
    defaultPrinterDict[expr.hashCode] = expr;

    // Note that this value is computed differently in dart2js compared to the
    // Dart VM.
    return expr.hashCode;
  }
}

/// Default implementation of [ExprCanCompute].
bool defaultCanCompute(int expr) {
  return expr > 0 && expr - 1 < ComputableExpr.values.length;
}

/// Default optimized implementation of [ExprCompute]. This implementation
/// assumes you are using the [_defaultResolver].
num defaultCompute(int expr, List<num> args) {
  assert(expr > 0);
  // Note: subtract one because 0 is a reserved expression code.
  if (expr - 1 < ComputableExpr.values.length) {
    switch (ComputableExpr.values[expr - 1]) {
      case ComputableExpr.add:
        assert(args.length == 2);
        return args[0] + args[1];
      case ComputableExpr.subtract:
        assert(args.length == 2);
        return args[0] - args[1];
      case ComputableExpr.multiply:
        assert(args.length == 2);
        return args[0] * args[1];
      case ComputableExpr.divide:
        assert(args.length == 2);
        return args[0] / args[1];
      default:
        throw new Exception('this is 100% impossible');
    }
  } else {
    return null;
  }
}
