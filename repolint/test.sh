#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find "$DIR/test" -name '*.sh' | parallel bash {}
