module main

// Regression tests for the Android-only GLX bug.
//
// The bug: desktop code used glXGetProcAddress (and C `#if defined(__linux__)`)
// which also matches Android, where GLX does not exist. The fix forces
// eglGetProcAddress on Linux and Android.

fn test_proc_loader_is_egl_not_glx() {
	loader := mpv_proc_loader_name()
	// Never GLX: the fixed loader uses EGL on Linux/Android, WGL on Windows.
	assert loader != 'glXGetProcAddress'
	assert loader != 'glXGetProcAddressARB'
	$if android {
		assert loader == 'eglGetProcAddress'
	} $else $if linux {
		assert loader == 'eglGetProcAddress'
	} $else $if windows {
		assert loader == 'wglGetProcAddress'
	} $else $if macos {
		assert loader == 'CGL'
	} $else {
		assert loader == 'eglGetProcAddress'
	}
}

fn test_fixed_loader_never_uses_glx() {
	assert mpv_uses_glx() == false
}

fn test_buggy_loader_would_use_glx_on_linux() {
	// Documents what the old code did on desktop Linux. On the fixed code
	// this stays false; the buggy helper returns true on Linux to prove the
	// test can tell them apart.
	$if linux {
		assert mpv_buggy_uses_glx() == true
		assert mpv_uses_glx() == false
	} $else {
		assert mpv_uses_glx() == false
	}
}

fn test_c_guard_excludes_android() {
	guard := mpv_glx_c_guard()
	assert guard.contains('__linux__')
	assert guard.contains('!defined(__ANDROID__)')
	// The buggy guard lacks the Android exclusion and would wrongly match.
	assert !mpv_buggy_glx_c_guard().contains('ANDROID')
}

fn test_no_display_param_on_android() {
	$if android {
		assert mpv_needs_x11_display() == false
		assert mpv_needs_wl_display() == false
	} $else $if linux {
		// Exactly one of X11 / Wayland interop is active on desktop Linux.
		assert mpv_needs_x11_display() != mpv_needs_wl_display()
	} $else {
		assert mpv_needs_x11_display() == false
		assert mpv_needs_wl_display() == false
	}
}
