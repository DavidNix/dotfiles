#!/usr/bin/env bash

set -e

readonly defSize=12

SIZE=${1:-$defSize}

sd "size: \d+" "size: $SIZE" .config/alacritty/alacritty.yml
