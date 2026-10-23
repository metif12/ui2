module ui2

// Reusable, higher-level components inspired by Flutter's widget catalog.
// Each helper returns an ordinary Element, so it composes with every other
// ui2 primitive and renders on every backend.

pub fn divider(id string, frame Rect, color u32, thickness f64) Element {
	mut box := BoxStyle{
		bg: color
	}
	_ = box
	if thickness <= 0 {
		return view(id, frame, BoxStyle{ bg: color, transparent: false }, [])
	}
	// A horizontal divider fills the frame height with the requested thickness.
	mut h := thickness
	if h > frame.height && frame.height > 0 {
		h = frame.height
	}
	return view(id, rect(frame.x, frame.y + (frame.height - h) / 2, frame.width, h), BoxStyle{
		bg:     color
		radius: h / 2
	}, [])
}

pub fn card(id string, frame Rect, box_ BoxStyle, children []Element) Element {
	b := BoxStyle{
		...box_
		bg:     if box_.bg == 0 { u32(0xffffff) } else { box_.bg }
		radius: if box_.radius == 0 { 12.0 } else { box_.radius }
	}
	return view(id, frame, b, children)
}

pub fn list_tile(id string, frame Rect, leading Element, title string, subtitle string, trailing Element, box_ BoxStyle) Element {
	mut children := []Element{}
	mut x := 12.0
	if leading.id.len > 0 || leading.kind != .view {
		// accept any element as leading
	}
	if leading.frame.width > 0 || leading.id.len > 0 || leading.kind != .view {
		le := leading
		children << le
		x += le.frame.width + 12
	}
	title_style := TextStyle{ color: 0x111111, size: 15, bold: true }
	children << label('${id}_title', title, rect(x, 8, frame.width - x - 12, 20), title_style)
	if subtitle.len > 0 {
		sub_style := TextStyle{ color: 0x64748b, size: 12 }
		children << label('${id}_subtitle', subtitle, rect(x, 28, frame.width - x - 12, 16), sub_style)
	}
	if trailing.frame.width > 0 || trailing.id.len > 0 || trailing.kind != .view {
		tr := trailing
		children << tr
	}
	return view(id, frame, box_, children)
}

pub fn chip(id string, frame Rect, text string, box_ BoxStyle, style TextStyle) Element {
	b := BoxStyle{
		...box_
		bg:     if box_.bg == 0 { u32(0xe2e8f0) } else { box_.bg }
		radius: if box_.radius == 0 { frame.height / 2 } else { box_.radius }
	}
	return button(id, text, frame, b, style)
}

pub fn badge(id string, frame Rect, text string, box_ BoxStyle, style TextStyle) Element {
	b := BoxStyle{
		...box_
		bg:     if box_.bg == 0 { u32(0xef4444) } else { box_.bg }
		radius: if box_.radius == 0 { frame.height / 2 } else { box_.radius }
	}
	s := if style.color == 0x111111 {
		TextStyle{ ...style, color: 0xffffff, size: if style.size == 15 { 11.0 } else { style.size } }
	} else {
		TextStyle{ ...style, size: if style.size == 15 { 11.0 } else { style.size } }
	}
	return view(id, frame, b, [label('${id}_text', text, rect(0, 0, frame.width, frame.height), s)])
}

pub fn floating_action_button(id string, frame Rect, icon string, box_ BoxStyle, style TextStyle) Element {
	b := BoxStyle{
		...box_
		bg:     if box_.bg == 0 { u32(0x2563eb) } else { box_.bg }
		radius: if box_.radius == 0 { frame.width / 2 } else { box_.radius }
	}
	s := TextStyle{
		...style
		color: if style.color == 0x111111 { u32(0xffffff) } else { style.color }
		size:  if style.size == 15 { 22.0 } else { style.size }
		align: .center
	}
	return button(id, icon, frame, b, s)
}

pub fn app_bar(id string, frame Rect, title string, box_ BoxStyle, style TextStyle) Element {
	b := BoxStyle{
		...box_
		bg: if box_.bg == 0 { u32(0x2563eb) } else { box_.bg }
	}
	s := TextStyle{
		...style
		color: if style.color == 0x111111 { u32(0xffffff) } else { style.color }
		size:  if style.size == 15 { 18.0 } else { style.size }
		bold:  true
	}
	return view(id, frame, b, [label('${id}_title', title, rect(16, (frame.height - s.size) / 2, frame.width - 32, s.size + 4), s)])
}

pub fn scaffold(id string, frame Rect, app_bar_el Element, body Element, bottom_nav Element, box_ BoxStyle) Element {
	mut children := []Element{}
	body_y := if app_bar_el.id.len > 0 || app_bar_el.kind != .view { 56.0 } else { 0.0 }
	if app_bar_el.id.len > 0 || app_bar_el.kind != .view {
		ab_h := if app_bar_el.frame.height == 0 { 56.0 } else { app_bar_el.frame.height }
		ab_w := if app_bar_el.frame.width == 0 { frame.width } else { app_bar_el.frame.width }
		ab := Element{ ...app_bar_el, frame: rect(0, 0, ab_w, ab_h) }
		children << ab
	}
	mut body_w := body.frame.width
	if body_w == 0 { body_w = frame.width }
	mut body_h := body.frame.height
	if body_h == 0 { body_h = frame.height - body_y }
	body_el := Element{ ...body, frame: rect(0, body_y, body_w, body_h) }
	children << body_el
	if bottom_nav.id.len > 0 || bottom_nav.kind != .view {
		bn_h := if bottom_nav.frame.height == 0 { 56.0 } else { bottom_nav.frame.height }
		bn_w := if bottom_nav.frame.width == 0 { frame.width } else { bottom_nav.frame.width }
		bn := Element{ ...bottom_nav, frame: rect(0, frame.height - bn_h, bn_w, bn_h) }
		children << bn
	}
	return view(id, frame, box_, children)
}

pub fn bottom_navigation_bar(id string, frame Rect, items []string, selected int, box_ BoxStyle, style TextStyle) Element {
	mut children := []Element{}
	n := if items.len > 0 { items.len } else { 1 }
	item_w := frame.width / n
	for i, item in items {
		s := if i == selected {
			TextStyle{ ...style, bold: true, color: u32(0x2563eb) }
		} else {
			TextStyle{ ...style, color: u32(0x64748b) }
		}
		children << label('${id}_item_${i}', item, rect(f64(i) * item_w, 8, item_w, frame.height - 16), s)
	}
	b := BoxStyle{
		...box_
		bg: if box_.bg == 0 { u32(0xffffff) } else { box_.bg }
	}
	return view(id, frame, b, children)
}

pub fn drawer(id string, frame Rect, open bool, box_ BoxStyle, children []Element) Element {
	if !open {
		return view(id, rect(0, 0, 0, 0), BoxStyle{ transparent: true }, [])
	}
	b := BoxStyle{
		...box_
		bg: if box_.bg == 0 { u32(0xffffff) } else { box_.bg }
	}
	mut w := frame.width * 0.75
	if w > 320 {
		w = 320
	}
	return view(id, rect(0, 0, w, frame.height), b, children)
}

pub fn snack_bar(id string, frame Rect, text string, box_ BoxStyle, style TextStyle) Element {
	b := BoxStyle{
		...box_
		bg:     if box_.bg == 0 { u32(0x323232) } else { box_.bg }
		radius: if box_.radius == 0 { 4.0 } else { box_.radius }
	}
	s := TextStyle{
		...style
		color: if style.color == 0x111111 { u32(0xffffff) } else { style.color }
	}
	return view(id, frame, b, [label('${id}_text', text, rect(16, (frame.height - s.size) / 2, frame.width - 32, s.size + 4), s)])
}
