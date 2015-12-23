#!/usr/bin/env bash

set -e

echo "Generating links.."
find $PWD -name ".[^.]*" -type f -print0 | xargs -0tJ % ln -sf %  ~
echo "Complete!"
