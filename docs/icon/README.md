# App Icon source

`icon-source.svg` — SVG source for the app icon (white background + blue arm-flex).

The path is from [Material Design Icons `arm-flex`](https://pictogrammers.com/library/mdi/icon/arm-flex/)
(Apache 2.0 license, free for commercial use). Wrapped in a 1024×1024 canvas with white
background and recoloured to `#1E5DB8`.

## Regenerate `GymSong/Assets.xcassets/AppIcon.appiconset/icon.png` from this SVG

```sh
mkdir -p /tmp/icon_out
qlmanage -t -s 1024 -o /tmp/icon_out docs/icon/icon-source.svg
# strip alpha channel (iOS app icons must not have one)
sips -s format jpeg /tmp/icon_out/icon-source.svg.png --out /tmp/icon_out/icon.jpg
sips -s format png  /tmp/icon_out/icon.jpg --out GymSong/Assets.xcassets/AppIcon.appiconset/icon.png
```

To change colour or shape: edit `icon-source.svg` (the `<path>`'s `fill` attribute or
the path data itself), then re-run the commands above.
