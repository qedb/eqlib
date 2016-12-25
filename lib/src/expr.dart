// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression of a variable or function
abstract class Expr {
  Expr();

  /// Construct from binary data.
  factory Expr.fromBinary(ByteBuffer buffer) => exprCodecDecode(buffer);

  /// Construct from Base64 string.
  factory Expr.fromBase64(String base64) =>
      new Expr.fromBinary(new Uint8List.fromList(BASE64.decode(base64)).buffer);

  /// Parse string expression using EqExParser.
  factory Expr.parse(String str, [ExprResolve resolver = standaloneResolve]) {
    return parseExpression(str);
  }

  /// Transform the given value into an expression if it is not an expression
  /// already.
  factory Expr.wrap(dynamic value) {
    if (value is Expr) {
      return value;
    } else if (value is num) {
      return new ExprNum(value);
    } else {
      throw new ArgumentError('value type must be one of: Expr, num');
    }
  }

  /// Write binary data.
  ByteBuffer toBinary() => exprCodecEncode(this);

  /// Write Base64 string.
  String toBase64() => BASE64.encode(toBinary().asUint8List());

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
  bool get isGeneric => false;

  /// Superset pattern matching
  ///
  /// Match another [superset] expression against this expression.
  ExprMatchResult matchSuperset(Expr superset);

  /// Expression remapping
  ///
  /// If this expression is in the [mapping] table, this will return the new
  /// expression. Else this will remap all arguments.
  ///
  /// This method always returns a new expression instance (deep cody).
  Expr remap(Map<int, Expr> mapping);

  /// Substitute the given [equation] at the given pattern [index].
  /// Returns a new instance of [Expr] where the equation is substituted.
  /// Never returns null, instead returns itself if nothing is substituted.
  Expr subsInternal(Eq equation, W<int> index) {
    final result = matchSuperset(equation.left);
    return result.match && index.v-- == 0
        ? equation.right.remap(result.mapping)
        : this;
  }

  Expr subs(Eq equation, [int index = 0]) =>
      subsInternal(equation, new W<int>(index));

  /// Recursive substitution.
  Expr subsRecursive(Eq equation, Eq terminator, [int maxRecursions = 100]) {
    if (maxRecursions <= 0) {
      throw new ArgumentError.value(
          maxRecursions, 'maxRecursions', 'must be larger than 0');
    }

    var expr = clone();

    var cycle = 0;
    while (cycle < maxRecursions) {
      // Check if terminator is already reached.
      final index = new W<int>(0);
      expr = expr.subsInternal(terminator, index);
      if (index.v < 0) {
        return expr;
      }

      expr = expr.subsInternal(equation, index);
      if (index.v == 0) {
        // Substitution failed, but condition is not yet met.
        throw new Exception('recursion ended before terminator was reached');
      }

      // Evaluate new substitution.
      expr.eval();

      cycle++;
    }

    throw new Exception('reached maximum number of recursions');
  }

  /// Appemts to evaluate this expression to a number using the given compute
  /// functions. Returns null if this is unsuccessful.
  ///
  /// TODO: find a way to avoid `null` as return value.
  num _eval(ExprCanCompute canCompute, ExprCompute compute);

  /// Wrapper of [_eval] to provide default arguments.
  num eval(
          [ExprCanCompute canCompute = standaloneCanCompute,
          ExprCompute computer = standaloneCompute]) =>
      _eval(canCompute, computer);

  // Standard operator IDs used by built-in operators.
  static int opAddId = standaloneResolve('add');
  static int opSubId = standaloneResolve('sub');
  static int opMulId = standaloneResolve('mul');
  static int opDivId = standaloneResolve('div');
  static int opPowId = standaloneResolve('pow');
  static int opNegId = standaloneResolve('neg');

  /// Add other expression.
  Expr operator +(dynamic other) =>
      new ExprFun(opAddId, [this, new Expr.wrap(other)]);

  /// Subtract other expression.
  Expr operator -(dynamic other) =>
      new ExprFun(opSubId, [this, new Expr.wrap(other)]);

  /// Multiply by other expression.
  Expr operator *(dynamic other) =>
      new ExprFun(opMulId, [this, new Expr.wrap(other)]);

  /// Divide by other expression.
  Expr operator /(dynamic other) =>
      new ExprFun(opDivId, [this, new Expr.wrap(other)]);

  /// Power by other expression.
  Expr operator ^(dynamic other) =>
      new ExprFun(opPowId, [this, new Expr.wrap(other)]);

  /// Negate expression.
  Expr operator -() => new ExprFun(opNegId, [this]);

  /// Global string printer function.
  static ExprPrint stringPrinter = dfltExprEngine.print;

  /// Generate string representation.
  @override
  String toString() => stringPrinter(this);
}

/// Return data of [Expr.matchSuperset].
class ExprMatchResult {
  bool match;

  /// Map of function/symbol ID's and their mapped expression
  final mapping = new Map<int, Expr>();

  ExprMatchResult.exactMatch() : match = true;

  ExprMatchResult.noMatch() : match = false;

  ExprMatchResult.genericMatch(int generic, Expr ref) : match = true {
    mapping[generic] = ref;
  }

  ExprMatchResult.processGenericFunction(
      int id, Expr fnref, int argsLength, ExprMatchResult matchArg(int i)) {
    mapping[id] = fnref;
    match = _processFunction(argsLength, matchArg);
  }

  ExprMatchResult.processFunction(
      int argsLength, ExprMatchResult matchArg(int i)) {
    match = _processFunction(argsLength, matchArg);
  }

  bool _processFunction(int argsLength, ExprMatchResult matchArg(int i)) {
    for (var i = 0; i < argsLength; i++) {
      final result = matchArg(i);

      // If this argument does not match, terminate.
      if (!result.match) {
        return false;
      }

      // Check if any existing mappings would be violated by merging with
      // the mapping resulting from the argument match.
      for (final key in result.mapping.keys) {
        if (mapping.containsKey(key) && mapping[key] != result.mapping[key]) {
          // Violation: terminate.
          return false;
        }
      }

      // Merge argument mapping into this mapping.
      mapping.addAll(result.mapping);
    }
    return true;
  }
}
