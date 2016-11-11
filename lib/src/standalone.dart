// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

/// TODO: wrapping class for all functions?
part of eqlib.standalone;

/// Default substitution character.
const dfltInnerExprLbl = '{}';

/// All computable functions that are implemented by standalone handlers.
enum ComputableExpr { add, subtract, multiply, divide, power }

/// Expr labels for all default computable functions.
const Map<String, ComputableExpr> _computableExprLabels = const {
  'add': ComputableExpr.add,
  'sub': ComputableExpr.subtract,
  'mul': ComputableExpr.multiply,
  'div': ComputableExpr.divide,
  'pow': ComputableExpr.power
};

/// Printer expression dictionary.
final standalonePrinterDict = new Map<int, String>();

/// Flag for [standalonePrinter] to enable the use of operator characters.
bool standalonePrinterOpChars = false;

/// Standalone implementation of [ExprPrinter].
String standalonePrinter(num value, bool isNumeric, List<Object> args) {
  if (isNumeric) {
    return value.toString();
  } else {
    assert(value is int);
    if (value - 1 < ComputableExpr.values.length) {
      switch (ComputableExpr.values[value - 1]) {
        case ComputableExpr.add:
          assert(args.length == 2);
          return standalonePrinterOpChars
              ? '${args[0]} + ${args[1]}'
              : 'add(${args[0]}, ${args[1]})';
        case ComputableExpr.subtract:
          assert(args.length == 2);
          return standalonePrinterOpChars
              ? '${args[0]} - ${args[1]}'
              : 'sub(${args[0]}, ${args[1]})';
        case ComputableExpr.multiply:
          assert(args.length == 2);
          return standalonePrinterOpChars
              ? '{${args[0]}}*{${args[1]}}'
              : 'mul(${args[0]}, ${args[1]})';
        case ComputableExpr.divide:
          assert(args.length == 2);
          return standalonePrinterOpChars
              ? '{${args[0]}}/{${args[1]}}'
              : 'div(${args[0]}, ${args[1]})';
        case ComputableExpr.power:
          assert(args.length == 2);
          return standalonePrinterOpChars
              ? '{${args[0]}}^{${args[1]}}'
              : 'pow(${args[0]}, ${args[1]})';
        default:
          throw new Exception('this is 100% impossible');
      }
    } else if (args.isEmpty) {
      return '${standalonePrinterDict[value]}';
    } else {
      return '${standalonePrinterDict[value]}(${args.join(', ')})';
    }
  }
}

/// Standalone implementation of [ExprResolve] that uses [defaultExprLabels] and
/// [String.hashCode].
int standaloneResolver(String expr) {
  if (expr == dfltInnerExprLbl) {
    // This expression label is reserved to represent expression ID 0, which is
    // used to reference the inner expression in substitutions.
    return 0;
  } else if (_computableExprLabels.containsKey(expr)) {
    // Add 1 because 0 is a reserved expression ID.
    return _computableExprLabels[expr].index + 1;
  } else {
    // In order to work with the default printer, we need to keep a dictionary
    // of all expression strings.
    standalonePrinterDict[expr.hashCode] = expr;

    // Note that this value is computed different in dart2js and the Dart VM.
    return expr.hashCode;
  }
}

/// Standalone implementation of [ExprCanCompute].
bool standaloneCanCompute(int expr) {
  return expr > 0 && expr - 1 < ComputableExpr.values.length;
}

/// Default optimized implementation of [ExprCompute]. This implementation
/// assumes you are using the [_standaloneResolver].
num standaloneCompute(int expr, List<num> args) {
  assert(expr > 0);
  // Note: subtract one because 0 is a reserved expression ID.
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
      case ComputableExpr.power:
        assert(args.length == 2);
        return pow(args[0], args[1]);
      default:
        throw new Exception('this is 100% impossible');
    }
  } else {
    return null;
  }
}
