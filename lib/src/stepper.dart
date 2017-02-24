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
  factory Step.substitute(dynamic left, dynamic right) =>
      new SubstituteStep(new Eq(left, right));
  factory Step.envelop(Expr template, Expr envelope) =>
      new EnvelopStep(template, envelope);
  factory Step.evaluate() => new EvalStep();

  /// Apply this step to the given equation.
  void applyTo(Eq eq);
}

class SubstituteStep implements Step {
  final Eq rule;
  SubstituteStep(this.rule);

  @override
  void applyTo(Eq eq) {
    eq.substitute(rule);
  }
}

class EnvelopStep implements Step {
  final Expr template, envelope;
  EnvelopStep(this.template, this.envelope);

  @override
  void applyTo(Eq eq) {
    eq.envelop(template, envelope);
  }
}

class EvalStep implements Step {
  @override
  void applyTo(Eq eq) {
    eq.evaluate();
  }
}
