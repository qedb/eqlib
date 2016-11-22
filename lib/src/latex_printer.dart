// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex_printer;

class LaTeXPrinterEntry {
  final String template;
  final bool useParenthesis;
  const LaTeXPrinterEntry(this.template, [this.useParenthesis = false]);
}

/// LaTeX Expr printer
/// TODO: Handle multiple levels of operator precedence better.
class LaTeXPrinter {
  final _dict = new Map<int, LaTeXPrinterEntry>();

  /// Dictionary update events.
  final _onDictUpdate = new StreamController<Null>.broadcast();
  Stream<Null> get onDictUpdate => _onDictUpdate.stream;

  void addDefaultEntries(ExprResolve resolver) {
    _dict[resolver('add')] = const LaTeXPrinterEntry(r'$a+$b', true);
    _dict[resolver('sub')] = const LaTeXPrinterEntry(r'$a-$b', true);
    _dict[resolver('mul')] = const LaTeXPrinterEntry(r'$(a)\cdot$(b)', true);
    _dict[resolver('div')] = const LaTeXPrinterEntry(r'\frac{$a}{$b}', true);
    _dict[resolver('pow')] = const LaTeXPrinterEntry(r'$(a)^{$b}', false);
  }

  /// TODO: design more generic methods.
  void dictReplace(int oldId, int newId, String template) {
    if (oldId != newId && _dict.containsKey(oldId)) {
      _dict.remove(oldId);
    }
    _dict[newId] = new LaTeXPrinterEntry(template);
    _onDictUpdate.add(null);
  }

  String render(Expr expr, ExprResolveName resolveName,
      [bool explicitBlock = false]) {
    if (expr is ExprNum) {
      return expr.value.toString();
    } else if (expr is ExprSym) {
      return _dict.containsKey(expr.id)
          ? _dict[expr.id].template
          : '{${resolveName(expr.id)}}';
    } else if (expr is ExprFun) {
      // Check if there is an entry in the dictionary.
      if (_dict.containsKey(expr.id)) {
        final formatted =
            renderTemplate(expr, _dict[expr.id].template, resolveName);
        if (explicitBlock && _dict[expr.id].useParenthesis) {
          return '\\left($formatted\\right)';
        } else {
          return formatted;
        }
      } else {
        // Resolve function name using the name resolver.
        final name = resolveName(expr.id);
        return [
          '\\text{$name}\\left(',
          new List<String>.generate(
                  expr.args.length, (i) => render(expr.args[i], resolveName))
              .join(', '),
          '\\right)'
        ].join();
      }
    } else {
      throw new ArgumentError(
          'expr type must be one of: ExprNum, ExprSym, ExprFun');
    }
  }

  /// Render template
  String renderTemplate(
      ExprFun expr, String template, ExprResolveName resolveName) {
    // Never surround with parenthesis.
    final openArg = new RegExp(r'\$(\w+)');

    // Surround with parenthesis when argument has useParenthesis set.
    final closedArg = new RegExp(r'\$\((\w+)\)');

    // Replace all open args.
    template = template.replaceAllMapped(openArg, (match) {
      // Compute argument index.
      final idx = match.group(1).codeUnitAt(0) - 'a'.codeUnitAt(0);
      if (idx < expr.args.length) {
        return render(expr.args[idx], resolveName);
      } else {
        return match.group(1);
      }
    });

    // Replace all closed args.
    template = template.replaceAllMapped(closedArg, (match) {
      // Compute argument index.
      final idx = match.group(1).codeUnitAt(0) - 'a'.codeUnitAt(0);
      if (idx < expr.args.length) {
        return render(expr.args[idx], resolveName, true);
      } else {
        return match.group(1);
      }
    });

    return template;
  }
}
