module ui2

fn test_components_build_elements() {
	frame := rect(0, 0, 320, 240)
	card_el := card('card1', frame, BoxStyle{}, [])
	assert card_el.kind == .view

	div := divider('div1', rect(0, 0, 320, 8), 0xcbd5e1, 2)
	assert div.kind == .view

	chip_el := chip('chip1', rect(0, 0, 96, 32), 'Chip', BoxStyle{}, TextStyle{})
	assert chip_el.kind == .button

	badge_el := badge('badge1', rect(0, 0, 44, 22), '3', BoxStyle{}, TextStyle{})
	assert badge_el.kind == .view

	fab_el := floating_action_button('fab1', rect(0, 0, 56, 56), '+', BoxStyle{}, TextStyle{})
	assert fab_el.kind == .button

	bar_el := app_bar('bar1', rect(0, 0, 320, 56), 'Title', BoxStyle{}, TextStyle{})
	assert bar_el.kind == .view

	nav_el := bottom_navigation_bar('nav1', rect(0, 0, 320, 56), ['Home', 'Settings'], 0, BoxStyle{}, TextStyle{})
	assert nav_el.kind == .view

	drawer_el := drawer('drawer1', frame, true, BoxStyle{}, [])
	assert drawer_el.kind == .view

	snack_el := snack_bar('snack1', rect(0, 0, 300, 48), 'Done', BoxStyle{}, TextStyle{})
	assert snack_el.kind == .view

	tile_el := list_tile('tile1', rect(0, 0, 260, 64), Element{}, 'Title', 'Subtitle', Element{}, BoxStyle{})
	assert tile_el.kind == .view

	scaffold_el := scaffold('scaffold1', frame, bar_el, card_el, nav_el, BoxStyle{})
	assert scaffold_el.kind == .view
}

fn test_components_vml_round_trip() {
	source := 'Screen { id: Form1 width: 320 height: 240
Card { id: c x: 10 y: 10 width: 100 height: 60 background: #FFFFFF }
Divider { id: d x: 10 y: 80 width: 300 height: 8 color: #CBD5E1 thickness: 2 }
Chip { id: ch x: 10 y: 100 width: 80 height: 32 text: "Chip" }
Badge { id: b x: 100 y: 100 width: 32 height: 20 text: "3" }
FloatingActionButton { id: f x: 260 y: 180 width: 56 height: 56 text: "+" }
AppBar { id: a x: 0 y: 0 width: 320 height: 56 title: "Title" }
SnackBar { id: s x: 10 y: 190 width: 300 height: 48 text: "Done" }
ListTile { id: t x: 10 y: 120 width: 260 height: 64 title: "Item" }
}'
	el := element_from_vml(source, rect(0, 0, 320, 240)) or { panic(err) }
	assert el.kind == .screen
}
