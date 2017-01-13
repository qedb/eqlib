// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex_printer;

/// LaTeX dictionary entry
class LaTeXDictEntry {
  /// LaTeX template string
  final String template;

  /// Use parentheses to separate this function from surrounding things.
  final bool useParentheses;

  /// Precedence index (when chain).
  final int precedence;

  /// Argument index that is evaluated before this operator is. This index is
  /// used to mimick the behavior of operator associativity.
  ///
  /// Example: when this function represents a left associative operator, the
  /// 0th index is evaluated before this operator is evaluated. Therefore, if
  /// this argument has a higer or equal precedence, it should be surrounded in
  /// parentheses (the configuration for this function can again override this
  /// by disabling [useParentheses], for example when the template already
  /// resolves this). This behaviour can also be disabled by the parent template
  /// if it already provides a way to distinghuish the argument as argument.
  final int preEvalIndex;

  const LaTeXDictEntry(this.template,
      [this.useParentheses = false,
      this.precedence = 0,
      this.preEvalIndex = -1]);
}

class LaTeXDictUpdateAddition {
  final int id;
  final LaTeXDictEntry entry;
  LaTeXDictUpdateAddition(this.id, this.entry);
}

/// [LaTeXPrinter.onDictUpdate] event data
class LaTeXDictUpdate {
  final List<int> remove;
  final List<LaTeXDictUpdateAddition> add;
  LaTeXDictUpdate(this.remove, this.add);
}

/// LaTeX Expr printer
class LaTeXPrinter {
  final _dict = new Map<int, LaTeXDictEntry>();

  /// Default precedence level for function notation
  ///
  /// Note: omitting parentheses on single argument functions can be achieved by
  /// setting the precedence to 1. This means it will put add and sub operators
  /// in parentheses but not operators with a higer precedence
  /// (including functions!).
  static const functionPrecedence = 5;

  /// Dictionary update events.
  final _onDictUpdate = new StreamController<LaTeXDictUpdate>.broadcast();
  Stream<LaTeXDictUpdate> get onDictUpdate => _onDictUpdate.stream;

  /// Stream destructor.
  Future destruct() => _onDictUpdate.close();

  void addDefaultEntries([ExprResolve resolver = eqlibSAResolve]) {
    _dict[resolver('add')] = const LaTeXDictEntry(r'$(a)+$(b)', true, 1, 0);
    _dict[resolver('sub')] = const LaTeXDictEntry(r'$(a)-$(b)', true, 1, 0);
    _dict[resolver('mul')] = const LaTeXDictEntry(r'$(a)\cdot$(b)', true, 2, 0);
    _dict[resolver('div')] =
        const LaTeXDictEntry(r'\frac{$a}{$b}', false, 2, 0);
    _dict[resolver('pow')] = const LaTeXDictEntry(r'$!(a)^{$b}', true, 3, 1);
    _dict[resolver('neg')] = const LaTeXDictEntry(r'-$(a)', false, 4, 0);
  }

  // Add or replace entry in printer dictionary.
  void dictUpdate(LaTeXDictUpdate update) {
    update.remove.forEach((id) => _dict.remove(id));
    update.add.forEach((add) => _dict[add.id] = add.entry);
    _onDictUpdate.add(update);
  }

  /// Render LaTeX string from the given expression. Expressions that are not in
  /// the printer dictionary use [resolveName] and a generic function notation.
  ///
  /// The render function should make sure the output can not produce any
  /// conflicts with any surrounding TeX.
  String render(Expr expr, [ExprResolveName resolveName = eqlibSAResolveName]) {
    // Numbers
    if (expr is NumberExpr) {
      return expr.value.toString();
    }

    // Symbols
    // Note: we could analyze the inner expression to decide if braces are neccesary.
    else if (expr is SymbolExpr) {
      return [
        '{',
        _dict.containsKey(expr.id)
            ? _dict[expr.id].template
            : resolveName(expr.id),
        '}'
      ].join();
    }

    // Functions
    else if (expr is FunctionExpr) {
      // Render expression.
      return _dict.containsKey(expr.id)
          ? _renderTemplate(expr, resolveName)
          : [
              r'\text{',
              resolveName(expr.id),
              r'}\left(',
              new List<String>.generate(expr.args.length,
                      (i) => render(expr.args[i], resolveName),
                      growable: false)
                  .join(', '),
              r'\right)'
            ].join();
    } else {
      throw new ArgumentError(
          'expr type must be one of: NumberExpr, SymbolExpr, FunctionExpr');
    }
  }

  /// Render template (unsafe).
  String _renderTemplate(FunctionExpr expr, ExprResolveName resolveName) {
    assert(_dict.containsKey(expr.id));
    final entry = _dict[expr.id];

    // Copy output string from entry template.
    var output = entry.template;

    // Never surround with parenthesis.
    output = output.replaceAllMapped(new RegExp(r'\$(\w+)'), (match) {
      return _processTemplateArg(expr, resolveName, entry.precedence,
          entry.preEvalIndex, match, true, false);
    });

    // Surround with parenthesis demanded by precedence and association rules.
    output = output.replaceAllMapped(new RegExp(r'\$\((\w+)\)'), (match) {
      return _processTemplateArg(expr, resolveName, entry.precedence,
          entry.preEvalIndex, match, false, false);
    });

    // Force surround with parenthesis for functions.
    output = output.replaceAllMapped(new RegExp(r'\$!\((\w+)\)'), (match) {
      return _processTemplateArg(expr, resolveName, entry.precedence,
          entry.preEvalIndex, match, false, true);
    });

    return output;
  }

  /// Argument processer for [_renderTemplate].
  ///
  /// Note: [disableParentheses] is turned on when the template already provides
  /// another way to separate the expression from the surrounding LaTeX (\frac).
  String _processTemplateArg(
      FunctionExpr expr,
      ExprResolveName resolveName,
      int parentPrecedence,
      int preEvalIndex,
      Match match,
      bool disableParentheses,
      bool forceParentheses) {
    // Compute argument index.
    final index = match.group(1).codeUnitAt(0) - 'a'.codeUnitAt(0);

    // If the index is out of bounds with the expression arguments, throw an
    // error.
    if (index < expr.args.length) {
      final arg = expr.args[index];

      // Use parentheses if enabled and:
      // - index is not preEvalIndex and precedence <= parent precedence
      // - index is preEvalIndex and precedence < parent precedence
      var printParentheses = false;
      if (!disableParentheses &&
          arg is FunctionExpr &&
          _dict.containsKey(arg.id) &&
          _dict[arg.id].useParentheses) {
        final precedence = _dict[arg.id].precedence;
        printParentheses =
            precedence < parentPrecedence + (index != preEvalIndex ? 1 : 0);
      }

      final rendered = render(arg, resolveName);
      return printParentheses || (forceParentheses && arg is FunctionExpr)
          ? '\\left($rendered\\right)'
          : rendered;
    } else {
      throw new ArgumentError('template cannot be resolved');
    }
  }
}
