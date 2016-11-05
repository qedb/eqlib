// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Parse an expression string that does not contain white spaces.
Expr parseExpressionUnsafe(W<String> str, ExprResolve resolver) {
  // Get expression label.
  final lblre = new RegExp(r'([-.%a-z\d]+)');
  final label = lblre.matchAsPrefix(str.v).group(1);

  // Try to parse the label as numeric value.
  num value;
  bool isNumeric;
  try {
    value = num.parse(label);
    isNumeric = true;
  } on FormatException {
    // Use expression resolver to get an expression ID.
    value = resolver(label);
    isNumeric = false;
  }

  // Remove label from string to continue parsing.
  str.v = str.v.substring(label.length);
  if (str.v.startsWith('(')) {
    final args = new List<Expr>();
    str.v = str.v.substring(1);
    while (!str.v.startsWith(')')) {
      args.add(parseExpressionUnsafe(str, resolver));
      if (str.v.startsWith(',')) {
        str.v = str.v.substring(1);
      }
    }
    str.v = str.v.substring(1);
    return new Expr(value, isNumeric, args);
  } else {
    return new Expr(value, isNumeric, []);
  }
}
