// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex_printer;

/// Function or symbol entry for the LaTeX printer.
class LaTeXPrinterEntry {
  /// LaTeX template string
  final String template;

  /// Level of precedence for omitting parentheses (higher is first).
  final int precedenceLvl;

  const LaTeXPrinterEntry(this.template, [this.precedenceLvl = 0]);
}

/// LaTeX Expr printer
class LaTeXPrinter {
  final _dict = new Map<int, LaTeXPrinterEntry>();

  /// Default precedence level for function notation.
  static const functionPrecedence = 3;

  /// Dictionary update events.
  final _onDictUpdate = new StreamController<Null>.broadcast();
  Stream<Null> get onDictUpdate => _onDictUpdate.stream;
  
  /// Stream destructor.
  Future destruct() => _onDictUpdate.close();

  void addDefaultEntries(ExprResolve resolver) {
    _dict[resolver('add')] = const LaTeXPrinterEntry(r'$(a)+$(b)', 0);
    _dict[resolver('sub')] = const LaTeXPrinterEntry(r'$(a)-$(b)', 0);
    _dict[resolver('mul')] = const LaTeXPrinterEntry(r'$(a)\cdot$(b)', 1);
    _dict[resolver('div')] = const LaTeXPrinterEntry(r'\frac{$a}{$b}', 1);
    _dict[resolver('pow')] = const LaTeXPrinterEntry(r'$(a)^{$b}', 2);
    _dict[resolver('neg')] = const LaTeXPrinterEntry(r'-{$a}', 2);
  }

  // Add or replace entry in printer dictionary.
  void dictUpdate(int id, LaTeXPrinterEntry entry) {
    _dict[id] = entry;
    _onDictUpdate.add(null);
  }

  /// Remove and add entry in printer dictionary at once.
  /// (e.g. triggers [onDictUpdate] only once)
  void dictReplace(int oldId, int newId, LaTeXPrinterEntry entry) {
    if (oldId != newId && _dict.containsKey(oldId)) {
      _dict.remove(oldId);
    }
    _dict[newId] = entry;
    _onDictUpdate.add(null);
  }

  /// Render LaTeX string from the given expression. Expressions that are not in
  /// the printer dictionary use [resolveName] and a generic function notation.
  ///
  /// + [parentPrecedence] is the precedence index of the parent.
  /// + [useParentheses] sets if parenteses should be used if the precedence
  ///   level is smaller than the parent.
  /// + [explicitNotation] sets if parenteses should also be used when the
  ///   parent precedence index is equal to the current one.
  String render(Expr expr, ExprResolveName resolveName,
      [int parentPrecedence = 0,
      bool useParentheses = false,
      bool explicitNotation = false]) {
    // Numbers
    if (expr is ExprNum) {
      return expr.value.toString();
    }

    // Symbols
    else if (expr is ExprSym) {
      return _dict.containsKey(expr.id)
          ? _dict[expr.id].template
          : '{${resolveName(expr.id)}}';
    }

    // Functions
    else if (expr is ExprFun) {
      // Render expression.
      final rendered = _dict.containsKey(expr.id)
          ? renderTemplate(expr, _dict[expr.id], resolveName, explicitNotation)
          : [
              r'\text{',
              resolveName(expr.id),
              r'}\left(',
              new List<String>.generate(expr.args.length,
                  (i) => render(expr.args[i], resolveName)).join(', '),
              r'\right)'
            ].join();

      // Surround with parentesis if the parent precedence index is higher and
      // the parent does require parentheses, or if explicitNotation is set.
      if ((explicitNotation &&
              _dict[expr.id].precedenceLvl == parentPrecedence) ||
          (useParentheses && _dict[expr.id].precedenceLvl < parentPrecedence)) {
        return '\\left($rendered\\right)';
      } else {
        return rendered;
      }
    } else {
      throw new ArgumentError(
          'expr type must be one of: ExprNum, ExprSym, ExprFun');
    }
  }

  /// Render template
  String renderTemplate(ExprFun expr, LaTeXPrinterEntry entry,
      ExprResolveName resolveName, bool explicitNotation) {
    // Generic argument processing function.
    final processArg = (Match match, bool useParentheses) {
      // Compute argument index.
      final idx = match.group(1).codeUnitAt(0) - 'a'.codeUnitAt(0);

      // If the index is out of bounds with the expression arguments, throw an
      // error.
      if (idx < expr.args.length) {
        return render(expr.args[idx], resolveName, entry.precedenceLvl,
            useParentheses, explicitNotation);
      } else {
        throw new ArgumentError('template arguments do not match the function');
      }
    };

    // Copy output string from entry template.
    var output = entry.template;

    // Never surround with parenthesis.
    output = output.replaceAllMapped(new RegExp(r'\$(\w+)'), (match) {
      return processArg(match, false);
    });

    // Surround with parenthesis when applicable.
    output = output.replaceAllMapped(new RegExp(r'\$\((\w+)\)'), (match) {
      return processArg(match, true);
    });

    return output;
  }
}
