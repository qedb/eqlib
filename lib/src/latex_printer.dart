// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.default_handlers;

/// Dictionary of expression strings and their LaTeX equivalent
final latexDict = new Map<String, String>();

/// Simple LaTeX printer.
String latexPrinter(num value, bool isNumeric, List<Object> args) {
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
          return '{${args[0]}}\\cdot {${args[1]}}';
        case ComputableExpr.divide:
          assert(args.length == 2);
          return '\\frac{${args[0]}}{${args[1]}}';
        default:
          throw new Exception('this is 100% impossible');
      }
    } else if (args.isEmpty) {
      final key = defaultPrinterDict[value];
      return '{${latexDict[key] ?? "\\text{$key}"}}';
    } else {
      return '\\text{${defaultPrinterDict[value]}}\\left(${args.join(', ')}\\right)';
    }
  }
}
