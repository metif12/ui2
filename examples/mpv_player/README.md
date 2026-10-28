# mpv player (gg OpenGL + ui2)

Android-capable video player embedding libmpv in the same OpenGL context
that `gg`/sokol owns, with transport controls described as a `ui2`
declarative tree.

## Layout

- `mpv_gl_loader.v` — pure-V proc-loader selection. Always uses
  `eglGetProcAddress` on Linux/Android. Documents the Android-only GLX bug.
- `mpv_render_d_mpv.c.v` — real libmpv bindings, only with `-d mpv`.
  C GLX headers are guarded by
  `#if defined(__linux__) && !defined(__ANDROID__)` (the fix).
- `player_state.v` — headless `PlayerState` + `build_player_ui()` tree.
- `main.v` — `gg` window: video rect on top, ui2-driven controls below.
  With `-d mpv` it renders via `mpv_render_context_render` into FBO 0;
  without it draws a stub frame so layout/tests run everywhere.
- `mpv_gl_loader_test.v`, `player_state_test.v` — regression tests.

## The Android-only GLX bug

First version used `glXGetProcAddress` and C `#if defined(__linux__)`.
That works on desktop Linux but breaks on Android:

1. The NDK defines `__linux__` alongside `__ANDROID__`, so the GLX branch
   was wrongly taken on Android. V's `$if linux` already excludes Android,
   raw C does not — the guard must spell `!defined(__ANDROID__)` out.
2. `<GL/glx.h>` is absent from the NDK; `glXGetProcAddress` is NULL at
   runtime. `mpv_render_context_create` fails, video stays black while
   audio plays.

Fix: `eglGetProcAddress` on Linux and Android (sokol forces EGL even on
X11, see `SOKOL_FORCE_EGL`), X11/Wayland display params only on desktop
Linux, never on Android.

## Build

```sh
# stub (no libmpv), desktop
v run examples/mpv_player [video.mp4]

# real video, desktop (needs libmpv dev package)
v -enable-globals -d mpv run examples/mpv_player [video.mp4]

# Android (needs NDK + libmpv for Android)
v -enable-globals -os android -d mpv -o player.apk examples/mpv_player

# cross-check the fix without NDK or libmpv
v -os android -check examples/mpv_player
v -os linux -check examples/mpv_player
v -enable-globals -d mpv -os android -check examples/mpv_player
v -enable-globals -d mpv -os linux -check examples/mpv_player
v test examples/mpv_player
```
