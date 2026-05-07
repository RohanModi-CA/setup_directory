#!/bin/bash

# Utility to convert images and PDFs to a standardized PDF with size/orientation control.
# Usage: to-pdf.sh <input_file> [--size a4|letter|legal|tabloid|custom W H] [--orientation portrait|landscape|auto]

# Default values
SIZE="letter"
ORIENTATION="auto"
INPUT_FILE=""
OUTPUT_FILE=""
CUSTOM_W=""
CUSTOM_H=""

# Help function
show_help() {
    echo "Usage: $(basename "$0") <input_file> [options]"
    echo ""
    echo "Options:"
    echo "  --size <name>            a4, letter, legal, tabloid (default: letter)"
    echo "  --size custom <W> <H>    Custom size in inches (e.g., --size custom 8.5 11)"
    echo "  --orientation <type>     portrait, landscape, auto (default: auto)"
    echo "  -o, --output <file>      Specify output filename (default: input_basename.pdf)"
    echo ""
    exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --size)
            if [[ "$2" == "custom" ]]; then
                SIZE="custom"
                CUSTOM_W="$3"
                CUSTOM_H="$4"
                shift 3
            else
                SIZE="$2"
                shift 1
            fi
            ;;
        --orientation) ORIENTATION="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        -h|--help) show_help ;;
        *) 
            if [[ -z "$INPUT_FILE" ]]; then
                INPUT_FILE="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

if [[ -z "$INPUT_FILE" ]]; then
    show_help
fi

# Determine output filename if not provided
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="${INPUT_FILE%.*}.pdf"
    if [[ "$OUTPUT_FILE" == "$INPUT_FILE" ]]; then
        OUTPUT_FILE="${INPUT_FILE}_converted.pdf"
    fi
fi

# Temporary file for conversion
TMP_PDF="/tmp/to-pdf-$(date +%s).pdf"

# 1. Convert to PDF if it's an image
FILE_TYPE=$(file --mime-type -b "$INPUT_FILE")

case "$FILE_TYPE" in
    image/*)
        echo "Converting image to temporary PDF..."
        convert -density 300 "$INPUT_FILE" "$TMP_PDF"
        INPUT_TO_GS="$TMP_PDF"
        ;;
    application/pdf)
        INPUT_TO_GS="$INPUT_FILE"
        ;;
    *)
        echo "Error: Unsupported file type $FILE_TYPE"
        exit 1
        ;;
esac

# 2. Ghostscript Resizing/Orientation Logic
GS_OPTS="-o $OUTPUT_FILE -sDEVICE=pdfwrite -dFIXEDMEDIA -dPDFFitPage"

# Map sizes to points (1/72 inch)
case "$SIZE" in
    a4)      W=595; H=842 ;;
    letter)  W=612; H=792 ;;
    legal)   W=612; H=1008 ;;
    tabloid) W=792; H=1224 ;;
    custom)
        # Convert inches to points using bc
        W=$(echo "$CUSTOM_W * 72" | bc)
        H=$(echo "$CUSTOM_H * 72" | bc)
        ;;
    *) echo "Error: Unknown size $SIZE"; exit 1 ;;
esac

# Function to ensure W <= H (Portrait) or W >= H (Landscape)
# For 'auto', we'll use the provided W and H as given but still allow GS to rotate pages per-page.
ensure_portrait() {
    if (( $(echo "$W > $H" | bc -l) )); then
        local temp=$W
        W=$H
        H=$temp
    fi
}

ensure_landscape() {
    if (( $(echo "$W < $H" | bc -l) )); then
        local temp=$W
        W=$H
        H=$temp
    fi
}

# Apply orientation logic
case "$ORIENTATION" in
    portrait)
        ensure_portrait
        GS_OPTS="$GS_OPTS -dDEVICEWIDTHPOINTS=$W -dDEVICEHEIGHTPOINTS=$H -dAutoRotatePages=/None"
        ;;
    landscape)
        ensure_landscape
        GS_OPTS="$GS_OPTS -dDEVICEWIDTHPOINTS=$W -dDEVICEHEIGHTPOINTS=$H -dAutoRotatePages=/None"
        ;;
    auto)
        # For 'auto', the longer of the two dimensions will be the orientation.
        # This is handled by Ghostscript per page by default with /PageByPage.
        # But we need to define the target media size for the container.
        # We'll default to portrait container if not custom, or custom dimensions as provided.
        if [[ "$SIZE" != "custom" ]]; then
            # Standard sizes use the PAPERSIZE setting for auto
            GS_OPTS="$GS_OPTS -sPAPERSIZE=$SIZE -dAutoRotatePages=/PageByPage"
        else
            # Custom sizes use points
            GS_OPTS="$GS_OPTS -dDEVICEWIDTHPOINTS=$W -dDEVICEHEIGHTPOINTS=$H -dAutoRotatePages=/PageByPage"
        fi
        ;;
    *) echo "Error: Unknown orientation $ORIENTATION"; exit 1 ;;
esac

echo "Finalizing PDF ($SIZE, $ORIENTATION) -> $OUTPUT_FILE"
gs $GS_OPTS "$INPUT_TO_GS"

# Cleanup
if [[ -f "$TMP_PDF" ]]; then
    rm "$TMP_PDF"
fi

echo "Done."
