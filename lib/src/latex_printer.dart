// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex_printer;

/// Dictionary of expression strings and their LaTeX equivalent
final Map<String, String> defaultLatexPrinterDict = new Map<String, String>();

/// Check if the given expression ID requires parenthesis in LaTeX.
bool _useParenthesis(int value) => value - 1 < ComputableExpr.values.length;

/// Simple LaTeX printer.
String defaultLatexPrinter(num value, bool isNumeric, List<Expr> args) {
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
          return [
            '${_useParenthesis(args[0].value) ? "\\left(${args[0]}\\right)" : args[0]}',
            '\\cdot',
            '${_useParenthesis(args[1].value) ? "\\left(${args[1]}\\right)" : args[1]}'
          ].join();
        case ComputableExpr.divide:
          assert(args.length == 2);
          return '\\frac{${args[0]}}{${args[1]}}';
        case ComputableExpr.power:
          assert(args.length == 2);
          return [
            '${_useParenthesis(args[0].value) ? "\\left(${args[0]}\\right)" : args[0]}',
            '^{${args[1]}}'
          ].join();
        default:
          throw new Exception('this is 100% impossible');
      }
    } else if (args.isEmpty) {
      /// TODO: more flexible implementation (name resolver function).
      final key = standalonePrinterDict[value];
      return '{${defaultLatexPrinterDict[key] ?? "\\text{$key}"}}';
    } else {
      return '\\text{${standalonePrinterDict[value]}}\\left(${args.join(', ')}\\right)';
    }
  }
}
