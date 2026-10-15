#!/usr/bin/env bash
# Regenerates every launcher icon from the SVG sources in assets/icon/.
# Needs ImageMagick 7 built with librsvg (`magick -list format | grep RSVG`).
# Run from the app folder: tool/make_icons.sh
set -euo pipefail

ICON=assets/icon/paisa_icon.svg   # full icon: mark on the green rounded square
MARK=assets/icon/paisa_mark.svg   # mark only, transparent, inside the 66% safe zone
RES=android/app/src/main/res

render() { # svg size out
  magick -background none -density 384 "$1" -resize "$2x$2" -depth 8 -strip "$3"
}

# Legacy launcher icons (Android 7 and older): 48 dp.
for pair in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  dpi=${pair%%:*}; px=${pair##*:}
  mkdir -p "$RES/mipmap-$dpi"
  render "$ICON" "$px" "$RES/mipmap-$dpi/ic_launcher.png"
done

# Adaptive icon layers (Android 8+): 108 dp foreground, plus a white
# silhouette for Android 13 themed (monochrome) icons.
for pair in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  dpi=${pair%%:*}; px=${pair##*:}
  render "$MARK" "$px" "$RES/mipmap-$dpi/ic_launcher_foreground.png"
  # Light parts (wallet, receipt, card) stay; the green details (bars,
  # receipt lines, clasp) become holes, so the mark still reads in one colour.
  magick "$RES/mipmap-$dpi/ic_launcher_foreground.png" \
    \( +clone -alpha off -colorspace gray -threshold 62% \) \
    \( -clone 0 -alpha extract \) -delete 0 -compose multiply -composite \
    -background white -alpha shape -depth 8 -strip "$RES/mipmap-$dpi/ic_launcher_monochrome.png"
done

# Store listing and desktop sizes.
render "$ICON" 512 assets/icon/paisa_icon_512.png

echo "icons regenerated"
