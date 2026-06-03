#!/bin/bash -eu
$CXX $CXXFLAGS -o $OUT/dummy_fuzzer $SRC/T2DECODE/.clusterfuzzlite/dummy_fuzzer.cpp $LIB_FUZZING_ENGINE
