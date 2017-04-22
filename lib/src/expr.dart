// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Expression of a variable or function
///
/// The expression class is supposed to be fully immutable.
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

  /// Convert expression to flat structure.
  List<Expr> flatten();

  /// Get all function IDs in this expression.
  Set<int> get functionIds {
    final target = new Set<int>();
    getFunctionIds(target);
    return target;
  }

  /// Internal call for [getFunctionIds].
  void getFunctionIds(Set<int> target);

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
  /// This method always returns a new expression instance (deep copy).
  Expr remap(ExprMapping mapping);

  /// Substitute the given [rule] at the given [position]. The position of this
  /// node is 0. The position should be decremented when passing it on to
  /// children.
  Expr substituteAt(Rule rule, int position) {
    final _position = new W<int>(position);
    final result = _substituteAt(rule, _position);
    if (_position.v >= 0) {
      throw new EqLibException('position not found');
    } else {
      return result;
    }
  }

  /// [substituteAt] with shared position pointer.
  Expr _substituteAt(Rule rule, W<int> position);

  /// Apply given [rearrange] list at [position].
  Expr rearrangeAt(
      List<int> rearrange, int position, List<int> rearrangeableIds) {
    final _position = new W<int>(position);
    final result = _rearrangeAt(rearrange, _position, rearrangeableIds);
    if (_position.v >= 0) {
      throw new EqLibException('position not found');
    } else {
      return result;
    }
  }

  /// [rearrangeAt] with shared position pointer.
  Expr _rearrangeAt(
      List<int> rule, W<int> position, List<int> rearrangeableIds);

  /// Find first [n] positions that match [expr].
  List<int> search(Expr expr, [int n = 1]) {
    final result = new List<int>();
    final flat = flatten();
    for (var i = 0; i < flat.length; i++) {
      if (flat[i].compare(expr)) {
        result.add(i);
        if (n > 0 && result.length == n) {
          break;
        }
      }
    }
    return result;
  }

  /// Substitute [rule] at first [n] matching positions.
  /// Throws an error if [n] > 0 and it is not possible to substitute [n] times.
  Expr substitute(Rule rule, [int n = 1]) {
    final positions = search(rule.left, n);
    if (n > 0 && positions.length != n) {
      throw new EqLibException('could not find $n substitution sites');
    }

    // Iterate backwards so positions stay fixed.
    var expr = this;
    for (final position in positions.reversed) {
      expr = expr.substituteAt(rule, position);
    }

    return expr;
  }

  /// Attempts to evaluate this expression to a number using the given compute
  /// functions. Returns expression that is evaluated as far as possible. This
  /// is not guaranteed to be a new instance.
  Expr evaluate(ExprCompute compute);
}

/// Repeat [n] [Expr.substitute] calls with [rule] on [target] for at most [max]
/// cycles. After each cycle the expression is evaluated. After each cycle the
/// terminator is substituted. When [_n] terminators are substituted this
/// function returns with the new expression.
Expr substituteRecursive(
    Expr target, Rule rule, Rule terminator, ExprCompute compute,
    [int _n = 1, int max = 100]) {
  assert(max > 0 && _n > 0);

  var n = _n;
  var cycles = 0;
  var expr = target;

  while (n > 0) {
    cycles++;
    if (cycles > max) {
      throw new EqLibException('reached maximum number of recursions');
    }

    // Try to substitute rule.
    expr = expr.substitute(rule, n);

    // Evaluate expression before searching for terminators.
    expr = expr.evaluate(compute);

    // Substitute terminators.
    do {
      final nextPosition = expr.search(terminator.left, 1);
      if (nextPosition.isNotEmpty) {
        expr = expr.substituteAt(terminator, nextPosition.first);
        n--;
      } else {
        break;
      }
    } while (n > 0);
  }

  return expr;
}

/// Utility function to check if the given expression is dependent only on the
/// given symbol ID. Used by [FunctionExpr.remap].
bool _exprOnlyDependsOn(int symbolId, Expr expr) {
  if (expr is NumberExpr) {
    return true;
  } else if (expr is FunctionExpr) {
    return expr.isSymbol
        ? expr.id == symbolId
        : expr.arguments.every((arg) => _exprOnlyDependsOn(symbolId, arg));
  } else {
    return false;
  }
}
