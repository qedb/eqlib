// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

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

/// A standalone/in-memory context for parsing and printing expressions.
class DefaultExprContext {
  /// Default envelope self character.
  static const envelopeLbl = '{}';

  /// Expression ID offset (IDs between 0 and this offset can be assigned to
  /// special symbols/functions).
  final idOffset = 3;

  /// List of all labels (assigned ID is same List index + [idOffset]).
  final printerDict = new List<PrinterEntry>();

  /// Operator configuration used by this backend.
  final operators = new OperatorConfig(1);

  DefaultExprContext() {
    // Load default operator configuration.
    operators.add(Associativity.ltr,
        argc: 2, lvl: 1, char: '+', id: assignId('+', false));
    operators.add(Associativity.ltr,
        argc: 2, lvl: 1, char: '-', id: assignId('-', false));
    operators.add(Associativity.ltr,
        argc: 2, lvl: 2, char: '*', id: assignId('*', false));
    operators.add(Associativity.ltr,
        argc: 2, lvl: 2, char: '/', id: assignId('/', false));
    operators.add(Associativity.rtl,
        argc: 2, lvl: 3, char: '^', id: assignId('^', false));

    /// Implicit multiplication is set to right associativity by default so that
    /// expressions like these can be written: `a^2b` (which would otherwise be
    /// parsed as `(a^2)*b`).
    /// Increasing the precedence level is not an option, this would result in:
    /// `2a^b` => `(2*a)^b`.
    operators.add(Associativity.rtl,
        argc: 2, lvl: 3, id: operators.implicitMultiplyId);

    // Negation.
    operators.add(Associativity.rtl,
        argc: 1, lvl: 4, char: '~', id: assignId('~', false));
  }

  /// Implementation of [ExprAssignId].
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

  /// Implementation of [ExprGetLabel].
  String getLabel(int id) {
    final idx = id - idOffset;
    if (idx >= 0 && idx < printerDict.length) {
      return printerDict[idx].label;
    } else {
      return null;
    }
  }

  /// Default implementation of [ExprCompute].
  num compute(int id, List<num> args) {
    // Clean but less efficient implementation.
    if (id == operators.id('+')) {
      assert(args.length == 2);
      return args[0] + args[1];
    } else if (id == operators.id('-')) {
      assert(args.length == 2);
      return args[0] - args[1];
    } else if (id == operators.id('*')) {
      assert(args.length == 2);
      return args[0] * args[1];
    } else if (id == operators.id('/')) {
      assert(args.length == 2);
      return args[0] / args[1];
    } else if (id == operators.id('^')) {
      assert(args.length == 2);
      return pow(args[0], args[1]);
    } else if (id == operators.id('~')) {
      assert(args.length == 1);
      return -args[0];
    } else {
      return double.NAN;
    }
  }

  /// Implementation of [ExprToString].
  String print(Expr expr) {
    final generic = expr.isGeneric ? '?' : '';

    if (expr is NumberExpr) {
      return expr.value.toString();
    } else if (expr is SymbolExpr) {
      return '$generic${getLabel(expr.id)}';
    } else if (expr is FunctionExpr) {
      final id = expr.id;
      final args = expr.args;
      final label = getLabel(id);

      if (operators.opChars.contains(label.codeUnitAt(0))) {
        assert(args.length == operators.idToArgc[id]);
        if (label == '~') {
          return _printOperator(null, args.first, id, '-');
        } else {
          return _printOperator(args[0], args[1], id, label);
        }
      } else {
        return '$generic$label(${args.join(',')})';
      }
    } else {
      throw new ArgumentError(
          'expr type must be one of: NumberExpr, SymbolExpr, FunctionExpr');
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
        return '($arg)';
      }
    }

    // Fallback.
    return '$arg';
  }
}
