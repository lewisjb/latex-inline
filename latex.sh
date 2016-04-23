#!/bin/sh

# latex-inline
# Author: https://github.com/lewisjb

LATEX_ENDINGS=("aux" "log" "pdf" "png")

# Create tmp - LaTeX file to be converted to PNG
printf "%s\n%s\n%s\n%s\n%s" \
	"\\documentclass[convert={density=100}]{standalone}" \
	"\\usepackage{color}" \
	"\\begin{document}" \
	"\\textcolor{white}{\$$1\$}" \
	"\\end{document}" >> tmp

# Create the files
pdflatex -shell-escape tmp > /dev/null

# Get the current cursor position
echo -en "\E[6n"
read -sdR CURPOS
CURPOS=${CURPOS#*[}
# CURPOS = row;col
IFS=';' read -ra POS <<< "$CURPOS"
# POS = (row col)

# Get the terminal height (px)
stty -echo
printf "%b%s" "\033[14t\033[c"

read -t 1 -d c -s -r SIZE; stty echo
HEIGHT=`echo "$SIZE" | awk -F ';' '{print $2}'`

# Terminal rows
ROWS=`tput lines`

# Font height = px/rows
FONTH=$(($HEIGHT / $ROWS))

# Y-offset = Y cursor row * font height
yoff=$(((${POS[0]})*$FONTH))


# Display it
read width height <<< `echo -e "5;tmp.png" | /usr/lib/w3m/w3mimgdisplay`
echo -e "0;1;0;$yoff;$width;$height;;;;;tmp.png\n4;\n3;" | /usr/lib/w3m/w3mimgdisplay

tput cup $((($height/$FONTH)+${POS[0]}+1)) 0

# Cleanup
rm tmp
for i in "${LATEX_ENDINGS[@]}"
do
	rm "tmp.$i"
done
