// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

/// Parse a LaTeX string and produce an expression.
/// TODO: Create tests.
Expr parseLaTeX(String input, [ExprResolve resolver = eqlibSAResolve]) {
  // 1. Apply all substitutions.
  var processedInput = input;
  _latexSubstitute.forEach((key, value) {
    processedInput = processedInput.replaceAllMapped(
        key, (match) => _processLatexSubstitute(match, value));
  });

  // 2. Parse expression.
  final expr = parseExpression(processedInput);

  // 3. Apply rules.
  for (final rule in _latexRules) {
    expr.subsAll(rule);
  }

  return expr;
}

/// Substitution rules to pre-process LaTeX for parsing.
///
/// Optional arguments are not processed, e.g. \sqrt[3] is not supported.
///
/// The following special operators are present after processing:
/// - A `=` operator (for example in sums or integrals), this operator has a
///   very low precedence (lower than addition).
/// - A `_` operator (subscript), this operator has  a very high precedence
///   (higher than the unary minus).
///
/// Additionally there is a factorial operator in LaTeX (`!`) and implicit
/// multiplication has the same precedence as explicit multiplication.
final Map<Pattern, String> _latexSubstitute = {
  /// Mark implicit multiplication with a space.
  /// Example: `2^22 => 2^2 2`
  new RegExp(r'^([0-9A-Za-z])'): r'^$1 ',
  new RegExp(r'_([0-9A-Za-z])'): r'_$1 ',

  /// Numbers after commands (or other pieces of text) are not considered part of
  /// that text. Insert a space to mark implicit multiplication.
  /// Example: `\alpha2 => \alpha 2`
  new RegExp(r'([a-z])(\d)'): r'$1 $2',
  new RegExp(r'(\S)\\'): r'$1 \\',

  /// Calculus specific: replace dx with d(x) (for all letters).
  new RegExp(r'([^A-Za-z])d([A-Za-z]{1})([^A-Za-z]|$)'): r'$1d($2)$3',

  /// Convert multiple arguments to argument list.
  /// Example: `\frac{1}{2}` => `\frac{1,2}`
  new RegExp(r'}\s*{'): ',',

  /// Convert braces to parentheses.
  /// Example: `\frac{1,2}` => `\frac(1,2)`
  '{': '(',
  '}': ')',

  /// Convert multiplication sign.
  r'\cdot': '*',

  /// Convert left/right parentheses.
  r'\left(': '(',
  r'\right)': ')',

  /// Convert absolute value & vector magnitude notation.
  r'\left|': 'abs(',
  r'\right|': ')'
};

final _substituteVarRegex = new RegExp(r'\$(\d)+');

/// Process value of [_latexSubstitute].
String _processLatexSubstitute(Match keyMatch, String substitute) =>
    substitute.replaceAllMapped(_substituteVarRegex,
        (match) => keyMatch.group(int.parse(match.group(1))));

/// List all trigonometry functions.
const _trigFnBase = const ['sin', 'cos', 'tan', 'cot'];
final _trigFn = generateList<String>(_trigFnBase.length, [
  (i) => _trigFnBase[i],
  (i) => 'arc' + _trigFnBase[i],
  (i) => _trigFnBase[i] + 'h'
]);

/// Substitution expressions to process messy LaTeX expressions.
final List<Eq> _latexRules = [
  /// Calculus general
  new Eq.parse(r'd ?x = d(?x)'),
  new Eq.parse(r'\partial ?x = d(?x)'),

  /// Integrals
  new Eq.parse(r'\int ?f d(?x) = indefinite_integral(?f, ?x'),
  new Eq(new Expr.parse(r'\int_{?x=?a}^{?b} ?f d(?x)'),
      new Expr.parse('definite_integral(?f, ?x, ?a, ?b')),

  /// Differentials
  new Eq.parse(r'\frac{d}{d(?x)} ?f = diff(?f, ?x)'),
  new Eq.parse(r'\frac{\partial}{\partial ?x} ?f = diff(?f, ?x)'),

  /// Limits
  new Eq.parse(r'\lim_{?a \to ?b} ?f = lim(?a, ?b, ?f)')
]
  ..addAll(generateList<Eq>(_trigFn.length, [
    /// For all trigonometry functions
    (i) => new Eq.parse('\\${_trigFn[i]} ?a = ${_trigFn[i]}(?a)'),
    (i) => new Eq.parse('\\${_trigFn[i]}^?e ?a = ${_trigFn[i]}(?a)^?e')
  ]));
