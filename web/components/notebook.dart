// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:async';

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
  final entries = new List<EntryData>();
  int largestIndex = 0;

  Future<Null> ngOnInit() async {
    addEntry();
  }

  void updateData(int index, EntryData data) {}

  void addEntry() {
    entries.add(new EntryData(++largestIndex));
  }

  void insertEntry(int index) {
    entries.insert(index, new EntryData(++largestIndex));
  }

  void deleteEntry(int index) {
    entries.removeAt(index);
  }
}
