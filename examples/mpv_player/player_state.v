module main

import ui2

// PlayerState is the headless playback model shared by the gg renderer and
// the ui2 declarative tree. Keeping it free of gg/sokol calls makes it
// unit-testable on the host without a window or libmpv.
pub struct PlayerState {
pub mut:
	video_path string
	playing    bool
	position   f64 // seconds
	duration   f64 // seconds, 0 when unknown
	volume     f64 = 100.0
	muted      bool
}

// toggle flips the playing flag.
pub fn (mut s PlayerState) toggle() {
	s.playing = !s.playing
}

// seek_by moves position by delta seconds and clamps into [0, duration]
// (or [0, +inf) when duration is unknown).
pub fn (mut s PlayerState) seek_by(delta f64) {
	s.seek_to(s.position + delta)
}

// seek_to moves position to an absolute time and clamps it.
pub fn (mut s PlayerState) seek_to(pos f64) {
	mut p := pos
	if p < 0 {
		p = 0
	}
	if s.duration > 0 && p > s.duration {
		p = s.duration
	}
	s.position = p
}

// seek_fraction returns position / duration in [0, 1]. It is 0 when duration
// is unknown.
pub fn (s PlayerState) seek_fraction() f64 {
	if s.duration <= 0 {
		return 0
	}
	f := s.position / s.duration
	if f < 0 {
		return 0
	}
	if f > 1 {
		return 1
	}
	return f
}

// set_volume clamps volume into [0, 100].
pub fn (mut s PlayerState) set_volume(v f64) {
	mut nv := v
	if nv < 0 {
		nv = 0
	}
	if nv > 100 {
		nv = 100
	}
	s.volume = nv
}

// status_text is the one-line status shown under the video.
pub fn (s PlayerState) status_text() string {
	state := if s.playing { 'playing' } else { 'paused' }
	return '${state} ${int(s.position)}s / ${int(s.duration)}s vol ${int(s.volume)}'
}

// build_player_ui builds the declarative ui2 tree for the player controls.
// The gg frame callback draws the video rect first, then draws these controls
// on top. Validating the tree with ui2.validate_element_tree catches
// duplicate ids before any native state is touched.
pub fn build_player_ui(s PlayerState) ui2.Element {
	play_label := if s.playing { 'Pause' } else { 'Play' }
	return ui2.screen(0x101418, [
		ui2.label('status', s.status_text(), ui2.rect(16, 12, 600, 24), ui2.TextStyle{
			color: 0xe8edf2
			size:  15
		}),
		ui2.button('play', play_label, ui2.rect(16, 44, 120, 40), ui2.BoxStyle{
			bg:     0x3478d4
			radius: 8
		}, ui2.TextStyle{
			color: 0xffffff
			size:  16
		}),
		ui2.button('back10', '-10s', ui2.rect(144, 44, 80, 40), ui2.BoxStyle{
			bg:     0x2a3340
			radius: 8
		}, ui2.TextStyle{
			color: 0xffffff
			size:  14
		}),
		ui2.button('fwd10', '+10s', ui2.rect(232, 44, 80, 40), ui2.BoxStyle{
			bg:     0x2a3340
			radius: 8
		}, ui2.TextStyle{
			color: 0xffffff
			size:  14
		}),
		ui2.slider(ui2.SliderConfig{
			id:    'seek'
			frame: ui2.rect(16, 92, 600, 32)
			min:   0.0
			max:   100.0
			value: s.seek_fraction() * 100.0
		}),
	])
}
