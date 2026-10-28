module main

import ui2

fn find_element(el ui2.Element, id string) ?ui2.Element {
	if el.id == id {
		return el
	}
	for child in el.children {
		if found := find_element(child, id) {
			return found
		}
	}
	return none
}

fn test_player_toggle() {
	mut s := PlayerState{}
	assert s.playing == false
	s.toggle()
	assert s.playing == true
	s.toggle()
	assert s.playing == false
}

fn test_player_seek_clamps() {
	mut s := PlayerState{
		duration: 100.0
	}
	s.seek_to(1000)
	assert s.position == 100.0
	s.seek_to(-5)
	assert s.position == 0
	s.seek_to(40)
	s.seek_by(10)
	assert s.position == 50.0
	s.seek_by(-100)
	assert s.position == 0
}

fn test_player_seek_fraction() {
	mut s := PlayerState{
		duration: 200.0
		position: 50.0
	}
	assert s.seek_fraction() == 0.25
	s.seek_to(300)
	assert s.seek_fraction() == 1.0
	mut unknown := PlayerState{}
	assert unknown.seek_fraction() == 0
}

fn test_player_volume_clamps() {
	mut s := PlayerState{}
	s.set_volume(1000)
	assert s.volume == 100.0
	s.set_volume(-1)
	assert s.volume == 0
	s.set_volume(55)
	assert s.volume == 55.0
}

fn test_player_ui_tree_valid() {
	s := PlayerState{
		playing:  true
		position: 30.0
		duration: 120.0
	}
	root := build_player_ui(s)
	ui2.validate_element_tree(root) or { panic(err) }
	play := find_element(root, 'play') or { panic('missing play') }
	assert play.text == 'Pause'
	assert find_element(root, 'back10') or { panic('missing back10') }.text == '-10s'
	assert find_element(root, 'seek') or { panic('missing seek') }.kind == .slider
}

fn test_player_ui_paused_label() {
	s := PlayerState{
		playing: false
	}
	root := build_player_ui(s)
	play := find_element(root, 'play') or { panic('missing play') }
	assert play.text == 'Play'
}
