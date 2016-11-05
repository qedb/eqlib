// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

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

class EntryData {
  /// Entry index in the notebook
  int index;

  /// Entry type
  EntryType type = EntryType.empty;

  /// For [EntryType.symbol] entries
  var symbols = new List<SymbolData>();

  /// For [EntryType.define] entries
  String defineXml;

  /// For [EntryType.apply] entries
  int applySource, applyTarget, applyIndex;

  /// For [EntryType.compute] entries
  int computeSource;

  EntryData(this.index);

  /// Reconstruct from JSON.decode data.
  EntryData.fromJson(Map<String, dynamic> data) {
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
    applySource = data['applySource'];
    applyTarget = data['applyTarget'];
    applyIndex = data['applyIndex'];
    computeSource = data['computeSource'];
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
        return {'index': index, 'type': type.index, 'defineXml': defineXml};
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
