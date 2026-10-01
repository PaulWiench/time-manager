# Stamped app icon: implementation handoff

Final design: **Sun Dial** (round 1, A). The app's progress ring as the mark: one apricot lap of the workday with the sun knob riding its end, eight engraved hour ticks, on the dusk slab. Dark is the launcher icon, exactly as shown in round 1. Light is the same mark for light surfaces (in-app, docs, store-style listings).

Audience: Claude Code, working in `PaulWiench/time-manager` (Flutter, Android). `preview.png` shows everything at a glance.

## 1. What to do

1. Copy `android/app/src/main/res/` over the project's `android/app/src/main/res/`. This **replaces** the Flutter template's `mipmap-*/ic_launcher.png` and adds:
   - `drawable/ic_launcher_background.xml`, `drawable/ic_launcher_foreground.xml`, `drawable/ic_launcher_monochrome.xml` (adaptive layers, vector, 108 dp canvas)
   - `mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml` (adaptive icon with the `<monochrome>` layer for Android 13+ themed icons)
   - `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` and `ic_launcher_round.png` (48/72/96/144/192 px, circle, for API < 26)
   - `drawable/ic_stamped_logo_light_background.xml`, `drawable/ic_stamped_logo_light_foreground.xml` (light variant as vectors, optional; not used by the launcher)
2. In `android/app/src/main/AndroidManifest.xml`, on `<application>`: `android:icon="@mipmap/ic_launcher"` and add `android:roundIcon="@mipmap/ic_launcher_round"`. If the app is being renamed, set `android:label="Stamped"` too.
3. Do **not** add `flutter_launcher_icons`; it would overwrite these files.
4. Optional, for the in-app logo (About screen, onboarding): copy `svg/stamped-logo-dark.svg` and `svg/stamped-logo-light.svg` to `assets/branding/`, register them in `pubspec.yaml`, render with `flutter_svg`, and pick by brightness (dark logo on `slab`/dark surfaces, light logo on `background`/`surface` in light mode). PNGs at 512/1024 are in `png/` if a raster is easier.
5. Optional, Android 12+ splash: `windowSplashScreenAnimatedIcon` = `@drawable/ic_launcher_foreground`, `windowSplashScreenBackground` = `#2E2447` (`slab`).
6. Build and check on the Pixel 4a: launcher (circle), Settings → Wallpaper & style → Themed icons on, and a light and a dark wallpaper.

Launcher icons do not switch with the system theme on Android. The adaptive icon is always the dark version; Android 13+ themed icons use the monochrome layer and tint it to match the wallpaper, which covers "light mode" on the home screen.

## 2. Files

| File | What |
|---|---|
| `svg/stamped-logo-dark.svg`, `svg/stamped-logo-light.svg` | Logo, circle-masked (viewBox = the visible 72 dp), 512 px nominal |
| `svg/adaptive/dark/background.svg`, `foreground.svg` | Launcher layers on the 108 dp canvas, production-clean |
| `svg/adaptive/light/background.svg`, `foreground.svg` | Light layers, same geometry |
| `svg/adaptive/monochrome.svg` | Themed-icon layer: one colour (`#000000`) on transparent |
| `svg/adaptive/*/foreground-guides.svg`, `*/composite-guides.svg`, `monochrome-guides.svg` | Same layers with the guides drawn: magenta dashed = 108 dp canvas, blue dashed = 72 dp visible viewport (r 36), red = 66 dp safe zone (r 33). Reference only, never ship. |
| `android/…` | Ready-to-copy Android resources (§1) |
| `png/stamped-logo-{dark,light}-{512,1024}.png` | Rasters, transparent outside the circle |
| `preview.png` | Overview of both versions, layers, guides and 48 dp use |

## 3. Geometry (108 dp canvas, centre 54/54)

| Element | Value |
|---|---|
| Track ring | circle r 21, stroke 10 (spans r 16–26) |
| Lap arc | from 12 o'clock clockwise to 280° (0.78 of a lap), stroke 10, round caps |
| Hour ticks | 8 at 45° steps, from r 18 to r 24, stroke 1.6, round caps, drawn over track and arc |
| Knob | circle r 7.5 centred at (33.32, 50.35), i.e. on the ring at 280°, with a 3 dp stroke in the ground colour (the "cut") |
| Outermost ink | r 30 (knob edge incl. cut) → inside the 33 dp safe zone with 3 dp to spare |
| Monochrome | track at 35 % alpha, arc at 100 %, knob as a solid r 9 disc; no ticks or cuts, because a themed icon is one tint |

Same proportions as the in-app ring (base handoff §5.1): stroke/radius ≈ 0.48 here vs 0.24 in-app, doubled so the ring survives 48 dp.

## 4. Colours and tokens (Golden Hour)

| Part | Dark (launcher) | Light |
|---|---|---|
| Background layer | `slab` `#2E2447` | `background` `#FAF5EE` |
| Track | `slabTrack` `#4B4068` | `divider` `#E4DACB` |
| Lap arc + knob | `accentFill` `#F7B27A` | `accentStrong` `#D9691C` |
| Ticks + knob cut | `slab` `#2E2447` | `background` `#FAF5EE` |
| Monochrome | `#000000` on transparent (the system tints it) | (same layer) |

All values are the **light-theme** hex of each Golden Hour token, because an icon is a single fixed image. **No new tokens.** The light version follows Golden Hour's own rule that thin marks on light grounds use `accentStrong` instead of `accentFill` (3.5:1 on white, versus 1.6:1).

Flutter constants, if the logo is drawn in code instead of from SVG:
```dart
// Stamped logo, dark
const logoDarkBg = Color(0xFF2E2447);    // slab
const logoDarkTrack = Color(0xFF4B4068); // slabTrack
const logoDarkMark = Color(0xFFF7B27A);  // accentFill
// Stamped logo, light
const logoLightBg = Color(0xFFFAF5EE);    // background
const logoLightTrack = Color(0xFFE4DACB); // divider
const logoLightMark = Color(0xFFD9691C);  // accentStrong
```

## 5. Rationale

- **It is the app.** The ring that fills one lap per workday is the most-seen pixel in Stamped (Home and widget). The icon is the same object, so the home screen, the widget and the app read as one thing.
- **Stamped, literally.** The knob is where the day's stamp currently sits; the gap behind it is the time still to work. The eight engraved ticks are the hours of a Stempelkarte line.
- **Built for 48 dp.** One bold shape (ring + knob) with a strong value contrast: apricot on violet is 8:1, so it holds on busy light and dark wallpapers; the ticks are a bonus detail at large sizes and can disappear at 48 dp without hurting recognition.
- **Mask-safe.** Everything sits in a centred circle of r 30, so circle, squircle and rounded-square masks crop only the background.
- **Themed icons.** The monochrome layer keeps the silhouette (full lap, knob) and shows the unfilled part as a 35 % tint, so the "lap" idea survives in a single colour.
