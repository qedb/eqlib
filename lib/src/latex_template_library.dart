// Copyright (c) 2017, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of eqlib.latex;

/*
1:  \int_(?0=?1)^(?2)*?3=int(?0, ?1, ?2, ?3)
2:  #123(?0, ?1, ?0=?2, ?3)=int(?0, ?1, ?2, ?3)
3:  #123(?0, ?1, ?2, ?3)*\d(?0)=int(?0, ?1, ?2, ?3)
*/

class LaTeXTemplate {
  Expr template;
  int targetFunction;

  //String encode();
}

class EncodedTemplate {
  String template;
  int targetFunction;
  int priority;
}

class LaTeXTemplateLibrary {
  List<String> latexCommands;

  List<List<LaTeXTemplate>> library;

  //EncodedTemplate addTemplate(String source);

  //List<EncodedTemplate> encode();

  //void decode(List<EncodedTemplate> data);
}
