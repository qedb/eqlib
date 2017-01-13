// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression of a variable or function
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

  /// Parse string expression using EqExParser.
  factory Expr.parse(String str, [ExprResolve resolver = eqlibSAResolve]) {
    return parseExpression(str);
  }

  /// Transform the given value into an expression if it is not an expression
  /// already.
  factory Expr.from(dynamic value) {
    if (value is Expr) {
      return value;
    } else if (value is num) {
      return new NumberExpr(value);
    } else {
      throw new ArgumentError('value type must be one of: Expr, num');
    }
  }

  /// Write binary data.
  ByteBuffer toBinary() => exprCodecEncode(this).writeToBuffer();

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
  Expr remap(Map<int, Expr> mapping, Map<int, FunctionExpr> genericFunctions);

  /// Substitute the given [equation] at the given pattern [index].
  /// Returns a new instance of [Expr] where the equation is substituted.
  /// Never returns null, instead returns itself if nothing is substituted.
  Expr subsInternal(Eq equation, W<int> index) {
    final result = matchSuperset(equation.left);
    return result.match && index.v-- == 0
        ? equation.right.remap(result.mapping, result.genericFunctions)
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

    // Note: no need to clone: subsInternal will return a new instance.
    var expr = this;

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
        throw new EqLibException(
            'recursion ended before terminator was reached');
      }

      // Evaluate new substitution.
      expr.eval();

      cycle++;
    }

    throw new EqLibException('reached maximum number of recursions');
  }

  /// Appemts to evaluate this expression to a number using the given compute
  /// functions. Returns double.NAN if this is unsuccessful.
  num evalInternal(ExprCanCompute canCompute, ExprCompute compute);

  /// Wrapper of [evalInternal] to provide default arguments.
  num eval(
          [ExprCanCompute canCompute = eqlibSACanCompute,
          ExprCompute computer = eqlibSACompute]) =>
      evalInternal(canCompute, computer);

  // Standard operator IDs used by built-in operators.
  static int opAddId = eqlibSAResolve('add');
  static int opSubId = eqlibSAResolve('sub');
  static int opMulId = eqlibSAResolve('mul');
  static int opDivId = eqlibSAResolve('div');
  static int opPowId = eqlibSAResolve('pow');
  static int opNegId = eqlibSAResolve('neg');

  /// Add other expression.
  Expr operator +(dynamic other) =>
      new FunctionExpr(opAddId, [this, new Expr.from(other)]);

  /// Subtract other expression.
  Expr operator -(dynamic other) =>
      new FunctionExpr(opSubId, [this, new Expr.from(other)]);

  /// Multiply by other expression.
  Expr operator *(dynamic other) =>
      new FunctionExpr(opMulId, [this, new Expr.from(other)]);

  /// Divide by other expression.
  Expr operator /(dynamic other) =>
      new FunctionExpr(opDivId, [this, new Expr.from(other)]);

  /// Power by other expression.
  Expr operator ^(dynamic other) =>
      new FunctionExpr(opPowId, [this, new Expr.from(other)]);

  /// Negate expression.
  Expr operator -() => new FunctionExpr(opNegId, [this]);

  /// Global string printer function.
  static ExprPrint stringPrinter = eqlibSAPrint;

  /// Generate string representation.
  @override
  String toString() => stringPrinter(this);
}

/// Return data of [Expr.matchSuperset].
class ExprMatchResult {
  bool match;

  /// Map of function/symbol IDs and their mapped expression
  final mapping = new Map<int, Expr>();

  /// Map of generic functions.
  final genericFunctions = new Map<int, FunctionExpr>();

  ExprMatchResult.exactMatch() : match = true;

  ExprMatchResult.noMatch() : match = false;

  ExprMatchResult.genericMatch(int generic, Expr ref) : match = true {
    mapping[generic] = ref;
  }

  /// The generic superset function must contain exactly one argument (less than
  /// one should be a symbol, more than one cannot guarantee order).
  ExprMatchResult.processGenericFunction(
      FunctionExpr superset, FunctionExpr fnref) {
    // Fist establish that the superset has only one argument.
    if (superset.args.length != 1) {
      throw new EqLibException(
          'generic functions can only have a single argument');
    }

    // Add the function to the generic function list.
    genericFunctions[superset.id] = superset;

    // If the reference function also has one argument, we can try to map
    // generics.
    if (fnref.args.length == 1) {
      _processFunction(fnref.args.length,
          (i) => fnref.args[i].matchSuperset(superset.args[i]));
    }

    // Store mapping from superset function to the reference function.
    // Note that the mapping is still empty so additional check are not
    // required.
    mapping[superset.id] = fnref;
    match = true;
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

      // Check if any existing genericFunctions are incompatible with generic
      // functions from this argument.
      for (final fn in result.genericFunctions.keys) {
        if (genericFunctions.containsKey(fn) &&
            genericFunctions[fn] != result.genericFunctions[fn]) {
          // Violation: illegal superset rule.
          // Generic functions must be equal to support argument inference.
          throw new EqLibException('generic functions must all be equal');
        }
      }

      // Merge generic functions.
      genericFunctions.addAll(result.genericFunctions);
    }
    return true;
  }
}
