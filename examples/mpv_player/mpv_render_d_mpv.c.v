module main

// mpv_render_d_mpv.c.v is only compiled with `-d mpv`. It holds the real
// libmpv render-GL bindings with the Android EGL fix.
//
// ── The bug ──
// A first version of this file did:
//
//   #include <GL/glx.h>                       // missing in the Android NDK
//   get_proc = C.glXGetProcAddress             // NULL on Android
//
// guarded in C by `#if defined(__linux__)`. That guard is true on Android
// too (the NDK defines `__linux__` plus `__ANDROID__`), so an Android build
// picked the desktop-GLX path, failed to compile (no glx.h) or, with a
// dlopen fallback, created a render context whose get_proc_address returned
// NULL for every GLES entry. Result: black video, audio OK, only on Android.
//
// ── The fix ──
//  * Use eglGetProcAddress on both Linux and Android. sokol forces EGL even
//    on X11 (SOKOL_FORCE_EGL), so the gg context is always EGL-capable.
//  * Only include GLX headers under
//      #if defined(__linux__) && !defined(__ANDROID__)
//    V's own `$if linux` already excludes Android; raw C must do it by hand.
//  * Never pass MPV_RENDER_PARAM_X11_DISPLAY / WL_DISPLAY on Android.

$if mpv ? {
	#flag -lmpv
	#flag linux -lEGL -lGL -ldl
	#flag android -lEGL -lGLESv3 -llog -landroid
	#flag windows -lopengl32
	#flag macos -framework OpenGL
	#include <mpv/client.h>
	#include <mpv/render.h>
	#include <mpv/render_gl.h>
	#include <EGL/egl.h>
	// Desktop GLX only. The `!defined(__ANDROID__)` is the fix: without it
	// this header is picked on Android where it does not exist.
	#if defined(__linux__) && !defined(__ANDROID__)
	#include <GL/glx.h>
	#endif
}

// Opaque libmpv handles.
struct C.mpv_handle {}

struct C.mpv_render_context {}

// Mirrors mpv_opengl_init_params from render_gl.h.
struct C.mpv_opengl_init_params {
	get_proc_address     fn (ctx voidptr, name &char) voidptr
	get_proc_address_ctx voidptr
}

// Mirrors mpv_opengl_fbo from render_gl.h.
struct C.mpv_opengl_fbo {
	fbo             int
	w               int
	h               int
	internal_format int
}

// Mirrors mpv_render_param from render.h.
struct C.mpv_render_param {
	typ  int
	data voidptr
}

// MPV_RENDER_PARAM_* values (see include/mpv/render.h).
const mpv_render_param_invalid = 0
const mpv_render_param_api_type = 1
const mpv_render_param_opengl_init_params = 2
const mpv_render_param_opengl_fbo = 3
const mpv_render_param_flip_y = 4
const mpv_render_param_depth = 5
const mpv_render_param_x11_display = 8
const mpv_render_param_wl_display = 9
const mpv_render_param_advanced_control = 10

// get_proc_address resolver handed to mpv. Fixed version: EGL everywhere on
// Linux/Android, matching the sokol EGL context gg owns.
fn mpv_get_proc_address(ctx voidptr, name &char) voidptr {
	$if mpv ? {
		$if android || linux {
			return C.eglGetProcAddress(name)
		} $else $if windows {
			// wglGetProcAddress lives in opengl32; sokol already links it.
			return C.wglGetProcAddress(name)
		} $else {
			return C.eglGetProcAddress(name)
		}
	} $else {
		return unsafe { nil }
	}
}

fn C.eglGetProcAddress(name &char) voidptr

$if linux {
	fn C.glXGetProcAddress(name &u8) voidptr
}
$if windows {
	fn C.wglGetProcAddress(name &char) voidptr
}

// Minimal libmpv client API used by main.v.
fn C.mpv_create() &C.mpv_handle
fn C.mpv_initialize(ctx &C.mpv_handle) int
fn C.mpv_terminate_destroy(ctx &C.mpv_handle)
fn C.mpv_set_option_string(ctx &C.mpv_handle, name &char, data &char) int
fn C.mpv_command_string(ctx &C.mpv_handle, args &char) int
fn C.mpv_set_property_string(ctx &C.mpv_handle, name &char, data &char) int
fn C.mpv_render_context_create(res &&C.mpv_render_context, mpv &C.mpv_handle, params &C.mpv_render_param) int
fn C.mpv_render_context_set_update_callback(ctx &C.mpv_render_context, cb fn (ctx voidptr), cb_ctx voidptr)
fn C.mpv_render_context_update(ctx &C.mpv_render_context) u64
fn C.mpv_render_context_render(ctx &C.mpv_render_context, params &C.mpv_render_param) int
fn C.mpv_render_context_report_swap(ctx &C.mpv_render_context)
fn C.mpv_render_context_free(ctx &C.mpv_render_context)
