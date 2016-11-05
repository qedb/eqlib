// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:guppy_dart/guppy_dart.dart';
import 'package:katex_js/katex_js.dart' as katex;

import 'entry_data.dart';

/// Use this instead of CSS transitions because we need all kinds of shady
/// delays to make them work.
void _animateHeight(
    DivElement elm, int from, int to, int stepSize, Function callback,
    [int steps = 0]) {
  window.requestAnimationFrame((num time) {
    elm.style.height = '${from + stepSize * steps}px';
    if (steps < ((to - from) / stepSize).abs().floor()) {
      _animateHeight(elm, from, to, stepSize, callback, steps + 1);
    } else {
      elm.style.height = '${to}px';
      callback();
    }
  });
}

@Component(
  selector: 'notebook-entry',
  templateUrl: 'notebook_entry.html',
  styleUrls: const ['notebook_entry.css'],
  directives: const [materialDirectives, MaterialNumberInputValidatorDirective],
  providers: const [materialProviders],
)
class NotebookEntryComponent implements AfterViewInit {
  // Stream controllers for bindings with the parent notebook.
  final _dataChanged = new StreamController<EntryData>();
  final _entryInsert = new StreamController<Null>();
  final _entryDelete = new StreamController<Null>();

  @ViewChild('wrapper')
  ElementRef wrapper;

  @ViewChild('guppyDefine')
  ElementRef guppyDefine;

  @ViewChildren('symbolLaTeXRendered')
  QueryList<ElementRef> symbolLaTeXRendered;

  void addSymbol(int index) {
    data.symbols.insert(index, new SymbolData('', ''));
  }

  void updateSymbol(int index) {
    final name = data.symbols[index].name;
    final latex = data.symbols[index].latex;
    katex.render(latex, symbolLaTeXRendered.toList()[index].nativeElement);
    guppyRemoveSymbol(name);
    guppyAddSymbol(name, latex, name);
  }

  void removeSymbol(int index) {
    data.symbols.removeAt(index);
  }

  void ngAfterViewInit() {
    final div = wrapper.nativeElement as DivElement;
    div.style.height = 'auto';

    if (data.type == EntryType.empty) {
      // Animate wrapper when entry is new.
      _animateHeight(div, 0, div.clientHeight, 6, () {
        div.style.height = 'auto';
      });
      div.style.height = '0';
    } else if (data.type == EntryType.symbols) {
      // Render all LaTeX strings.
      for (var i = 0; i < data.symbols.length; i++) {
        updateSymbol(i);
      }
    }
  }

  void configure(int typeIndex) {
    data.type = EntryType.values[typeIndex];
    _dataChanged.add(data);

    if (data.type == EntryType.symbols) {
      // Add initial row.
      data.symbols.add(new SymbolData('', ''));
    } else if (data.type == EntryType.define) {
      // Wait for 100ms so Angular can add the root element to the DOM
      new Future.delayed(new Duration(milliseconds: 100), () {
        // Initialize new Guppy editor.
        guppyInit('packages/guppy_dart/deps/transform.xsl',
            'packages/guppy_dart/deps/symbols.json');
        new Guppy(guppyDefine.nativeElement);
      });
    }
  }

  void onDelete() {
    final div = wrapper.nativeElement as DivElement;
    _animateHeight(div, div.clientHeight, 0, -6, () {
      _entryDelete.add(null);
    });
  }

  void onInsert() => _entryInsert.add(null);

  @Input()
  EntryData data;

  @Output()
  Stream<EntryData> get dataChanged => _dataChanged.stream;

  @Output()
  Stream<Null> get entryInsert => _entryInsert.stream;

  @Output()
  Stream<Null> get entryDelete => _entryDelete.stream;
}
