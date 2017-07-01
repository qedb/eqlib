#!/bin/bash

# Copyright (c) 2016, Herman Bergwerf. All rights reserved.
# Use of this source code is governed by an AGPL-3.0-style license
# that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Check formatting.
dartfmt --dry-run --set-exit-if-changed ./

# Run analyzer checks.
dartanalyzer \
--options analysis_options.yaml \
--fatal-hints --fatal-warnings --fatal-lints ./

# Run the tests.
pub run test
