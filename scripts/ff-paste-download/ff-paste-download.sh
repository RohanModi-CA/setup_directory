#!/bin/bash

# This script takes an image from the clipboard and "downloads" it into Firefox.
# VERSION 3: Uses a single, permanent HTML file in the user's home directory
# to avoid Snap sandbox permission issues with /tmp.

# --- Configuration ---
# We'll create the HTML file in your home directory. It will be overwritten each time.
HTML_FILE="clipboard_to_firefox.html"
IMAGE_TYPE="image/png"
FILENAME_BASE="pasted-image"
# -------------------

# Create a unique filename for the image download with a timestamp.
FILENAME="${FILENAME_BASE}-$(date +%Y-%m-%d_%H-%M-%S).png"

# Attempt to get the image data from the clipboard.
CLIPBOARD_DATA=$(xclip -selection clipboard -t "$IMAGE_TYPE" -o 2>/dev/null)

if [ -z "$CLIPBOARD_DATA" ]; then
    notify-send "Clipboard Download Failed" "No image found on the clipboard."
    exit 1
fi

# Encode the raw image data into Base64.
ENCODED_DATA=$(echo -n "$CLIPBOARD_DATA" | base64 -w 0)

# Overwrite our permanent HTML file with the new image data.
cat <<EOF > "$HTML_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>Downloading...</title>
</head>
<body onload="document.getElementById('downloadLink').click(); setTimeout(function() { window.close(); }, 500);">
    <a id="downloadLink" href="data:${IMAGE_TYPE};base64,${ENCODED_DATA}" download="${FILENAME}"></a>
</body>
</html>
EOF

# Open the HTML file in a new Firefox tab.
# Since the file is in your home directory, the Firefox Snap can access it.
firefox --new-tab "$HTML_FILE" &

notify-send "Image Download Started" "Saving '${FILENAME}' to Firefox downloads."

exit 0
