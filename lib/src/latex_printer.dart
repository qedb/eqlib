// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

class _LaTeXRenderData {
  final String tex;
  final int leftBoundaryPre;
  final int rightBoundaryPre;

  _LaTeXRenderData(this.tex,
      [this.leftBoundaryPre = -1, this.rightBoundaryPre = -1]);
}

/// LaTeX Expr printer
class LaTeXPrinter {
  final dict = new Map<int, String>();

  void addDefaultEntries(ExprContextLabelResolver res) {
    final id = (String str) => res.assignId(str, false);
    dict[id('+')] = r'$(0+)+$(+1)';
    dict[id('-')] = r'$(0-)-$(-1)';
    dict[id('*')] = r'$(0*)$(*1)';
    dict[id('/')] = r'\frac{$0}{$1}';
    dict[id('^')] = r'$(0^)^{$1}';
    dict[id('~')] = r'-$(~0)';
    dict[id('!')] = r'$(0!)!';
    dict[id('_')] = r'$(0_)_{$1}';
  }

  /// Public alias for [_render].
  String render(Expr expr, ExprGetLabel resolveName, OperatorConfig ops) {
    return _render(expr, resolveName, ops).tex;
  }

  /// Render LaTeX string from the given expression. Expressions that are not in
  /// the printer dictionary use [resolveName] and a generic function notation.
  ///
  /// The render function figures out how to prevent unintended side effects of
  /// nested templates. Templates should be as compact as possible and not
  /// contain spaces etc.
  _LaTeXRenderData _render(
      Expr expr, ExprGetLabel resolveName, OperatorConfig ops) {
    // Numbers
    if (expr is NumberExpr) {
      return new _LaTeXRenderData(expr.value.toString());
    }

    // Functions
    else if (expr is FunctionExpr) {
      // Render expression.
      if (dict.containsKey(expr.id)) {
        return _renderTemplate(expr, resolveName, ops);
      } else {
        final genericPrefix = expr.isGeneric ? r'{}_\text{?}' : '';
        if (!expr.isSymbol) {
          return new _LaTeXRenderData([
            genericPrefix,
            r'\text{',
            resolveName(expr.id),
            r'}{\left(',
            new List<String>.generate(expr.arguments.length,
                    (i) => render(expr.arguments[i], resolveName, ops))
                .join(r',\,'),
            r'\right)}'
          ].join());
        } else {
          return new _LaTeXRenderData(
              [genericPrefix, resolveName(expr.id)].join());
        }
      }
    } else {
      throw unsupportedType('expr', expr, ['NumberExpr', 'FunctionExpr']);
    }
  }

  /// Render template string.
  /// Borrows functionality from [SimpleExprContext.formatExplicitParentheses].
  _LaTeXRenderData _renderTemplate(
      FunctionExpr expr, ExprGetLabel resolveName, OperatorConfig ops) {
    assert(dict.containsKey(expr.id));
    final argRegex = new RegExp(r'\$(?:(\d+)|\(([^\d]?)(\d+)([^\d]?)\))');

    var leftBoundaryPre = -1;
    var rightBoundaryPre = -1;
    final tex = dict[expr.id].replaceAllMapped(argRegex, (match) {
      final nr = match.group(1) ?? match.group(3);
      final arg = expr.arguments[int.parse(nr)];
      final argData = _render(arg, resolveName, ops);
      var tex = argData.tex;

      // Parentheses
      final g2 = match.group(2);
      final g4 = match.group(4);
      final opChar = g2 != null && g2.isNotEmpty ? g2 : g4;
      if (opChar != null && opChar.isNotEmpty) {
        final op = ops.byChar[char(opChar)];
        final pre = op.precedenceLevel;
        final direction = opChar == g2 ? Associativity.ltr : Associativity.rtl;

        // Proceed with adding parentheses if the argument is an operator or
        // has colliding boundaries.
        if (arg is FunctionExpr && ops.byId.containsKey(arg.id)) {
          tex = SimpleExprContext.formatExplicitParentheses(
              r'\left(', r'\right)', arg, tex, pre, direction, ops);
        } else if ((direction == Associativity.ltr &&
                argData.leftBoundaryPre > 0 &&
                argData.leftBoundaryPre <= pre) ||
            (direction == Associativity.rtl &&
                argData.rightBoundaryPre > 0 &&
                argData.rightBoundaryPre <= pre)) {
          tex = '\\left($tex\\right)';
        }

        // Propagate boundary settings.
        // Also check if we just added parentheses.
        if (match.start == 0) {
          leftBoundaryPre = pre;
        } else if (match.end == match.input.length) {
          rightBoundaryPre = pre;
        }
      }

      // Check if a space should be added at the beginning. Spaces are added to
      // separate letters that should not be grouped (in particular when dealing
      // with commands).
      if (match.start > 0) {
        final letter = new RegExp(r'[A-Za-z]');
        // Check character in input before this argument and the first character
        // of this argument.
        if (letter.hasMatch(match.input[match.start - 1]) &&
            letter.hasMatch(tex[0])) {
          tex = ' $tex';
        }
      }

      return tex;
    });

    return new _LaTeXRenderData(tex, leftBoundaryPre, rightBoundaryPre);
  }
}
