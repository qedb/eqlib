// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:eqlib/eqlib.dart';
import 'package:eqlib/default.dart';

enum EntryType { empty, symbols, define, apply, compute }

class SymbolData {
  String name, latex;

  SymbolData(this.name, this.latex);

  SymbolData.fromJson(Map<String, String> data) {
    name = data['name'];
    latex = data['latex'];
  }

  Map<String, String> toJson() => {'name': name, 'latex': latex};
}

typedef EntryData EntryLookupFn(int i);

class EntryData {
  /// Entry index in the notebook
  int index;

  /// Entry type
  EntryType type = EntryType.empty;

  /// For [EntryType.symbols] entries
  var symbols = new List<SymbolData>();

  /// For [EntryType.define] entries
  String defineXml, defineText;

  /// For [EntryType.apply] entries
  /// Note that <material-input> gives us doubles.
  double applySource, applyTarget, applyIndex;

  /// For [EntryType.compute] entries
  int computeSource;

  /// For all entries except symbol tables.
  Eq eq;
  bool wrapEq = false;

  final EntryLookupFn entryLookup;

  EntryData(this.index, this.entryLookup);

  /// Reconstruct from JSON.decode data.
  EntryData.fromJson(Map<String, dynamic> data, this.entryLookup) {
    index = data['index'];
    type = EntryType.values[data['type']];

    List symbolData = data['symbols'];
    if (symbolData != null) {
      symbols = new List<SymbolData>.generate(
          symbolData.length,
          (i) => new SymbolData.fromJson(
              new Map<String, String>.from(symbolData[i])));
    }

    defineXml = data['defineXml'];
    defineText = data['defineText'];
    applySource = data['applySource'];
    applyTarget = data['applyTarget'];
    applyIndex = data['applyIndex'];
    computeSource = data['computeSource'];
  }

  /// Get equation.
  Eq getEq() {
    if (eq == null) {
      if (defineText != null) {
        updateEqFromText(defineText);
      } else {
        updateEqByApply();
      }
      return eq;
    } else {
      return eq;
    }
  }

  /// Update equation from text.
  void updateEqFromText(String text) {
    wrapEq = text.contains('→');
    final sides = wrapEq ? text.split('→') : text.split('=');
    final parser = new EqExParser();
    eq = new Eq(parser.parse(sides[0]).value, parser.parse(sides[1]).value);
    defineText = text;
  }

  /// Update equation from apply parameters.
  void updateEqByApply() {
    // If one of the apply parameters is null, return.
    if (applySource == null || applyTarget == null || applyIndex == null) {
      return;
    }

    // Resolve source.
    final source = entryLookup(applySource.toInt()).getEq().clone();

    // Resolve target.
    final target = entryLookup(applyTarget.toInt()).getEq();

    // Get target type.
    final wrap = entryLookup(applyTarget.toInt()).wrapEq;

    // Generate default generics.
    final generics = [
      defaultResolver('a'),
      defaultResolver('b'),
      defaultResolver('c')
    ];

    // Apply.
    if (wrap) {
      source.wrap(target.left, generics, target.right);
    } else {
      source.subs(target, generics, applyIndex.toInt());
    }

    eq = source;
  }

  /// Add [change] to all indices starting at [start] (inclusive).
  void changeIndicesFrom(int start, int change) {
    if (index >= start) {
      index += change;
    }

    if (applySource != null && applySource >= start) {
      applySource += change;
    }
    if (applyTarget != null && applyTarget >= start) {
      applyTarget += change;
    }
    if (applyIndex != null && applyIndex >= start) {
      applyIndex += change;
    }
    if (computeSource != null && computeSource >= start) {
      computeSource += change;
    }
  }

  /// Create JSON.encode compatiple data structure.
  Map<String, dynamic> toJson() {
    switch (type) {
      case EntryType.empty:
        return {'index': index, 'type': type.index};
      case EntryType.symbols:
        return {'index': index, 'type': type.index, 'symbols': symbols};
      case EntryType.define:
        return {
          'index': index,
          'type': type.index,
          'defineXml': defineXml,
          'defineText': defineText
        };
      case EntryType.apply:
        return {
          'index': index,
          'type': type.index,
          'applySource': applySource,
          'applyTarget': applyTarget,
          'applyIndex': applyIndex
        };
      case EntryType.compute:
        return {
          'index': index,
          'type': type.index,
          'computeSource': computeSource
        };
      default:
        throw new StateError('EntryType.data is $type');
    }
  }
}
