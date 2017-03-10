// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

/// All LaTeX parsing stuff is wrapped in this class to not pollute the global
/// namespace, and to delay some initialization untill the class is constructed.
class LaTeXParser {
  /// Substitution rules to pre-process LaTeX for parsing.
  ///
  /// Optional arguments are not processed seperatecly (e.g. `\sqrt[3]`).
  ///
  /// The following special operators are present after processing:
  /// - A `=` operator (for example in sums or integrals), this operator has a
  ///   very low precedence (lower than addition).
  /// - A `_` operator (subscript), this operator has  a very high precedence
  ///   (higher than the unary minus).
  ///
  /// Additionally there is a factorial operator in LaTeX (`!`) and implicit
  /// multiplication has the same precedence as explicit multiplication.
  final Map<Pattern, String> replaceMap = {
    /// Mark implicit multiplication with a space.
    /// Example: `2^22` => `2^2 2`
    new RegExp(r'\^([0-9A-Za-z])'): r'^$1 ',
    new RegExp(r'_([0-9A-Za-z])'): r'_$1 ',

    /// Numbers after commands (or other pieces of text) are not considered part of
    /// that text. Insert a space to mark implicit multiplication.
    /// Example: `\alpha2` => `\alpha 2`
    new RegExp(r'([a-z])(\d)'): r'$1 $2',
    new RegExp(r'(\S)\\'): r'$1 \',

    /// Calculus specific: replace dx with d(x) (for all letters).
    new RegExp(r'([^A-Za-z])d([A-Za-z]{1})([^A-Za-z]|$)'): r'$1d($2)$3',

    /// Convert multiple arguments to argument list.
    /// Example: `\frac{1}{2}` => `\frac{1,2}`
    new RegExp(r'}\s*{'): ',',

    /// Convert braces to parentheses.
    /// Example: `\frac{1,2}` => `\frac(1,2)`
    '{': '(',
    '}': ')',

    /// Tilde in LaTeX means a space.
    '~': ' ',

    /// Convert multiplication sign.
    r'\cdot': '*',

    /// Convert left/right parentheses.
    r'\left(': '(',
    r'\right)': ')',

    /// Convert absolute value & vector magnitude notation.
    r'\left|': 'abs(',
    r'\right|': ')'
  };

  /// Fundamental trigonometry functions.
  static const basicTrigFunctions = const ['sin', 'cos', 'tan', 'cot'];

  /// List of all functions that we consider for the LaTeX parser.
  ///
  /// ## All standard LaTeX functions
  ///
  ///     \arccos   \cos     \csc    \exp    \ker       \limsup   \min    \sinh
  ///     \arcsin   \cosh    \deg    \gcd    \lg        \ln       \Pr     \sup
  ///     \arctan   \cot     \det    \hom    \lim       \log      \sec    \tan
  ///     \arg      \coth    \dim    \inf    \liminf    \max      \sin    \tanh
  ///
  final allFunctions = [
    'arg', 'csc', 'det', 'exp', 'ln',
    //
    'log', 'min', 'max', 'sec'
  ];

  /// Substitution rules to process messy LaTeX expressions.
  static const Map<String, String> rules = const {
    /// Basic operators
    r'\frac{?a}{?b}': '?a / ?b',

    /// Logarithm
    r'\log_?b ?n': 'log(?b, ?n)',

    /// Calculus general
    r'd ?x': 'd(?x)',
    r'\partial ?x': 'd(?x)',

    /// Integrals
    r'\int ?f d ?x': 'int(?f, ?x)',
    r'\int_{?x=?a}^{?b} ?f d(?x)': 'defint(?f, ?x, ?a, ?b)',

    /// Differentials
    r'd/d(?x) ?f': 'diff(?f, ?x)',
    r'\partial/(\partial ?x) ?f': 'diff(?f, ?x)',

    /// Limits
    r'\lim_{?a \to ?b} ?f': 'lim(?a, ?b, ?f)'
  };

  /// Parsed [rules]
  final parsedRules = new List<Eq>();

  LaTeXParser(ExprContext ctx) {
    // Load default operator configuration.
    operators
      ..add(Associativity.ltr,
          argc: 2, lvl: 0, char: '=', id: ctx.assignId('=', false))
      ..add(Associativity.ltr,
          argc: 2, lvl: 1, char: '+', id: ctx.assignId('+', false))
      ..add(Associativity.ltr,
          argc: 2, lvl: 1, char: '-', id: ctx.assignId('-', false))
      ..add(Associativity.ltr,
          argc: 2, lvl: 2, char: '*', id: ctx.assignId('*', false))
      ..add(Associativity.ltr,
          argc: 2, lvl: 2, char: '/', id: ctx.assignId('/', false))
      ..add(Associativity.rtl,
          argc: 2, lvl: 3, char: '^', id: ctx.assignId('^', false))
      ..add(Associativity.rtl,
          argc: 1, lvl: 4, char: '~', id: ctx.assignId('~', false))
      ..add(Associativity.ltr,
          argc: 1, lvl: 5, char: '!', id: ctx.assignId('!', false))
      ..add(Associativity.ltr,
          argc: 2, lvl: 6, char: '_', id: ctx.assignId('_', false))
      ..add(Associativity.ltr, argc: 2, lvl: 2, id: 0);

    // Add variations of basic trigonometry functions to [allFunctions].
    allFunctions.addAll(generateList<String>(basicTrigFunctions.length, [
      (i) => basicTrigFunctions[i],
      (i) => 'arc' + basicTrigFunctions[i],
      (i) => basicTrigFunctions[i] + 'h'
    ]));

    // Parse all specified rules.
    rules.forEach((left, right) => parsedRules
        .add(new Eq(parse(left, ctx.assignId, false), ctx.parse(right))));

    // Generate additional rules for all functions specified in [allFunctions].
    parsedRules.addAll(generateList<Eq>(allFunctions.length, [
      (i) => new Eq(parse('\\${allFunctions[i]} ?a', ctx.assignId, false),
          ctx.parse('${allFunctions[i]}(?a)')),
      (i) => new Eq(parse('\\${allFunctions[i]}^?e ?a', ctx.assignId, false),
          ctx.parse('${allFunctions[i]}(?a)^?e'))
    ]));
  }

  /// Operator configuration for parsing LaTeX.
  final operators = new OperatorConfig(0);

  /// Parse a LaTeX string and produce an expression.
  Expr parse(String input, ExprAssignId assignId, [bool applyRules = true]) {
    // 1. Apply all replacements.
    var processedInput = input;
    replaceMap.forEach((key, value) {
      processedInput = processedInput.replaceAllMapped(
          key, (match) => processReplaceValue(match, value));
    });

    // 2. Parse expression.
    var expr = parseExpression(processedInput, operators, assignId);

    // 3. Apply rules.
    if (applyRules) {
      for (final rule in parsedRules) {
        expr = expr.substituteAll(rule);
      }
    }

    return expr;
  }

  /// Process [replaceMap] values.
  String processReplaceValue(Match keyMatch, String substitute) =>
      substitute.replaceAllMapped(new RegExp(r'\$(\d)+'),
          (match) => keyMatch.group(int.parse(match.group(1))));
}
