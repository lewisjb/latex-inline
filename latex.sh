#!/usr/bin/env bash

# latex-inline
# Author: https://github.com/lewisjb

LATEX_ENDINGS=("tex" "aux" "log" "pdf" "png")
W3MIMAGEDISPLAY="/usr/lib/w3m/w3mimgdisplay"
FILENAME="tmp"
DEBUG=false
DPI=100
ANCHOR=""

# Output basic usage explanation
usage() {
	echo "Usage: $0 \"<equation>\""
}

# Output full usage explanation
full_usage() {
	usage
	cat << EOF
Flags:
-h | --help		Shows this full help message.
-d | --debug		Enables debugging mode. This puts it in verbose mode,
			and doesn't automatically remove the temp files.
--imgdisplay <path>	Uses path for w3mimgdisplay.
--filename <name>	Uses filename for the temporary files.
--dpi <dpi>		Sets the DPI of the LaTeX equation (def=100).
EOF
}

overflow_warning() {
	echo -e "Warning: Using latex-inline after a whole 'page' of terminal \
history won't work as intended."
}


# Handle flags
while test $# -gt 0 ; do
	case "$1" in
		-h|--help)
			full_usage
			exit 0
			;;
		-d|--debug)
			DEBUG=true
			;;
		--imgdisplay)
			W3MIMAGEDISPLAY="$2"
			shift
			;;
		--filename)
			FILENAME="$2"
			shift
			;;
		--dpi)
			DPI="$2"
			shift
			;;
		*)
			break
			;;
	esac
	shift
done

if [ -z "$1" ]; then
	usage
	exit 1
fi

# Create tmp - LaTeX file to be converted to PNG
cat << EOF > "$FILENAME.tex"
	\\documentclass[convert={density=$DPI}]{standalone}
	\\usepackage{color}
	\\begin{document}
	\\textcolor{white}{\$$1\$}
	\\end{document}
EOF

# Create the files
if [ "$DEBUG" = true ]; then
	pdflatex -shell-escape $FILENAME
else
	pdflatex -shell-escape $FILENAME > /dev/null
fi

# Terminal rows
ROWS=`tput lines`


# Get the current cursor position
echo -en "\E[6n"
read -sdR CURPOS
CURPOS=${CURPOS#*[}
# CURPOS = row;col
IFS=';' read -ra CURPOS <<< "$CURPOS"
# CURPOS = (row col)

CURLINE="${CURPOS[0]}"
if [ "$CURLINE" -eq "$ROWS" ]; then
	overflow_warning
fi


# Get the terminal height (px)
stty -echo
printf "%b%s" "\033[14t\033[c"

read -t 1 -d c -s -r SIZE; stty echo
HEIGHT=`echo "$SIZE" | awk -F ';' '{print $2}'`


# Font height = px/rows
FONTH=$(($HEIGHT / $ROWS))

# Y-offset = Y cursor row * font height
yoff=$((($CURLINE)*$FONTH))
yoff=$(($yoff-$FONTH))

# Get dimensions of image
read width height <<< `echo -e "5;$FILENAME.png" | $W3MIMAGEDISPLAY`
# Move cursor down
tput cup $((($height/$FONTH)+${CURPOS[0]})) 0

# TODO: Find better way, but a delay is needed for tput to take effect
sleep 0.1
# Display it
echo -e "0;1;0;$yoff;$width;$height;;;;;$FILENAME.png\n4;\n3;" | $W3MIMAGEDISPLAY


# Cleanup
if [ "$DEBUG" = false ]; then
	for i in "${LATEX_ENDINGS[@]}"
	do
		rm "$FILENAME.$i"
	done
fi
