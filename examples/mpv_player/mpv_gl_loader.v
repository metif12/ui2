module main

// mpv_gl_loader selects the OpenGL proc-address resolver that libmpv must
// use with the gg/sokol OpenGL renderer.
//
// Background:
// sokol (and therefore gg) forces EGL even on Linux X11 (see
// vlib/sokol/c/declaration.c.v: SOKOL_FORCE_EGL). On Android it uses
// EGL + OpenGL ES 3. There is no GLX on Android at all.
//
// The Android-only bug:
// A naive integration does one of the following and works on desktop
// Linux but breaks on Android:
//
//   1. C guard `#if defined(__linux__)` for GLX headers/code.
//      The Android NDK compiler defines `__linux__` alongside `__ANDROID__`,
//      so the GLX branch is wrongly taken on Android. The correct C guard is
//      `#if defined(__linux__) && !defined(__ANDROID__)`.
//      (V's own `$if linux` already excludes Android, but raw C does not.)
//   2. get_proc_address = glXGetProcAddress.
//      `<GL/glx.h>` does not exist in the NDK, and at runtime the symbol is
//      NULL on Android. mpv_render_context_create then fails and video stays
//      black while audio keeps playing.
//
// Fix: always use eglGetProcAddress on Linux and Android, and only include
// GLX headers for desktop Linux with the `!defined(__ANDROID__)` guard.
// See mpv_render_d_mpv.c.v for the C side of the fix.

// mpv_proc_loader_name returns the proc resolver mpv must be given in
// mpv_opengl_init_params.get_proc_address for the current target.
pub fn mpv_proc_loader_name() string {
	$if android {
		return 'eglGetProcAddress'
	} $else $if linux {
		return 'eglGetProcAddress'
	} $else $if windows {
		return 'wglGetProcAddress'
	} $else $if macos {
		return 'CGL'
	} $else {
		return 'eglGetProcAddress'
	}
}

// mpv_uses_glx reports whether the fixed loader uses GLX. It must always be
// false: sokol forces EGL on Linux, and Android has no GLX at all.
// The pre-fix code returned true on Linux, which is the bug.
pub fn mpv_uses_glx() bool {
	return false
}

// mpv_buggy_uses_glx documents the old buggy behaviour for regression
// purposes: it returned true on desktop Linux (GLX) and, through the C
// `__linux__` pitfall, also selected GLX on Android where it cannot work.
pub fn mpv_buggy_uses_glx() bool {
	$if linux {
		return true
	} $else {
		return false
	}
}

// mpv_glx_c_guard is the correct C preprocessor guard for any remaining
// desktop-GLX-only code (headers, X11 display params).
pub fn mpv_glx_c_guard() string {
	return '#if defined(__linux__) && !defined(__ANDROID__)'
}

// mpv_buggy_glx_c_guard is the naive guard that caused the Android-only
// breakage: it is true on Android too because the NDK defines `__linux__`.
pub fn mpv_buggy_glx_c_guard() string {
	return '#if defined(__linux__)'
}

// mpv_needs_x11_display reports whether mpv needs MPV_RENDER_PARAM_X11_DISPLAY
// for hardware decoding interop.
pub fn mpv_needs_x11_display() bool {
	$if linux {
		$if sokol_wayland ? {
			return false
		} $else {
			return true
		}
	} $else {
		return false
	}
}

// mpv_needs_wl_display reports whether mpv needs MPV_RENDER_PARAM_WL_DISPLAY.
pub fn mpv_needs_wl_display() bool {
	$if linux {
		$if sokol_wayland ? {
			return true
		} $else {
			return false
		}
	} $else {
		return false
	}
}
