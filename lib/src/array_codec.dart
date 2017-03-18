// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expr types.
const _exprArrayTypeInteger = 1;
const _exprArrayTypeSymbol = 2;
const _exprArrayTypeSymbolGen = 3;
const _exprArrayTypeFunction = 4;
const _exprArrayTypeFunctionGen = 5;

/// Convert [Expr] to array of integers.
List<int> encodeExprArray(Expr input) {
  final data = new List<int>();
  _encodeExprArray(input, data);
  return data;
}

void _encodeExprArray(Expr input, List<int> target) {
  if (input is NumberExpr) {
    if (input.value is int) {
      target.add(_exprArrayTypeInteger);
      target.add(input.value);
    } else {
      throw new ArgumentError(
          'NumberExpr must be an integer for array encoding');
    }
  } else if (input is SymbolExpr) {
    target
        .add(input.isGeneric ? _exprArrayTypeSymbolGen : _exprArrayTypeSymbol);
    target.add(input.id);
  } else if (input is FunctionExpr) {
    target.add(
        input.isGeneric ? _exprArrayTypeFunctionGen : _exprArrayTypeFunction);
    target.add(input.id);

    // Add arguments.
    target.add(input.args.length);
    target.add(0); // This element will be used to store the content length.
    final startLength = target.length;
    for (final arg in input.args) {
      _encodeExprArray(arg, target);
    }
    // Store final content length.
    target[startLength - 1] = target.length - startLength;
  }
}

/// Convert array of integers to [Expr].
Expr decodeExprArray(List<int> input) {
  return _decodeExprArray(input, new W<int>(0));
}

Expr _decodeExprArray(List<int> input, W<int> ptr) {
  final type = input[ptr.v];
  ptr.v++;
  if (type == _exprArrayTypeInteger) {
    final value = input[ptr.v];
    ptr.v++;
    return new NumberExpr(value);
  } else {
    final id = input[ptr.v];
    final generic =
        type == _exprArrayTypeSymbolGen || type == _exprArrayTypeFunctionGen;
    ptr.v++;

    if (type < _exprArrayTypeFunction) {
      return new SymbolExpr(id, generic);
    } else {
      var argc = input[ptr.v];
      final args = new List<Expr>();
      ptr.v += 2; // Jump over argument count and full content length.
      while (argc > 0) {
        args.add(_decodeExprArray(input, ptr));
        argc--;
      }
      return new FunctionExpr(id, generic, args);
    }
  }
}
