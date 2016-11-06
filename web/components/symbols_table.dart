// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:eqlib/latex_printer.dart';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:guppy_dart/guppy_dart.dart';
import 'package:katex_js/katex_js.dart' as katex;

import 'entry_data.dart';

@Component(
  selector: 'symbols-table',
  templateUrl: 'symbols_table.html',
  styleUrls: const ['symbols_table.css'],
  directives: const [materialDirectives, MaterialNumberInputValidatorDirective],
  providers: const [materialProviders],
)
class SymbolsTableComponent implements AfterViewInit {
  String oldName;

  @Input()
  List<SymbolData> symbols;

  @ViewChildren('renderedSymbol')
  QueryList<ElementRef> renderedSymbol;

  void ngAfterViewInit() {
    // Render all LaTeX strings.
    for (var i = 0; i < symbols.length; i++) {
      updateSymbol(i);
    }
  }

  void addSymbol(int index) {
    symbols.insert(index, new SymbolData('', ''));
  }

  void updateSymbol(int index) {
    final name = symbols[index].name;
    final latex = symbols[index].latex;

    katex.render(latex, renderedSymbol.toList()[index].nativeElement);
    if (oldName != null) {
      guppyRemoveSymbol(name);
      defaultLatexPrinterDict.remove(name);
    }
    guppyAddSymbol(name, latex, name);
    defaultLatexPrinterDict[name] = latex;
    oldName = name;
  }

  void removeSymbol(int index) {
    symbols.removeAt(index);
  }
}
