module vml

fn compile_vml(source string) string {
	root := parse_vml_source(source) or { panic(err) }
	mut compiler := VmlCompiler{}
	return compiler.compile(root)
}

fn test_compiles_a_label_with_text() {
	source := "Label {\n\ttext: 'Hello'\n}"
	root := parse_vml_source(source)!
	assert root.tag == 'Label'
	code := compile_vml(source)
	assert code.starts_with('(fn () ui2.Element {')
	assert code.ends_with('}())')
	assert code.contains('kind: .label')
	assert code.contains("vml_property_0_text := 'Hello'")
	assert code.contains('text: vml_property_0_text')
	assert code.contains('frame: vml_frame_0')
}

fn test_compiles_nested_children() {
	code := compile_vml("Column {\n\tLabel { text: 'A' }\n\tLabel { text: 'B' }\n}")
	assert code.count(' := ui2.Element{') == 3
	assert code.contains("vml_property_0_0_text := 'A'")
	assert code.contains("vml_property_0_1_text := 'B'")
	assert code.contains('vml_children_0 << vml_element_0_0')
	assert code.contains('vml_children_0 << vml_element_0_1')
}

fn test_compiles_interpolated_text() {
	code := compile_vml(r"Label {
	text: 'Count: ${count}'
}")
	assert code.contains(r"'Count: ${count}'")
}

fn test_compiles_declared_property_types() {
	code := compile_vml('Label {
	property int width: 40
}')
	assert code.contains('vml_property_0_width := int(40)')
}

fn test_reports_an_unterminated_node() {
	if _ := parse_vml_source("Label {\n\ttext: 'Hi'\n") {
		assert false, 'expected an error for an unterminated node'
	} else {
		assert err.msg().len > 0
	}
}
