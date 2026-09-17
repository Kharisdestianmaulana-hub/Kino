#!/bin/bash
SRC="$1"
DEST="Kino/Assets.xcassets/AppIcon.appiconset"

# Resize images
sips -z 16 16 "$SRC" --out "$DEST/mac-16x16@1x.png"
sips -z 32 32 "$SRC" --out "$DEST/mac-16x16@2x.png"
sips -z 32 32 "$SRC" --out "$DEST/mac-32x32@1x.png"
sips -z 64 64 "$SRC" --out "$DEST/mac-32x32@2x.png"
sips -z 128 128 "$SRC" --out "$DEST/mac-128x128@1x.png"
sips -z 256 256 "$SRC" --out "$DEST/mac-128x128@2x.png"
sips -z 256 256 "$SRC" --out "$DEST/mac-256x256@1x.png"
sips -z 512 512 "$SRC" --out "$DEST/mac-256x256@2x.png"
sips -z 512 512 "$SRC" --out "$DEST/mac-512x512@1x.png"
sips -z 1024 1024 "$SRC" --out "$DEST/mac-512x512@2x.png"

# Update Contents.json
cat << 'JSON' > "$DEST/Contents.json"
{
  "images" : [
    {
      "filename" : "mac-16x16@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "mac-16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "mac-32x32@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "mac-32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "mac-128x128@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "mac-128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "mac-256x256@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "mac-256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "mac-512x512@1x.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "mac-512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
