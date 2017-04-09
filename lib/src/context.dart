// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

abstract class ExprContextLabelResolver {
  /// Function to assign an ID to an expression label.
  int assignId(String label, bool generic);

  /// Function to retrieve the expression label for the given ID.
  String getLabel(int id);
}

abstract class ExprContext {
  final ExprContextLabelResolver labelResolver;

  ExprContext(this.labelResolver);

  int assignId(String label, bool generic) =>
      labelResolver.assignId(label, generic);

  String getLabel(int id) => labelResolver.getLabel(id);

  /// Function to should compute a numeric value for the given expression ID
  /// and arguments.
  num compute(int id, List<num> args);

  /// Function to generate a human readable string from the given expression or
  /// equation.
  String str(Expr input);

  /// Parse an expression string.
  Expr parse(String str);

  /// Parse expression string as rule.
  Rule parseRule(String str);
}
