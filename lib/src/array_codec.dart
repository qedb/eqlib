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

/// Returns hash of encoded object.
///
/// Array codec format for integers and 0-argument functions (symbols):
/// `[$HASH, $TYPE, $VALUE]`
///
/// Array codec format for >0 arguments functions:
/// `[$HASH, $TYPE, $VALUE, $ARGC, $SIZE, ...children...]`
///
/// The hash is computed using the jenkins one-at-a-time hash. The hash input
/// are the type and value. In the case of functions the hash of each argument
/// is also added as input for the function hash.
///
/// The hash is shifted one place to the left and masked within the Dart smi
/// (small integer) range: 0x3fffffff. In the case of integers the first bit is
/// set. This way the integer value can later be reconstructed easily from the
/// hash.
int _encodeExprArray(Expr input, List<int> target) {
  if (input is NumberExpr) {
    final value = input.value;
    if (value is int) {
      final data = [_exprArrayTypeInteger, value];
      final hash = ((value << 1) & 0x3fffffff) | 0x1;
      target.add(hash);
      target.addAll(data);
      return hash;
    } else {
      throw new ArgumentError(
          'NumberExpr must be an integer for array encoding');
    }
  } else if (input is FunctionExpr) {
    if (input.isSymbol) {
      final data = [
        input.isGeneric ? _exprArrayTypeSymbolGen : _exprArrayTypeSymbol,
        input.id
      ];
      var hash = hashObjects(data);
      hash = (hash << 1) & 0x3fffffff;
      target.add(hash);
      target.addAll(data);
      return hash;
    } else {
      final firstIndex = target.length;
      var hash = 0;

      final type =
          input.isGeneric ? _exprArrayTypeFunctionGen : _exprArrayTypeFunction;
      target.add(0);
      target.add(type);
      target.add(input.id);
      hash = jMix(hash, type);
      hash = jMix(hash, input.id);

      // Add arguments.
      target.add(input.arguments.length);
      target.add(0); // This element will be used to store the content length.
      for (final arg in input.arguments) {
        hash = jMix(hash, _encodeExprArray(arg, target));
      }

      // Store final content length.
      target[firstIndex + 4] = target.length - firstIndex - 5;

      // Compute and store hash.
      hash = jPostprocess(hash);
      hash = (hash << 1) & 0x3fffffff;
      target[firstIndex] = hash;

      return hash;
    }
  } else {
    return -1;
  }
}

/// Convert array of integers to [Expr].
Expr decodeExprArray(List<int> input) {
  return _decodeExprArray(input, new W<int>(0));
}

Expr _decodeExprArray(List<int> input, W<int> ptr) {
  ptr.v++; // Jump over hash.
  final type = input[ptr.v++];
  if (type == _exprArrayTypeInteger) {
    final value = input[ptr.v++];
    return new NumberExpr(value);
  } else {
    final id = input[ptr.v++];
    final generic =
        type == _exprArrayTypeSymbolGen || type == _exprArrayTypeFunctionGen;

    if (type < _exprArrayTypeFunction) {
      return new FunctionExpr(id, generic, []);
    } else {
      var argc = input[ptr.v++];
      final args = new List<Expr>();
      ptr.v++; // Jump over content length.
      while (argc > 0) {
        args.add(_decodeExprArray(input, ptr));
        argc--;
      }
      return new FunctionExpr(id, generic, args);
    }
  }
}
