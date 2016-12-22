// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Parse an expression string.
Expr parseExpr(String str, [ExprResolve resolver = standaloneResolve]) {
  return _parseExprUnsafe(
      new W<String>(str.replaceAll(new RegExp(r'\s'), '')), resolver);
}

/// Parse an expression string that does not contain white spaces.
Expr _parseExprUnsafe(W<String> str, ExprResolve resolver) {
  // Get expression label.
  final lblre = new RegExp(r'([-?.{}a-z\d]+)');
  final match = lblre.matchAsPrefix(str.v);

  // If the label could not be parsed, throw an error.
  if (match == null) {
    throw new FormatException('wrong expression format: ${str.v}');
  }
  var label = match.group(1);

  // Remove label from string to continue parsing.
  str.v = str.v.substring(label.length);

  // Try to parse the label as numeric value.
  try {
    final value = num.parse(label);
    return new ExprNum(value);
  } on FormatException {}

  // Check if this is a generic expression.
  bool generic = false;
  if (label.startsWith('?')) {
    generic = true;
    label = label.substring(1);
  }

  // Resolve expression ID instead.
  final id = resolver(label);

  if (str.v.startsWith('(')) {
    final args = new List<Expr>();
    str.v = str.v.substring(1);
    while (!str.v.startsWith(')')) {
      args.add(_parseExprUnsafe(str, resolver));
      if (str.v.startsWith(',')) {
        str.v = str.v.substring(1);
      }
    }
    str.v = str.v.substring(1);
    return new ExprFun(id, args, generic);
  } else {
    return new ExprSym(id, generic);
  }
}
