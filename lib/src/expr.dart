// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression of a variable or function
///
/// Note: in this class we use some excessive OOP in order to obtain a nice
/// expression API.
abstract class Expr {
  Expr();

  /// Construct from binary data.
  factory Expr.fromBinary(ByteBuffer buffer) {
    final data = new ExprCodecData.decodeHeader(buffer);
    return exprCodecDecode(data);
  }

  /// Construct from Base64 string.
  factory Expr.fromBase64(String base64) =>
      new Expr.fromBinary(new Uint8List.fromList(BASE64.decode(base64)).buffer);

  /// Construct from integer array.
  factory Expr.fromArray(List<int> input) => decodeExprArray(input);

  /// Transform the given value into an expression if it is not an expression
  /// already.
  factory Expr.from(dynamic value) {
    if (value is Expr) {
      return value;
    } else if (value is num) {
      return new NumberExpr(value);
    } else {
      throw unsupportedType('value', value, ['Expr', 'num']);
    }
  }

  /// Write binary data.
  ByteBuffer toBinary() => exprCodecEncode(this).writeToBuffer();

  /// Write Base64 string.
  String toBase64() => BASE64.encode(toBinary().asUint8List());

  /// Write integer array.
  List<int> toArray() => encodeExprArray(this);

  /// Create deep copy.
  Expr clone();

  static Expr staticClone(Expr input) => input.clone();

  /// Compare to other expression.
  bool equals(Expr other);

  @override
  bool operator ==(dynamic other) => other is Expr && equals(other);

  /// Get expression hash (used by [hashCode])
  int get expressionHash;

  @override
  int get hashCode => expressionHash;

  /// Returns if this is a generic expression.
  bool get isGeneric;

  /// Pattern matching
  ///
  /// Match another [pattern] expression against this expression.
  bool compare(Expr pattern, [ExprMapping mapping]) {
    final theMapping = mapping ?? new ExprMapping();
    final result = _compare(pattern, theMapping);
    theMapping.finalize();
    return result;
  }

  /// Should never be called directly.
  bool _compare(Expr pattern, ExprMapping data) => false;

  /// Expression remapping
  ///
  /// This method always returns a new expression instance (deep cody).
  Expr remap(ExprMapping mapping);

  /// Substitute the given [equation] at the given pattern [index].
  /// Returns a new instance of [Expr] if the equation is substituted.
  /// Never returns null, instead returns itself if nothing is substituted.
  Expr substituteInternal(Eq equation, W<int> index);

  /// Wrapper around [substituteInternal].
  Expr substitute(Eq equation, [int index = 0]) =>
      substituteInternal(equation, new W<int>(index));

  /// Substitute all occurences of [equation].
  Expr substituteAll(Eq equation) {
    var expr = this;
    final index = new W<int>(1);
    while (index.v != 0) {
      index.v = 0;
      expr = expr.substituteInternal(equation, index);
    }
    return expr;
  }

  /// Recursive substitution.
  Expr substituteRecursivly(Eq equation, Eq terminator, ExprCompute compute,
      [int maxRecursions = 100]) {
    if (maxRecursions <= 0) {
      throw new ArgumentError.value(
          maxRecursions, 'maxRecursions', 'must be larger than 0');
    }

    // Note: no need to clone: subsInternal will return a new instance.
    var expr = this;

    var cycle = 0;
    while (cycle < maxRecursions) {
      // Check if terminator is already reached.
      final index = new W<int>(0);
      expr = expr.substituteInternal(terminator, index);
      if (index.v < 0) {
        return expr;
      }

      expr = expr.substituteInternal(equation, index);
      if (index.v == 0) {
        // Substitution failed, but condition is not yet met.
        throw new EqLibException(
            'recursion ended before terminator was reached');
      }

      // Evaluate new substitution.
      expr.evaluate(compute);

      cycle++;
    }

    throw new EqLibException('reached maximum number of recursions');
  }

  /// Appemts to evaluate this expression to a number using the given compute
  /// functions. Returns double.NAN if this is unsuccessful.
  num evaluate(ExprCompute compute);
}

/// Utility function to check if the given expression is dependent only on the
/// given symbol ID.
bool _exprOnlyDependsOn(int symbolId, Expr expr) {
  if (expr is NumberExpr) {
    return true;
  } else if (expr is FunctionExpr) {
    return expr.isSymbol
        ? expr.id == symbolId
        : expr.args.every((arg) => _exprOnlyDependsOn(symbolId, arg));
  } else {
    return false;
  }
}
