// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

class _LaTeXRenderData {
  final String tex;
  final bool startsWithInteger, endsWithInteger;
  final bool noParamBefore, noParamAfter;
  final int leftFacingPrecedence, rightFacingPrecedence;

  _LaTeXRenderData(this.tex,
      [this.startsWithInteger = false,
      this.endsWithInteger = false,
      this.noParamBefore = false,
      this.noParamAfter = false,
      this.leftFacingPrecedence = -1,
      this.rightFacingPrecedence = -1]);
}

/// LaTeX Expr printer
class LaTeXPrinter {
  static var leftParenthesis = r'\left(';
  static var rightParenthesis = r'\right)';

  final ExprGetLabel getLabel;
  final OperatorConfig operators;
  final dict = new Map<int, LaTeXTemplate>();

  LaTeXPrinter(this.getLabel, this.operators);

  void addTemplate(int functionId, String template) {
    dict[functionId] = parseLaTeXTemplate(template, operators);
  }

  void addDefaultEntries(ExprAssignId assignId) {
    int id(String str) => assignId(str, false);
    addTemplate(id('+'), r'${.0}+${1(+).}');
    addTemplate(id('-'), r'${.0}-${2(+).}');
    addTemplate(id('*'), r'${.0(+):}${:1(*).}');
    addTemplate(id('/'), r'\frac{${0}}{${1}}');
    addTemplate(id('^'), r'{${.0(*)}}^{${1}}');
    addTemplate(id('~'), r'$!-${0(^).}');
    addTemplate(id('!'), r'${.0(~)}!');
    addTemplate(id('_'), r'{${.0(!)}}_{${1}}');
  }

  /// Public alias for [_render].
  String render(Expr expr) {
    return _render(expr).tex;
  }

  /// Render LaTeX string from the given expression. Expressions that are not in
  /// the printer dictionary use the label resolver and a generic function
  /// notation.
  ///
  /// The render function figures out how to prevent unintended side effects of
  /// nested templates. Templates should be as compact as possible and not
  /// contain spaces etc.
  _LaTeXRenderData _render(Expr expr) {
    // Numbers
    if (expr is NumberExpr) {
      if (expr.value < 0) {
        return _render(new FunctionExpr(
            operators.id('~'), false, [new NumberExpr(expr.value.abs())]));
      } else {
        return new _LaTeXRenderData(expr.value.toString(), true, true);
      }
    }

    // Functions
    else if (expr is FunctionExpr) {
      // Render expression.
      if (dict.containsKey(expr.id)) {
        return _renderTemplate(expr);
      } else {
        final genericPrefix = expr.isGeneric ? r'{}_\text{?}' : '';
        if (!expr.isSymbol) {
          return new _LaTeXRenderData([
            genericPrefix,
            r'\text{',
            getLabel(expr.id),
            r'}{\left(',
            new List<String>.generate(
                    expr.arguments.length, (i) => render(expr.arguments[i]))
                .join(r',\,'),
            r'\right)}'
          ].join());
        } else {
          return new _LaTeXRenderData(
              [genericPrefix, getLabel(expr.id)].join());
        }
      }
    } else {
      throw unsupportedType('expr', expr, ['NumberExpr', 'FunctionExpr']);
    }
  }

  /// Render template string.
  /// Borrows functionality from [SimpleExprContext.formatExplicitParentheses].
  _LaTeXRenderData _renderTemplate(FunctionExpr expr) {
    assert(dict.containsKey(expr.id));
    final template = dict[expr.id];
    final tok = template.tokens;

    var startsWithInteger = false, endsWithInteger = false;
    var noParamBefore = false, noParamAfter = false;
    var leftFacingPrecedence = -1, rightFacingPrecedence = -1;

    // Render string from template.
    final parts = new List<String>();

    var prevParamIdx = 0;
    _LaTeXRenderData prevParam;
    var passedTextToken = false;

    for (var i = 0; i < tok.length; i++) {
      final token = tok[i];

      if (token.text.isNotEmpty) {
        parts.add(token.text);
        passedTextToken = true;
      } else {
        final argument = expr.arguments[token.paramIndex];
        final rendered = _render(argument);
        var useParentheses = false;

        if (token.paramLeftBaseline) {
          startsWithInteger = startsWithInteger || rendered.startsWithInteger;
          noParamBefore = noParamBefore || rendered.noParamBefore;
          leftFacingPrecedence = token.parenthesesPriority;
        }
        if (token.paramRightBaseline) {
          endsWithInteger = endsWithInteger || rendered.endsWithInteger;
          noParamAfter = noParamAfter || rendered.noParamAfter;
          rightFacingPrecedence = token.parenthesesPriority;
        }

        // Determine if this argument should be surrounded in parentheses.
        // There are 5 cases when parentheses must be used:
        // 1. The argument is an operator, and has a precedence level lower or
        //    equal to the one indicated by this token.
        // 2. There is no text token between this parameter and the previous one
        //    and both have colliding integers.
        // 3. There is no text token between this parameter and the previous one
        //    and either one has an noParamBefore/noParamAfter flag set.
        // 4. This template is an operator, and the argument has a left facing
        //    parameter with a parentheses priority lower than this one or
        //    vice versa.
        // 5. This parameter has the noParamBefore flag set and the token has
        //    the paramImposterLeft flag set or vice versa.

        // 1
        if (argument is FunctionExpr &&
            operators.byId.containsKey(argument.id) &&
            operators.byId[argument.id].precedenceLevel <=
                token.parenthesesPriority) {
          useParentheses = true;
        }

        // 2
        else if (prevParam != null &&
            !passedTextToken &&
            prevParam.endsWithInteger &&
            rendered.startsWithInteger) {
          useParentheses = true;
        }

        // 3
        else if (prevParam != null &&
            !passedTextToken &&
            (prevParam.noParamAfter || rendered.noParamBefore)) {
          // By convention: we add parentheses around the parameter that has set
          // the flag. If this is the previous one, we will do some tricks here.
          if (prevParam.noParamAfter) {
            parts.insert(prevParamIdx, leftParenthesis);
            prevParamIdx++;
            parts.insert(prevParamIdx + 1, rightParenthesis);
            prevParamIdx++;
          } else {
            useParentheses = true;
          }
        }

        // 4
        else if (operators.byId.containsKey(expr.id)) {
          final opPre = operators.byId[expr.id].precedenceLevel;
          if (token.paramLeftBaseline &&
              rendered.rightFacingPrecedence != -1 &&
              rendered.rightFacingPrecedence < opPre) {
            useParentheses = true;
          } else if (token.paramRightBaseline &&
              rendered.leftFacingPrecedence != -1 &&
              rendered.leftFacingPrecedence < opPre) {
            useParentheses = true;
          }
        }

        // 5
        else if ((rendered.noParamBefore && token.paramImposterLeft) ||
            (rendered.noParamAfter && token.paramImposterRight)) {
          useParentheses = true;
        }

        // Add result to parts.
        if (useParentheses) {
          parts.add(leftParenthesis);

          prevParamIdx = parts.length;
          parts.add(rendered.tex);

          parts.add(rightParenthesis);

          // Since we added parentheses, we clear all flags indicating possible
          // collisions.
          prevParam = new _LaTeXRenderData(rendered.tex);
        } else {
          // If the last part ends with a letter and the parameter tex starts
          // with a letter, a space must be added.
          if (parts.isNotEmpty &&
              new RegExp(r'[A-Za-z]$').hasMatch(parts.last) &&
              new RegExp(r'^[A-Za-z]').hasMatch(rendered.tex)) {
            parts.add(' ');
          }
          prevParamIdx = parts.length;
          parts.add(rendered.tex);

          // This parameter is now the previous parameter and can be used for
          // collision checks.
          prevParam = rendered;
        }

        passedTextToken = false;
      }
    }

    return new _LaTeXRenderData(
        parts.join(),
        startsWithInteger,
        endsWithInteger,
        template.noParamBefore || noParamBefore,
        template.noParamAfter || noParamAfter,
        leftFacingPrecedence,
        rightFacingPrecedence);
  }
}
