// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib;

class Stepper {
  final List<Step> steps;
  Stepper(this.steps);

  /// Execute steps on the given input and return the result.
  Eq run(Eq input) {
    for (final step in steps) {
      step.applyTo(input);
    }
    return input;
  }
}

abstract class Step {
  factory Step.subs(dynamic left, dynamic right) =>
      new SubsStep(new Eq(left, right));
  factory Step.wrap(Expr condition, Expr wrapping) =>
      new WrapStep(condition, wrapping);
  factory Step.eval() => new EvalStep();

  /// Apply this step to the given equation.
  void applyTo(Eq eq);
}

class SubsStep implements Step {
  final Eq rule;
  SubsStep(this.rule);

  @override
  void applyTo(Eq eq) {
    eq.subs(rule);
  }
}

class WrapStep implements Step {
  final Expr condition, wrapping;
  WrapStep(this.condition, this.wrapping);

  @override
  void applyTo(Eq eq) {
    eq.wrap(condition, wrapping);
  }
}

class EvalStep implements Step {
  @override
  void applyTo(Eq eq) {
    eq.eval();
  }
}
