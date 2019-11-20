#!/bin/bash
sphinx-build -b latex docs/source docs/build/latex
make -C docs/build/latex