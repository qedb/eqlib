// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

/// LaTeX Expr printer
class LaTeXPrinter {
  final dict = new Map<int, String>();

  void addDefaultEntries(ExprContextLabelResolver res) {
    final id = (String str) => res.assignId(str, false);
    dict[id('+')] = r'$0+$1';
    dict[id('-')] = r'$0-$1';
    dict[id('*')] = r'$0~$1';
    dict[id('/')] = r'\frac{$0}{$1}';
    dict[id('^')] = r'$0^{$1}';
    dict[id('~')] = r'-$0';
    dict[id('!')] = r'$0!';
    dict[id('_')] = r'$0_{$1}';
  }

  /// Render LaTeX string from the given expression. Expressions that are not in
  /// the printer dictionary use [resolveName] and a generic function notation.
  ///
  /// The render function figures out how to prevent uninteded side effects of
  /// nested templates. Templates should be as compact as possible and not
  /// contain spaces etc.
  String render(Expr expr, ExprGetLabel resolveName, OperatorConfig ops) {
    // Numbers
    if (expr is NumberExpr) {
      return expr.value.toString();
    }

    // Functions
    else if (expr is FunctionExpr) {
      // Render expression.
      if (dict.containsKey(expr.id)) {
        return _renderTemplate(expr, resolveName, ops);
      } else {
        final genericPrefix = expr.isGeneric ? r'{}_\text{?}' : '';
        if (!expr.isSymbol) {
          final args = new List<String>.generate(expr.args.length,
                  (i) => render(expr.args[i], resolveName, ops),
                  growable: false)
              .join(r',\,');

          return [
            genericPrefix,
            r'\text{',
            resolveName(expr.id),
            r'}{\left(',
            args,
            r'\right)}'
          ].join();
        } else {
          return [genericPrefix, resolveName(expr.id)].join();
        }
      }
    } else {
      throw unsupportedType('expr', expr, ['NumberExpr', 'FunctionExpr']);
    }
  }

  /// Render template string.
  /// Borrows functionality from [SimpleExprContext.formatExplicitParentheses].
  String _renderTemplate(
      FunctionExpr expr, ExprGetLabel resolveName, OperatorConfig ops) {
    assert(dict.containsKey(expr.id));
    return dict[expr.id].replaceAllMapped(new RegExp(r'\$(\d+)'), (match) {
      final arg = expr.args[int.parse(match.group(1))];
      var str = render(arg, resolveName, ops);

      // Additionaly formatting.
      if (arg is FunctionExpr) {
        final op = ops.byId[expr.id];
        final pre = op != null ? op.precedenceLevel : 1;

        // Format opening and closing arguments with explicit parentheses.
        if (match.start == 0) {
          str = SimpleExprContext.formatExplicitParentheses(
              r'\left(', r'\right)', arg, str, pre, Associativity.rtl, ops);
        } else if (match.end == match.input.length) {
          str = SimpleExprContext.formatExplicitParentheses(
              r'\left(', r'\right)', arg, str, pre, Associativity.ltr, ops);
        }
      }

      // Check if a space should be added at the beginning. Spaces are added to
      // separate letters that should not be grouped (in particular when dealing
      // with commands).
      if (match.start > 0) {
        final letter = new RegExp(r'[A-Za-z]');
        if (letter.hasMatch(match.input[match.start - 1]) &&
            letter.hasMatch(str[0])) {
          str = ' $str';
        }
      }

      return str;
    });
  }
}
