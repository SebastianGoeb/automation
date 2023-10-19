#!/bin/bash

find test -name '*.sh' | parallel bash {}
