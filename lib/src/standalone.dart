// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// All computable functions that are implemented by [StandaloneExprEngine].
enum ComputableExpr { add, subtract, multiply, divide, power, negate }

/// A standalone engine for handling expressions.
class StandaloneExprEngine {
  /// Default substitution character.
  static const dfltInnerExprLbl = '{}';

  /// Expr labels for all default computable functions.
  static const Map<String, ComputableExpr> _computableExprLabels = const {
    'add': ComputableExpr.add,
    'sub': ComputableExpr.subtract,
    'mul': ComputableExpr.multiply,
    'div': ComputableExpr.divide,
    'pow': ComputableExpr.power,
    'neg': ComputableExpr.negate
  };

  /// Printer expression dictionary.
  final printerDict = new Map<int, String>();

  /// Flag to enable the use of operator characters.
  bool printerOpChars = false;

  /// Implementation of [ExprResolve] that uses [_computableExprLabels] and
  /// [String.hashCode].
  int resolve(String name) {
    if (name == dfltInnerExprLbl) {
      // This expression label is reserved to represent expression ID 0, which
      // is used to reference the inner expression in substitutions.
      return 0;
    } else if (_computableExprLabels.containsKey(name)) {
      // Add 1 because 0 is a reserved expression ID.
      return _computableExprLabels[name].index + 1;
    } else {
      // In order to work with the default printer, we need to keep a dictionary
      // of all expression strings.
      printerDict[name.hashCode] = name;

      // Note that this value is computed different in dart2js and the Dart VM.
      return name.hashCode;
    }
  }

  /// Implementation of [ExprResolveName].
  String resolveName(int id) => printerDict[id];

  /// Implementation of [ExprCanCompute].
  bool canCompute(int id) {
    return id > 0 && id - 1 < ComputableExpr.values.length;
  }

  /// Default optimized implementation of [ExprCompute].
  num compute(int id, List<num> args) {
    assert(id > 0);
    // Note: subtract one because 0 is a reserved expression ID.
    if (id - 1 < ComputableExpr.values.length) {
      switch (ComputableExpr.values[id - 1]) {
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
        case ComputableExpr.negate:
          assert(args.length == 1);
          return -args[0];
        default:
          throw new Exception('this is 100% impossible');
      }
    } else {
      return null;
    }
  }

  /// Implementation of [ExprPrint].
  String print(Expr expr) {
    final generic = expr.isGeneric ? '?' : '';
    if (expr is NumberExpr) {
      return expr.value.toString();
    } else if (expr is SymbolExpr) {
      return '$generic${resolveName(expr.id)}';
    } else if (expr is FunctionExpr) {
      final id = expr.id;
      final args = expr.args;
      if (id - 1 < ComputableExpr.values.length) {
        switch (ComputableExpr.values[id - 1]) {
          case ComputableExpr.add:
            assert(args.length == 2);
            return printerOpChars
                ? '${args[0]} + ${args[1]}'
                : 'add(${args[0]}, ${args[1]})';
          case ComputableExpr.subtract:
            assert(args.length == 2);
            return printerOpChars
                ? '${args[0]} - ${args[1]}'
                : 'sub(${args[0]}, ${args[1]})';
          case ComputableExpr.multiply:
            assert(args.length == 2);
            return printerOpChars
                ? '{${args[0]}}*{${args[1]}}'
                : 'mul(${args[0]}, ${args[1]})';
          case ComputableExpr.divide:
            assert(args.length == 2);
            return printerOpChars
                ? '{${args[0]}}/{${args[1]}}'
                : 'div(${args[0]}, ${args[1]})';
          case ComputableExpr.power:
            assert(args.length == 2);
            return printerOpChars
                ? '{${args[0]}}^{${args[1]}}'
                : 'pow(${args[0]}, ${args[1]})';
          case ComputableExpr.negate:
            assert(args.length == 1);
            return printerOpChars ? '-{${args[0]}}' : 'neg(${args[0]})';
          default:
            throw new Exception('this is 100% impossible');
        }
      } else {
        return '$generic${resolveName(id)}(${args.join(', ')})';
      }
    } else {
      throw new ArgumentError(
          'expr type must be one of: NumberExpr, SymbolExpr, FunctionExpr');
    }
  }
}

final dfltExprEngine = new StandaloneExprEngine();

int standaloneResolve(String name) => dfltExprEngine.resolve(name);
String standaloneResolveName(int id) => dfltExprEngine.resolveName(id);
num standaloneCompute(int id, List<num> args) =>
    dfltExprEngine.compute(id, args);
bool standaloneCanCompute(int id) => dfltExprEngine.canCompute(id);
