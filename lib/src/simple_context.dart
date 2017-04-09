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
  int get hashCode => jPostprocess(jMix(label.hashCode, generic.hashCode));

  @override
  bool operator ==(other) =>
      other is PrinterEntry &&
      (other.label == label && other.generic == generic);
}

/// In-memory label resolver
class SimpleLabelResolver extends ExprContextLabelResolver {
  /// Expression ID offset (IDs between 0 and this offset can be assigned to
  /// special symbols/functions).
  final idOffset = 3;

  /// List of all labels (assigned ID is same List index + [idOffset]).
  final printerDict = new List<PrinterEntry>();

  @override
  int assignId(String label, bool generic) {
    final entry = new PrinterEntry(label, generic);
    final idx = printerDict.indexOf(entry);
    if (idx != -1) {
      return idx + idOffset;
    } else {
      printerDict.add(entry);
      return printerDict.length - 1 + idOffset;
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
        ..add(new Operator(assignId('=', false), 0, Associativity.ltr,
            char('='), OperatorType.infix))
        ..add(new Operator(assignId('+', false), 1, Associativity.ltr,
            char('+'), OperatorType.infix))
        ..add(new Operator(assignId('-', false), 1, Associativity.ltr,
            char('-'), OperatorType.infix))
        ..add(new Operator(assignId('*', false), 2, Associativity.ltr,
            char('*'), OperatorType.infix))
        ..add(new Operator(assignId('/', false), 2, Associativity.ltr,
            char('/'), OperatorType.infix))
        ..add(new Operator(assignId('^', false), 3, Associativity.rtl,
            char('^'), OperatorType.infix))
        ..add(new Operator(assignId('~', false), 4, Associativity.rtl,
            char('~'), OperatorType.prefix))
        ..add(new Operator(assignId('!', false), 5, Associativity.ltr,
            char('!'), OperatorType.postfix))

        /// Implicit multiplication is set to right associativity by default so
        /// that expressions like these can be written: `a^2b` (which would
        /// otherwise be parsed as `(a^2)*b`).
        /// Increasing the precedence level is not an option, this would result
        /// in: `2a^b` => `(2*a)^b`.
        ..add(new Operator(operators.implicitMultiplyId, 3, Associativity.rtl,
            -1, OperatorType.infix));
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

  Rule toRule(Expr expr) {
    if (expr is FunctionExpr && expr.id == operators.id('=')) {
      assert(expr.arguments.length == 2);
      return new Rule(expr.arguments[0], expr.arguments[1]);
    } else {
      throw new EqLibException('expr is not an equation');
    }
  }

  @override
  Rule parseRule(String str) => toRule(parse(str));

  @override
  num compute(int id, List<num> args) {
    // Clean but less efficient implementation.
    if (computable.containsKey(id)) {
      return computable[id](args);
    } else {
      return double.NAN;
    }
  }

  @override
  String str(Expr input) {
    final generic = input.isGeneric ? '?' : '';

    if (input is NumberExpr) {
      return input.value.toString();
    } else if (input is FunctionExpr) {
      final id = input.id;
      final args = input.arguments;
      var label = getLabel(id);

      if (input.isSymbol) {
        return '$generic$label';
      }

      // We prefer using '-' for negation.
      if (label == '~') {
        label = '-';
      }

      if (operators.byId.containsKey(id)) {
        final op = operators.byId[id];
        switch (op.operatorType) {
          case OperatorType.prefix: // null operator arg
            return _printOperator(null, args.first, id, label);
          case OperatorType.postfix: // arg operator null
            return _printOperator(args.first, null, id, label);
          default: // infix
            return _printOperator(args[0], args[1], id, label);
        }
      } else {
        return '$generic$label(${args.map((arg) => str(arg)).join(',')})';
      }
    } else {
      throw unsupportedType('input', input, ['NumberExpr', 'FunctionExpr']);
    }
  }

  /// Generate operator funtion string representation using parentheses only
  /// when necessary.
  String _printOperator(Expr left, Expr right, int id, String opChar) {
    final pre = operators.byId[id].precedenceLevel;
    final leftArg = left == null
        ? ''
        : formatExplicitParentheses(
            '(', ')', left, str(left), pre, Associativity.rtl, operators);
    final rightArg = right == null
        ? ''
        : formatExplicitParentheses(
            '(', ')', right, str(right), pre, Associativity.ltr, operators);

    return '$leftArg$opChar$rightArg';
  }

  /// Generic helper for handling parentheses with operators.
  /// Also used by LaTeXPrinter from the latex library.
  ///
  /// [direction]:
  /// - For left side pass [Associativity.rtl]
  /// - For right side pass [Associativity.ltr]
  static String formatExplicitParentheses(
      String leftP,
      String rightP,
      Expr arg,
      String inner,
      int parentPre,
      Associativity direction,
      OperatorConfig operators) {
    if (arg is FunctionExpr && operators.byId.containsKey(arg.id)) {
      final op = operators.byId[arg.id];
      final ass = op.associativity;
      final pre = op.precedenceLevel;
      if (pre < parentPre || (pre == parentPre && ass == direction)) {
        return '$leftP$inner$rightP';
      }
    }

    // Fallback.
    return inner;
  }
}
