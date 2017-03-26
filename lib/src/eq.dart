// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

/// Equation of two expressions
class Eq {
  /// Left and right hand side.
  Expr left, right;

  Eq(this.left, this.right);

  /// Create deep copy.
  Eq clone() => new Eq(left.clone(), right.clone());

  /// Substitute the given equation.
  bool substitute(Eq eq, [int idx = 0]) {
    final index = new W<int>(idx);
    left = left.substituteInternal(eq, index);
    if (index.v != -1) {
      right = right.substituteInternal(eq, index);
      return index.v == -1;
    } else {
      return true;
    }
  }

  /// Wrap both sides of the equation using the given [template].
  void envelop(Expr template, Expr envelope) {
    final lmapping = new ExprMapping();
    if (left.compare(template, lmapping)) {
      _envelop(envelope, lmapping);
    } else {
      final rmapping = new ExprMapping();
      if (right.compare(template, rmapping)) {
        _envelop(envelope, rmapping);
      } else {
        throw new EqLibException('the template does not match left or right');
      }
    }
  }

  /// Wrap both sides of the equation using the provided [envelope] expression
  /// and expression [mapping].
  void _envelop(Expr envelope, ExprMapping mapping) {
    left = envelope
        .remap(mapping)
        .substitute(new Eq(new FunctionExpr(0, false, []), left));
    right = envelope
        .remap(mapping)
        .substitute(new Eq(new FunctionExpr(0, false, []), right));
  }

  /// Compute both sides of the equation as far as possible using the given
  /// resolver.
  void evaluate(ExprCompute compute) {
    final lvalue = left.evaluate(compute);
    if (!lvalue.isNaN) {
      left = new NumberExpr(lvalue);
    }
    final rvalue = right.evaluate(compute);
    if (!rvalue.isNaN) {
      right = new NumberExpr(rvalue);
    }
  }

  /// Compare two equations.
  @override
  bool operator ==(dynamic other) {
    if (other is Eq) {
      return left == other.left && right == other.right;
    } else {
      return false;
    }
  }

  /// Equation hashcode.
  @override
  int get hashCode =>
      jPostprocess(jMix(jMix(0, left.hashCode), right.hashCode));
}
