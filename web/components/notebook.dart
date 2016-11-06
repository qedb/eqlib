// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';

import 'notebook_entry.dart';
import 'entry_data.dart';

@Component(
  selector: 'eqlib-notebook',
  templateUrl: 'notebook.html',
  styleUrls: const ['notebook.css'],
  directives: const [materialDirectives, NotebookEntryComponent],
  providers: const [materialProviders],
)
class NotebookComponent implements OnInit {
  /// Local Storage key where the notebook is stored.
  static const localStorageKey = 'eqlib-notebook-session';

  /// All notebook entries.
  final entries = new List<EntryData>();

  Future<Null> ngOnInit() async {
    // Store entries in the local storage before unload.
    window.onBeforeUnload.listen((_) {
      window.localStorage[localStorageKey] = JSON.encode(entries);
    });

    // Restore entries from the Local Storage.
    if (window.localStorage.containsKey(localStorageKey)) {
      List list = JSON.decode(window.localStorage[localStorageKey]);
      for (final item in list) {
        entries.add(new EntryData.fromJson(
            new Map<String, dynamic>.from(item), entryLookup));
      }
    } else {
      // Add empty initial entry.
      addEntry();
    }
  }

  /// Equation lookup function.
  EntryData entryLookup(int index) => entries[index];

  /// One record has been updated.
  void updateType(int index, EntryType type) {
    // Do not replace the record as this might confuse ngFor.
    entries[index].type = type;
  }

  /// Add a new entry to the bottom of the list.
  void addEntry() => entries.add(new EntryData(entries.length, entryLookup));

  /// Insert a new entry at the given index.
  void insertEntry(int index) {
    // Increment all indices that are equal or larger than index.
    for (final entry in entries) {
      entry.changeIndicesFrom(index, 1);
    }

    // Insert new entry at index.
    entries.insert(index, new EntryData(index, entryLookup));
  }

  /// Delete entry at the given index.
  void deleteEntry(int index) {
    entries.removeAt(index);

    // Decrement all indices that are larger than this one.
    for (final entry in entries) {
      entry.changeIndicesFrom(index + 1, -1);
    }
  }
}
