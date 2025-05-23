extends StaticBody2D

class_name AnnotFeature

signal mouse_in
signal mouse_out

var static_body_2d = StaticBody2D.new()
var coll_poly = CollisionPolygon2D.new()
var poly = Polygon2D.new()
var outline = Line2D.new()
var top = 50
var bottom = 100
var outline_width = 1.5
var gff_data = []
var parent_ctg
var name_label = Label.new()
var hovering = false
var selected = false
var id = -1
var default_z = 0
var is_currently_visible = false


func set_top_and_bottom(new_top, new_bottom):
	top = new_top
	bottom = new_bottom
	if "Parent" in gff_data[4] or "parent" in gff_data[4]:
		top += 2
		bottom -= 2
	set_polygon_coords()


func is_rev():
	return gff_data[3]


func is_gap():
	return gff_data[2] == "gap"


func is_on_screen():
	return -Globals.controls_width <= poly.polygon[1].x \
		and poly.polygon[0].x <= Globals.controls_width + Globals.genomes_viewport_width


func update_name_label():
	if poly.polygon[1].x - poly.polygon[0].x > 15:
		name_label.position = Vector2(poly.polygon[0].x + 1, poly.polygon[0].y + 1)
		name_label.set_size(Vector2(poly.polygon[1].x - poly.polygon[0].x - 1, poly.polygon[2].y - poly.polygon[0].y - 1))
		name_label.show()
	else:
		name_label.hide()


func make_visible():
	if is_currently_visible:
		return
	static_body_2d = StaticBody2D.new()
	add_child(static_body_2d)
	coll_poly = CollisionPolygon2D.new()
	static_body_2d.add_child(coll_poly)
	static_body_2d.set_pickable(true)
	static_body_2d.mouse_entered.connect(_on_mouse_entered)
	static_body_2d.mouse_exited.connect(_on_mouse_exited)
	outline.points = poly.polygon
	outline.add_point(outline.points[0])
	coll_poly.polygon = poly.polygon
	is_currently_visible = true
	update_name_label()
	show()
	
	
func make_invisible():
	if not is_currently_visible:
		return
	
	coll_poly.free()
	static_body_2d.free()
	is_currently_visible = false
	hide()


func set_visibility(zoom):
	if not is_on_screen():
		make_invisible()
	elif zoom > Globals.zoom_to_show_annot_all \
		or (zoom > Globals.zoom_to_show_annot_500 and (gff_data[1] - gff_data[0]) >= 500) \
		or (zoom > Globals.zoom_to_show_annot_1k and (gff_data[1] - gff_data[0]) >= 1000) \
		or (zoom > Globals.zoom_to_show_annot_2k and (gff_data[1] - gff_data[0]) >= 2000):
		make_visible()
	else:
		make_invisible()


func set_default_z(z):
	default_z = z
	z_index = z


func set_polygon_coords():
	poly.polygon[0] = Vector2(-(0.5 * outline_width) + parent_ctg.x_start + (parent_ctg.x_end - parent_ctg.x_start) * 1.0 * (gff_data[0]-0.4) / parent_ctg.length_in_bp, top)
	poly.polygon[1] = Vector2((0.5 * outline_width) + parent_ctg.x_start + (parent_ctg.x_end - parent_ctg.x_start) * 1.0 * (gff_data[1]+0.4) / parent_ctg.length_in_bp, top)
	poly.polygon[2] = Vector2(poly.polygon[1].x, bottom)
	poly.polygon[3] = Vector2(poly.polygon[0].x, bottom)

	if not is_currently_visible:
		return
	
	outline.points = poly.polygon
	outline.add_point(outline.points[0])
	coll_poly.polygon = poly.polygon
	update_name_label()


func gff2tooltip(a: Array):
	return parent_ctg.name() + ": " + str(a[0] + 1) + "-" + str(a[1] + 1) + "\n" \
		+ "type=" + a[2] + "\n" \
		+ "tags=" + str(a[4])


func selected_str():
	var tags = []
	for k in gff_data[4]:
		tags.append(k + "=" + gff_data[4][k])
	return str(gff_data[0] + 1) + "-" + str(gff_data[1] + 1) + \
	" / type=" + gff_data[2] + \
	" / " + ";".join(tags) 


func _init(new_id, gff_data_list, new_top, new_bottom, parent_contig):
	id = new_id
	gff_data = gff_data_list
	top = new_top
	bottom = new_bottom
	parent_ctg = parent_contig
	if "Parent" in gff_data[4] or "parent" in gff_data[4]:
		top += 2
		bottom -= 2
		outline_width = 1
	if is_gap():
		outline_width = 0.5
	poly.polygon = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]
	outline.width = outline_width
	outline.default_color = Globals.theme.colours["ui"]["text"]
	poly.color = Globals.theme.colours["ui"]["panel_bg"]
	static_body_2d.set_pickable(true)
	static_body_2d.mouse_entered.connect(_on_mouse_entered)
	static_body_2d.mouse_exited.connect(_on_mouse_exited)
	name_label.add_theme_color_override("font_color", Globals.theme.colours["text"])
	name_label.add_theme_font_override("font", Globals.fonts["dejavu"])
	if is_gap():
		name_label.add_theme_font_size_override("font_size", Globals.font_annot_gap_size)
		poly.color.a = 0.2
		outline.default_color.a = 0.5
	else:
		name_label.add_theme_font_size_override("font_size", Globals.font_annot_size)
	name_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	name_label.clip_text = true
	z_index = 1
	
	for k in ["Name", "name", "ID"]:
		name_label.text = gff_data[4].get(k, "")
		if name_label.text != "":
			break
	if name_label.text == "":
		name_label.text = "UNKNOWN"
	if is_gap():
		name_label.text = ""

	set_polygon_coords()
	add_child(static_body_2d)
	static_body_2d.add_child(coll_poly)
	add_child(poly)
	add_child(outline)
	add_child(name_label)
	hide()


func start_x_coord():
	return poly.polygon[0].x


func select():
	selected = true
	if hovering:
		outline.default_color = Globals.theme.colours["contig"]["edge_selected"]
	else:
		outline.default_color = Globals.theme.colours["ui"]["text"]
		
	poly.color = Globals.theme.colours["ui"]["text"]
	if is_gap():
		poly.color.a = 0.2
	name_label.add_theme_color_override("font_color", Globals.theme.colours["ui"]["general_bg"])
	z_index = 100


func deselect():
	selected = false	
	if hovering:
		outline.default_color = Globals.theme.colours["contig"]["edge_selected"]
	else:
		outline.default_color = Globals.theme.colours["ui"]["text"]
		
	poly.color = Globals.theme.colours["ui"]["panel_bg"]
	if is_gap():
		poly.color.a = 0.2
	name_label.add_theme_color_override("font_color", Globals.theme.colours["text"])
	z_index = default_z


func metadata_has_search_string(search_string):
	for k in gff_data[4]:
		if gff_data[4][k].findn(search_string) != -1:
			return true
	return false


func _on_mouse_entered():
	hovering = true
	outline.default_color = Globals.theme.colours["contig"]["edge_selected"]
	mouse_in.emit(id)


func _on_mouse_exited():
	hovering = false
	if not selected:
		outline.default_color = Globals.theme.colours["ui"]["text"]
	mouse_out.emit(id)
