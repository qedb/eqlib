// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

/// TODO:
/// - support interpolation expressions
/// - class based printer
part of eqlib.latex_printer;

class LaTeXPrinterEntry {
  final String template;
  final bool useParenthesis;
  const LaTeXPrinterEntry(this.template, [this.useParenthesis = false]);
}

/// LaTeX Expr printer.
class LaTeXPrinter {
  final _dict = new Map<int, LaTeXPrinterEntry>();

  void addDefaultEntries(ExprResolve resolver) {
    _dict[resolver('add')] = const LaTeXPrinterEntry('{a}+{b}', true);
    _dict[resolver('sub')] = const LaTeXPrinterEntry('{a}-{b}', true);
    _dict[resolver('mul')] = const LaTeXPrinterEntry('{(a)}\\cdot{(b)}', true);
    _dict[resolver('div')] = const LaTeXPrinterEntry('\\frac{{a}}{{b}}', true);
    _dict[resolver('pow')] = const LaTeXPrinterEntry('{(a)}^{{b}}', false);
  }

  String format(Expr input, ExprResolveName resolveName,
      [bool explicitBlock = false]) {
    if (input.isNumeric) {
      return input.value.toString();
    } else {
      assert(input.value is int);

      // Check if there is an entry in the dictionary.
      if (_dict.containsKey(input.value)) {
        final formatted =
            renderTemplate(input, _dict[input.value].template, resolveName);
        if (explicitBlock && _dict[input.value].useParenthesis) {
          return '{\\left($formatted\\right)}';
        } else {
          return formatted;
        }
      } else {
        // Resolve function name using the name resolver.
        final name = resolveName(input.value);
        if (input.args.isEmpty) {
          return '{$name}';
        } else {
          return [
            '{\\text{$name}\\left(',
            new List<String>.generate(input.args.length,
                (i) => format(input.args[i], resolveName)).join(', '),
            '\\right)}'
          ].join();
        }
      }
    }
  }

  /// Render template
  String renderTemplate(
      Expr input, String template, ExprResolveName resolveName) {
    // Never surround with parenthesis.
    final openArg = new RegExp(r'{(\w+)}');

    // Surround with parenthesis when argument has useParenthesis set.
    final closedArg = new RegExp(r'{\((\w+)\)}');

    // Replace all open args.
    template = template.replaceAllMapped(openArg, (match) {
      // Compute argument index.
      final idx = match.group(1).codeUnitAt(0) - 'a'.codeUnitAt(0);
      if (idx < input.args.length) {
        return format(input.args[idx], resolveName);
      } else {
        return match.group(1);
      }
    });

    // Replace all closed args.
    template = template.replaceAllMapped(closedArg, (match) {
      // Compute argument index.
      final idx = match.group(1).codeUnitAt(0) - 'a'.codeUnitAt(0);
      if (idx < input.args.length) {
        return format(input.args[idx], resolveName, true);
      } else {
        return match.group(1);
      }
    });

    return template;
  }
}
