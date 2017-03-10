// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

typedef num _Compute(List<num> args);

/// Item in [SimpleLabelResolver.printerDict]
class PrinterEntry {
  final String label;
  final bool generic;

  const PrinterEntry(this.label, this.generic);

  @override
  int get hashCode => jFinish(jCombine(label.hashCode, generic.hashCode));

  @override
  bool operator ==(other) =>
      other is PrinterEntry &&
      (other.label == label && other.generic == generic);
}

/// In-memory label resolver
class SimpleLabelResolver extends ExprContextLabelResolver {
  /// Default envelope self character.
  static const envelopeLbl = '{}';

  /// Expression ID offset (IDs between 0 and this offset can be assigned to
  /// special symbols/functions).
  final idOffset = 3;

  /// List of all labels (assigned ID is same List index + [idOffset]).
  final printerDict = new List<PrinterEntry>();

  @override
  int assignId(String label, bool generic) {
    if (label == envelopeLbl) {
      // This expression label is reserved to represent expression ID 0, which
      // is used to envelope the entire expression.
      return 0;
    } else {
      final entry = new PrinterEntry(label, generic);
      final idx = printerDict.indexOf(entry);
      if (idx != -1) {
        return idx + idOffset;
      } else {
        printerDict.add(entry);
        return printerDict.length - 1 + idOffset;
      }
    }
  }

  @override
  String getLabel(int id) {
    final idx = id - idOffset;
    if (idx >= 0 && idx < printerDict.length) {
      return printerDict[idx].label;
    } else {
      return null;
    }
  }
}

/// Standalone/in-memory context for parsing and printing expressions
class SimpleExprContext extends ExprContext {
  /// Operator configuration used by this backend.
  final operators = new OperatorConfig(1);

  /// Computable functions.
  final computable = new Map<int, _Compute>();

  SimpleExprContext(
      [ExprContextLabelResolver labelResolver,
      bool loadDefaultOperators = true])
      : super(labelResolver ?? new SimpleLabelResolver()) {
    // Load default operator configuration.
    if (loadDefaultOperators) {
      operators
        ..add(Associativity.ltr,
            argc: 2, lvl: 0, char: '=', id: assignId('=', false))
        ..add(Associativity.ltr,
            argc: 2, lvl: 1, char: '+', id: assignId('+', false))
        ..add(Associativity.ltr,
            argc: 2, lvl: 1, char: '-', id: assignId('-', false))
        ..add(Associativity.ltr,
            argc: 2, lvl: 2, char: '*', id: assignId('*', false))
        ..add(Associativity.ltr,
            argc: 2, lvl: 2, char: '/', id: assignId('/', false))
        ..add(Associativity.rtl,
            argc: 2, lvl: 3, char: '^', id: assignId('^', false))
        ..add(Associativity.rtl,
            argc: 1, lvl: 4, char: '~', id: assignId('~', false))
        ..add(Associativity.ltr,
            argc: 1, lvl: 5, char: '!', id: assignId('!', false))

        /// Implicit multiplication is set to right associativity by default so
        /// that expressions like these can be written: `a^2b` (which would
        /// otherwise be parsed as `(a^2)*b`).
        /// Increasing the precedence level is not an option, this would result
        /// in: `2a^b` => `(2*a)^b`.
        ..add(Associativity.rtl,
            argc: 2, lvl: 3, id: operators.implicitMultiplyId);
    }

    // Add computable functions.
    computable[operators.id('+')] = (args) => args[0] + args[1];
    computable[operators.id('-')] = (args) => args[0] - args[1];
    computable[operators.id('*')] = (args) => args[0] * args[1];
    computable[operators.id('/')] = (args) => args[0] / args[1];
    computable[operators.id('^')] = (args) => pow(args[0], args[1]);
    computable[operators.id('~')] = (args) => -args[0];
  }

  @override
  Expr parse(String str) => parseExpression(str, operators, assignId);

  @override
  Eq parseEq(String str) {
    final expr = parse(str);
    if (expr is FunctionExpr && expr.id == operators.id('=')) {
      assert(expr.args.length == 2);
      return new Eq(expr.args[0], expr.args[1]);
    } else {
      throw new EqLibException('no top level equation found');
    }
  }

  @override
  num compute(int id, List<num> args) {
    // Clean but less efficient implementation.
    if (computable.containsKey(id)) {
      assert(operators.idToArgc[id] == args.length);
      return computable[id](args);
    } else {
      return double.NAN;
    }
  }

  @override
  String str(dynamic input) {
    if (input is Expr) {
      final generic = input.isGeneric ? '?' : '';

      if (input is NumberExpr) {
        return input.value.toString();
      } else if (input is SymbolExpr) {
        return '$generic${getLabel(input.id)}';
      } else if (input is FunctionExpr) {
        final id = input.id;
        final args = input.args;
        final label = getLabel(id);

        if (operators.opChars.contains(label.codeUnitAt(0))) {
          assert(args.length == operators.idToArgc[id]);
          if (label == '~') {
            return _printOperator(null, args.first, id, '-');
          } else if (label == '!') {
            return _printOperator(args.first, null, id, label);
          } else {
            return _printOperator(args[0], args[1], id, label);
          }
        } else {
          return '$generic$label(${args.map((arg) => str(arg)).join(',')})';
        }
      } else {
        throw new ArgumentError(
            'unrecognized input expression: ${input.runtimeType}');
      }
    } else if (input is Eq) {
      return '${str(input.left)}=${str(input.right)}';
    } else {
      throw new ArgumentError('input must have type Expr or Eq');
    }
  }

  /// Generate operator funtion string representation using parentheses only
  /// when necessary.
  String _printOperator(Expr left, Expr right, int id, String opChar) {
    final pre = operators.idToPrecedence[id];
    final leftArg = _printOperatorArgument(left, pre, Associativity.rtl);
    final rightArg = _printOperatorArgument(right, pre, Associativity.ltr);
    return '$leftArg$opChar$rightArg';
  }

  /// Helper for [_printOperator].
  /// Important:
  /// - For left pass [Associativity.rtl] to [direction]
  /// - For right pass [Associativity.ltr] to [direction]
  String _printOperatorArgument(
      Expr arg, int parentPre, Associativity direction) {
    if (arg == null) {
      return '';
    }

    if (arg is FunctionExpr && operators.opIds.contains(arg.id)) {
      final id = arg.id;
      final ass = operators.idToAssociativity[id];
      final pre = operators.idToPrecedence[id];
      if (pre < parentPre || (pre == parentPre && ass == direction)) {
        return '(${str(arg)})';
      }
    }

    // Fallback.
    return str(arg);
  }
}
