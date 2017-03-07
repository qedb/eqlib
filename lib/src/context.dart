// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

abstract class ExprContext {
  /// Function to assign an ID to an expression label.
  int assignId(String label, bool generic);

  /// Function to retrieve the expression label for the given ID.
  String getLabel(int id);

  /// Function to should compute a numeric value for the given expression ID
  /// and arguments.
  num compute(int id, List<num> args);

  /// Function to generate a human readable string from the given expression or
  /// equation.
  String str(dynamic input);

  /// Parse an expression string.
  Expr parse(String str);

  /// Parse an equation string.
  Eq parseEq(String str);

  /// Recursive substitution (this requires computation).
  Expr substituteRecursivly(Expr base, Eq equation, Eq terminator,
          [int maxRecursions = 100]) =>
      base.substituteRecursivly(equation, terminator, compute, maxRecursions);

  /// Evaluate the given expression.
  num evaluate(Expr expr) => expr.evaluate(compute);
}
