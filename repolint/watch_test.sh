#!/bin/bash

find test -name '*.sh' | entr ./test.sh
