#!/bin/sh

TEMPLATES=../templates/ 
DOC2PDF=../fred-doc2pdf 

INPUT=zakerne.xml
# INPUT=expiring.xml
# INPUT=longlist.xml
# output file name - without extension
OUTPUT=zakerne

if [ -n "$1" ]; then
    INPUT=$1
    OUTPUT=${1%.xml}
    echo Input: $INPUT
    echo Output: $OUTPUT
else 
    echo "Specify an XML input file"
    exit 1
fi

xsltproc --stringparam srcpath $TEMPLATES $TEMPLATES/warning_letter.xsl $INPUT > $OUTPUT.rml
$FRED_ROOT/bin/fred-doc2pdf $OUTPUT.rml > $OUTPUT.pdf
evince $OUTPUT.pdf

