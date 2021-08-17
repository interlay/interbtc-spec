#!/bin/bash
# build the latex files
sphinx-build -b latex docs/source docs/build/latex

# create the PDF
make -C docs/build/latex

# open the specification
nohup xdg-open docs/build/latex/*.pdf &>/dev/null &