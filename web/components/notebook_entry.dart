// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:guppy_dart/guppy_dart.dart';

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
  directives: const [materialDirectives],
  providers: const [materialProviders],
)
class NotebookEntryComponent implements AfterViewInit {
  int index = 0;
  String type = 'empty';
  final _dataChanged = new StreamController<EntryData>();
  final _entryInsert = new StreamController<Null>();
  final _entryDelete = new StreamController<Null>();

  @ViewChild('wrapper')
  ElementRef wrapper;

  @ViewChild('guppyDefine')
  ElementRef guppyDefine;

  ngAfterViewInit() {
    // Animate wrapper.
    final div = wrapper.nativeElement as DivElement;
    div.style.height = 'auto';
    _animateHeight(div, 0, div.clientHeight, 6, () {
      div.style.height = 'auto';
    });
    div.style.height = '0';
  }

  void configure(String _type) {
    type = _type;
    if (type == 'define') {
      guppyInit('packages/guppy_dart/deps/transform.xsl',
          'packages/guppy_dart/deps/symbols.json');
      new Guppy(guppyDefine.nativeElement);
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
  set data(EntryData data) {
    index = data.index;
  }

  @Output()
  Stream<EntryData> get dataChanged => _dataChanged.stream;

  @Output()
  Stream<Null> get entryInsert => _entryInsert.stream;

  @Output()
  Stream<Null> get entryDelete => _entryDelete.stream;
}
