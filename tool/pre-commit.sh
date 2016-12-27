#!/bin/bash

# Copyright (c) 2016, Herman Bergwerf. All rights reserved.
# Use of this source code is governed by an AGPL-3.0-style license
# that can be found in the LICENSE file.

BRANCH_NAME=$(git branch | grep '*' | sed 's/* //')

# Do not run when rebasing.
if [ $BRANCH_NAME != '(no branch)' ]
then
  unifmt -c 'Herman Bergwerf' -l 'AGPL-3.0' -e '**.html'
  ./tool/check.sh
fi
