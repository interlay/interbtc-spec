#!/bin/bash
# build the latex files
sphinx-build -b latex docs build/latex

# create the PDF
make -C build/latex

# open the specification
nohup xdg-open build/latex/*.pdf &>/dev/null &
