module main

import gg
import os
import sokol.sapp
import ui2

// Android video player using libmpv embedded in the gg OpenGL renderer.
//
// Build matrix:
//   Desktop stub (no libmpv needed, draws placeholder video):
//     v run examples/mpv_player [video.mp4]
//   Desktop with libmpv:
//     v -d mpv run examples/mpv_player [video.mp4]
//   Android with libmpv (needs NDK + libmpv for Android):
//     v -os android -d mpv -o player.apk examples/mpv_player
//   Cross-check the Android-only GLX fix without an NDK:
//     v -os android -check examples/mpv_player
//     v -os linux -check examples/mpv_player
//
// The Android-only bug fixed here: the first render integration used
// glXGetProcAddress (desktop GLX). It worked on Linux but broke on Android
// (no <GL/glx.h> in the NDK, NULL procs at runtime, black video). The fix in
// mpv_gl_loader.v + mpv_render_d_mpv.c.v is to use eglGetProcAddress on both
// Linux and Android, because sokol/gg forces EGL even on X11, and to guard
// any remaining GLX C code with
// `#if defined(__linux__) && !defined(__ANDROID__)`.

struct App {
mut:
	state   PlayerState
	gg      &gg.Context = unsafe { nil }
	video   string
	use_mpv bool
}

fn main() {
	video := if os.args.len > 1 { os.args[1] } else { '' }
	mut app := &App{
		state: PlayerState{
			video_path: video
			duration:   360.0
		}
		video: video
	}
	$if mpv ? {
		app.use_mpv = true
	}
	app.gg = gg.new_context(
		width:        640
		height:       480
		window_title: 'mpv player (gg + ui2)'
		bg_color:     gg.Color{ r: 16, g: 20, b: 24, a: 255 }
		user_data:    app
		frame_fn:     on_frame
		event_fn:     on_event
		init_fn:      on_init
	)
	$if mpv ? {
		mpv_player_init(app)
	}
	app.gg.run()
	$if mpv ? {
		mpv_player_free(app)
	}
}

fn on_init(data voidptr) {
	mut app := unsafe { &App(data) }
	if app.video.len > 0 {
		app.state.video_path = app.video
		$if mpv ? {
			mpv_player_load(app, app.video)
		}
	}
}

fn on_frame(data voidptr) {
	mut app := unsafe { &App(data) }
	ctx := app.gg
	// Advance the stub clock when no real mpv backend is linked so the
	// example animates without libmpv.
	$if mpv ? {
	} $else {
		if app.state.playing {
			app.state.seek_by(1.0 / 60.0)
		}
	}
	draw_video_placeholder(ctx, app)
	draw_player_overlay(ctx, app)
}

// draw_video_placeholder fills the video rect. With `-d mpv` this is where
// mpv_render_context_render goes (same GL context gg owns); without libmpv
// it draws a dark frame plus a stub label so the layout can be tested.
fn draw_video_placeholder(ctx &gg.Context, app &App) {
	ctx.begin()
	mut fw := f32(ctx.width)
	mut fh := f32(ctx.height - 140)
	if fw < 1 {
		fw = 640
	}
	if fh < 1 {
		fh = 340
	}
	ctx.draw_rect_filled(0.0, 0.0, fw, fh, gg.Color{ r: 8, g: 10, b: 14, a: 255 })
	$if mpv ? {
		mpv_player_render(app, int(fw), int(fh))
	} $else {
		msg := if app.use_mpv {
			'mpv frame'
		} else {
			'stub frame (build with -d mpv for real video)'
		}
		ctx.draw_text(int(fw / 2) - 180, int(fh / 2), msg, gg.TextCfg{
			size:  18
			color: gg.Color{ r: 200, g: 210, b: 220, a: 255 }
		})
	}
	// Control bar below the video, driven by the ui2 declarative tree.
	root := build_player_ui(app.state)
	ui2.validate_element_tree(root) or { eprintln('ui2: ${err}') }
	y0 := fh
	// Status line.
	ctx.draw_text(16, int(y0 + 14), app.state.status_text(), gg.TextCfg{
		size:  16
		color: gg.Color{ r: 232, g: 237, b: 242, a: 255 }
	})
	// Play / -10s / +10s buttons (mirrors the ui2 tree ids play/back10/fwd10).
	ctx.draw_rect_filled(16.0, y0 + 40.0, 120.0, 40.0, gg.Color{ r: 52, g: 120, b: 212, a: 255 })
	ctx.draw_text(48, int(y0 + 52), if app.state.playing { 'Pause' } else { 'Play' }, gg.TextCfg{
		size:  16
		color: gg.Color{ r: 255, g: 255, b: 255, a: 255 }
	})
	ctx.draw_rect_filled(144.0, y0 + 40.0, 80.0, 40.0, gg.Color{ r: 42, g: 51, b: 64, a: 255 })
	ctx.draw_text(156, int(y0 + 52), '-10s', gg.TextCfg{
		size:  14
		color: gg.Color{ r: 255, g: 255, b: 255, a: 255 }
	})
	ctx.draw_rect_filled(232.0, y0 + 40.0, 80.0, 40.0, gg.Color{ r: 42, g: 51, b: 64, a: 255 })
	ctx.draw_text(244, int(y0 + 52), '+10s', gg.TextCfg{
		size:  14
		color: gg.Color{ r: 255, g: 255, b: 255, a: 255 }
	})
	// Seek bar (mirrors the ui2 slider id seek).
	bar_x := f32(16)
	bar_y := y0 + 92
	mut bar_w := fw - 32
	if bar_w < 10 {
		bar_w = 600
	}
	ctx.draw_rect_filled(bar_x, bar_y, bar_w, 6.0, gg.Color{ r: 60, g: 70, b: 82, a: 255 })
	ctx.draw_rect_filled(bar_x, bar_y, bar_w * f32(app.state.seek_fraction()), 6.0, gg.Color{
		r: 52
		g: 120
		b: 212
		a: 255
	})
	// Loader line proves which proc resolver is active on this target.
	ctx.draw_text(16, int(y0 + 108), 'gl loader: ${mpv_proc_loader_name()} (glx: ${mpv_uses_glx()})', gg.TextCfg{
		size:  13
		color: gg.Color{ r: 150, g: 165, b: 180, a: 255 }
	})
	ctx.end()
}

// draw_player_overlay is a no-op separator: all overlay drawing happens in
// draw_video_placeholder so there is a single gg begin/end pair per frame.
// gg/sokol allows exactly one active pass; nesting begin/end pairs corrupts
// the frame. mpv must render before gg's pass (to FBO 0), then gg draws on top.
fn draw_player_overlay(ctx &gg.Context, app &App) {
	_ = ctx
	_ = app
}

fn on_event(e &gg.Event, data voidptr) {
	mut app := unsafe { &App(data) }
	if e.typ == .mouse_down {
		x := e.mouse_x
		y := e.mouse_y
		fh := f32(app.gg.height - 140)
		y0 := fh
		if y >= y0 + 40 && y <= y0 + 80 {
			if x >= 16 && x <= 136 {
				app.state.toggle()
				$if mpv ? {
					mpv_player_toggle(app)
				}
			} else if x >= 144 && x <= 224 {
				app.state.seek_by(-10)
				$if mpv ? {
					mpv_player_seek(app, app.state.position)
				}
			} else if x >= 232 && x <= 312 {
				app.state.seek_by(10)
				$if mpv ? {
					mpv_player_seek(app, app.state.position)
				}
			}
		} else if y >= y0 + 88 && y <= y0 + 104 {
			bar_w := f32(app.gg.width) - 32
			if bar_w > 0 {
				mut frac := (x - 16) / bar_w
				if frac < 0 {
					frac = 0
				}
				if frac > 1 {
					frac = 1
				}
				app.state.seek_to(frac * app.state.duration)
				$if mpv ? {
					mpv_player_seek(app, app.state.position)
				}
			}
		}
	}
	if e.typ == .key_down {
		if e.key_code == .space {
			app.state.toggle()
			$if mpv ? {
				mpv_player_toggle(app)
			}
		} else if e.key_code == .left {
			app.state.seek_by(-10)
			$if mpv ? {
				mpv_player_seek(app, app.state.position)
			}
		} else if e.key_code == .right {
			app.state.seek_by(10)
			$if mpv ? {
				mpv_player_seek(app, app.state.position)
			}
		}
	}
	_ = sapp.width()
}

// ── libmpv backend (only with `-d mpv`) ──

$if mpv ? {
	struct MpvBackend {
	mut:
		handle   &C.mpv_handle         = unsafe { nil }
		render   &C.mpv_render_context = unsafe { nil }
		flipy    int                   = 1
		advanced int                   = 1
	}

	__global g_mpv_backend = &MpvBackend{}

	fn mpv_player_init(app &App) {
		mut be := g_mpv_backend
		be.handle = C.mpv_create()
		if be.handle == unsafe { nil } {
			eprintln('mpv: mpv_create failed')
			return
		}
		unsafe {
			C.mpv_set_option_string(be.handle, c'vo', c'libmpv')
			C.mpv_set_option_string(be.handle, c'hwdec', c'auto')
			C.mpv_set_option_string(be.handle, c'audio-client-name', c'mpv-player')
		}
		if C.mpv_initialize(be.handle) < 0 {
			eprintln('mpv: mpv_initialize failed')
			return
		}
		// Render context: API type + EGL proc resolver + advanced control.
		// No X11/WL display is passed on Android (mpv_needs_* is false there).
		api_type := c'opengl'
		mut init_params := C.mpv_opengl_init_params{
			get_proc_address:     mpv_get_proc_address
			get_proc_address_ctx: unsafe { nil }
		}
		mut advanced := 1
		$if linux {
			$if sokol_wayland ? {
				// Wayland hwdec would pass wl_display here.
				_ = mpv_needs_wl_display()
			} $else {
				// X11 hwdec would pass the sapp X11 display here.
				_ = mpv_needs_x11_display()
			}
		}
		mut params := [
			C.mpv_render_param{
				typ:  mpv_render_param_api_type
				data: voidptr(api_type)
			},
			C.mpv_render_param{
				typ:  mpv_render_param_opengl_init_params
				data: voidptr(&init_params)
			},
			C.mpv_render_param{
				typ:  mpv_render_param_advanced_control
				data: voidptr(&advanced)
			},
			C.mpv_render_param{
				typ:  mpv_render_param_invalid
				data: unsafe { nil }
			},
		]!
		if C.mpv_render_context_create(&be.render, be.handle, &params[0]) < 0 {
			eprintln('mpv: render context create failed (gl loader=${mpv_proc_loader_name()})')
			return
		}
		C.mpv_render_context_set_update_callback(be.render, mpv_on_update, unsafe { app })
	}

	fn mpv_on_update(ctx voidptr) {
		// Called by mpv on its internal thread when a new frame is ready.
		// The actual render happens on the gg frame thread; here we only
		// mark that work is pending. Never call mpv_render_* from here.
		_ = ctx
	}

	fn mpv_player_load(app &App, path string) {
		be := g_mpv_backend
		if be.handle == unsafe { nil } {
			return
		}
		cmd := 'loadfile "${path}"'
		unsafe {
			C.mpv_command_string(be.handle, &char(cmd.str))
		}
		_ = app
	}

	fn mpv_player_toggle(app &App) {
		be := g_mpv_backend
		if be.handle == unsafe { nil } {
			return
		}
		val := if app.state.playing { c'no' } else { c'yes' }
		unsafe {
			C.mpv_set_property_string(be.handle, c'pause', val)
		}
	}

	fn mpv_player_seek(app &App, pos f64) {
		be := g_mpv_backend
		if be.handle == unsafe { nil } {
			return
		}
		cmd := 'seek ${int(pos)} absolute'
		unsafe {
			C.mpv_command_string(be.handle, &char(cmd.str))
		}
	}

	fn mpv_player_render(app &App, w int, h int) {
		be := g_mpv_backend
		if be.render == unsafe { nil } {
			return
		}
		// mpv renders into gg/sokol's current FBO (0 = default framebuffer).
		// flip_y = 1 because GL default framebuffer is flipped vs mpv's
		// expectation. Must run on the frame thread with the context current.
		if C.mpv_render_context_update(be.render) == 0 {
			return
		}
		mut fbo := C.mpv_opengl_fbo{
			fbo:             0
			w:               w
			h:               h
			internal_format: 0
		}
		mut flipy := 1
		mut params := [
			C.mpv_render_param{
				typ:  mpv_render_param_opengl_fbo
				data: voidptr(&fbo)
			},
			C.mpv_render_param{
				typ:  mpv_render_param_flip_y
				data: voidptr(&flipy)
			},
			C.mpv_render_param{
				typ:  mpv_render_param_invalid
				data: unsafe { nil }
			},
		]!
		if C.mpv_render_context_render(be.render, &params[0]) < 0 {
			return
		}
		C.mpv_render_context_report_swap(be.render)
		_ = app
	}

	fn mpv_player_free(app &App) {
		mut be := g_mpv_backend
		if be.render != unsafe { nil } {
			C.mpv_render_context_free(be.render)
			be.render = unsafe { nil }
		}
		if be.handle != unsafe { nil } {
			C.mpv_terminate_destroy(be.handle)
			be.handle = unsafe { nil }
		}
		_ = app
	}
} $else {
	// Stub backend so the example builds and runs without libmpv headers.
	fn mpv_player_init(app &App) {
		_ = app
	}

	fn mpv_player_load(app &App, path string) {
		_ = app
		_ = path
	}

	fn mpv_player_toggle(app &App) {
		_ = app
	}

	fn mpv_player_seek(app &App, pos f64) {
		_ = app
		_ = pos
	}

	fn mpv_player_render(app &App, w int, h int) {
		_ = app
		_ = w
		_ = h
	}

	fn mpv_player_free(app &App) {
		_ = app
	}
}
