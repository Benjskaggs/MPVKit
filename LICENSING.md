# Licensing

This fork exists for two reasons: to build the mpv/FFmpeg stack as **LGPL-2.1**
rather than GPLv3, and to publish the modifications this build makes to mpv — which
the LGPL requires of anyone who distributes a modified version.

It is used by Cue, a closed-source Plex client
for iPhone, iPad and Apple TV. Publishing this repository does not make that app open
source, and is not meant to: LGPL covers the *library*, not the application that links
it. That distinction is the entire reason for the relicensing work below.

The relicensed build lives on branch **`cue-lgpl`**. Branch `main` tracks upstream and
still produces a GPLv3 build.

---

## Which licence covers what

Three separate things, three different answers. Conflating them is the usual source of
confusion here.

| | Licence |
|---|---|
| **This repository's own source** — the Swift package wrapper, the build scripts, `Sources/_MPVKit`, `Sources/_FFmpeg` | **LGPL-3.0**, inherited from upstream. See [`LICENSE`](LICENSE). |
| **The patches in `Sources/BuildScripts/patch/`** | **LGPL-2.1-or-later.** They modify mpv and FFmpeg source files that carry mpv's own LGPL-2.1-or-later header, so the modifications are offered under the same terms. |
| **The build output** — `Libmpv`, `Libav*`, `Libsw*` xcframeworks | **LGPL-2.1-or-later** on branch `cue-lgpl`. GPL-3.0 on `main`. |

The bundled third-party libraries keep their own licences, unchanged by any of this:
libass (ISC), libdav1d and libuavs3d (BSD), libplacebo and libfribidi and libuchardet
(LGPL-2.1+), libdovi and lcms2 and harfbuzz (MIT), MoltenVK and libshaderc
(Apache-2.0), libunibreak (zlib), freetype (FTL or GPLv2 — **FTL is elected here**).

---

## What changed against upstream, and why

Upstream ships a GPL build: FFmpeg configured `--enable-gpl` with `--enable-version3`,
and mpv with `-Dgpl=true`. That combination is GPLv3, which cannot be distributed
through the App Store.

Nothing that required GPL was actually being used. The audit:

| Change | Reason |
|---|---|
| FFmpeg: drop `--enable-gpl` | No GPL-only FFmpeg component is used. The build contains no libpostproc, no x264 and no x265. |
| FFmpeg: drop `--enable-version3` | This flag alone is what made the result v3 rather than v2.1. |
| FFmpeg: drop `--enable-filter=delogo` | The only GPL-only filter that was compiled in. The consuming app uses no video filters at all. |
| FFmpeg: `--disable-openssl`, `--enable-securetransport` | OpenSSL 3.x is Apache-2.0, which is incompatible with LGPL-2.1 — FFmpeg's configure would force `--enable-version3` back on to accept it. Independently, `tls_openssl.c` has no Apple integration: with no `ca_file` it falls back to Unix certificate paths that do not exist inside an iOS sandbox. SecureTransport uses the system trust store. |
| mpv: `-Dgpl=false` | Every gpl-gated feature at v0.41.0 is CDDA, DVB, dvdnav, JACK, OSS, CACA, Direct3D or X11 — optical discs, tuners, and non-Apple platform backends. None is reachable on iOS or tvOS. `-Dcplayer=false` was already set, so the GPL-licensed mpv CLI was never built. |
| mpv: `-Dlibbluray=disabled` | BD-ROM disc structures are never read. Dropping it also drops the libaacs/libbdplus question. |

Two components were checked individually against upstream at tag `v0.41.0`, because
the build genuinely depends on them and losing either would have made this approach
unworkable. Both are **LGPL-2.1-or-later**:

- `audio/filter/af_lavcac3enc.c` — the AC-3 re-encode path
- `video/out/vo_avfoundation.m` — the AVFoundation video output, added downstream by
  patch `0004`, not present upstream

---

## Verifying a build

FFmpeg records its licence in the binary. After building, this must print
`LGPL version 2.1 or later`:

```bash
strings Frameworks/Libavutil.xcframework/ios-arm64/Libavutil.framework/Libavutil \
  | grep "libavutil license"
```

The same binary carries the full configure line, which must contain neither
`--enable-gpl` nor `--enable-version3`:

```bash
strings Frameworks/Libavutil.xcframework/ios-arm64/Libavutil.framework/Libavutil \
  | grep -o '\-\-enable-[a-z0-9-]*' | sort -u
```

---

## Obtaining the source

Everything needed to reproduce the libraries is in this repository: the upstream
sources are fetched by the build scripts at the pinned versions, and every local
modification is a patch file under `Sources/BuildScripts/patch/`. `make build`
reproduces the output.

Note that `Package.swift` on a working checkout may be modified locally to point at
pre-built `Frameworks/*.xcframework` paths, which are `.gitignore`d. That is a
development convenience and is deliberately not committed — it has no effect on what
the libraries contain. The build recipe is `Sources/BuildScripts/XCFrameworkBuild/main.swift`
plus the patch series.

If you received a binary built from this repository and want the corresponding source,
the tag or commit it was built from is the authoritative answer; open an issue if one
is not identified.

---

## Credit

This is a fork of [edde746/MPVKit](https://github.com/edde746/MPVKit), which does the
substantial work of cross-compiling mpv, FFmpeg and their dependencies into
xcframeworks for Apple platforms — including the AVFoundation video output that makes
mpv practical on iOS and tvOS. The changes here are a licensing configuration and a
handful of playback patches on top of that.

[mpv](https://mpv.io) and [FFmpeg](https://ffmpeg.org) are the projects that actually
matter. Please support them.
