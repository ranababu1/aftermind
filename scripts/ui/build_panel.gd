class_name BuildPanel
extends PanelContainer
## Build menu: one large card per building with its cost and role. Costs the
## player cannot afford right now are shown in red (and as "need …").

signal building_chosen(definition: BuildingDefinition)
signal closed

const CARD_SIZE := Vector2(330, 190)
const SHORT_COLOR := Color(1.0, 0.45, 0.4)
const COST_COLOR := Color(1.0, 0.78, 0.4)

var _economy: Economy
var _cost_labels: Dictionary = {}


func populate(definitions: Array[BuildingDefinition], economy: Economy) -> void:
	_economy = economy
	for child in get_children():
		child.queue_free()
	_cost_labels.clear()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "BUILD"
	title.theme_type_variation = &"HeadingLabel"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 88)
	close.pressed.connect(func() -> void: closed.emit())
	header.add_child(close)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	layout.add_child(cards)
	for definition in definitions:
		cards.add_child(_card(definition))
	if not economy.changed.is_connected(_on_economy_changed):
		economy.changed.connect(_on_economy_changed)
	refresh()


func refresh() -> void:
	if _economy == null:
		return
	for definition in _cost_labels:
		var label := _cost_labels[definition] as Label
		var affordable := _economy.can_afford(definition.cost())
		label.add_theme_color_override("font_color", COST_COLOR if affordable else SHORT_COLOR)
		label.text = _cost_text(definition) if affordable else "Need " + _cost_text(definition)


func _card(definition: BuildingDefinition) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.pressed.connect(func() -> void: building_chosen.emit(definition))
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 6)
	rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	card.add_child(rows)
	var name_label := Label.new()
	name_label.text = definition.display_name
	name_label.add_theme_font_size_override("font_size", 30)
	rows.add_child(name_label)
	var cost := Label.new()
	cost.add_theme_font_size_override("font_size", 22)
	rows.add_child(cost)
	_cost_labels[definition] = cost
	var summary := Label.new()
	summary.text = definition.summary
	summary.theme_type_variation = &"MutedLabel"
	summary.add_theme_font_size_override("font_size", 20)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size = Vector2(CARD_SIZE.x - 40, 0)
	rows.add_child(summary)
	for label in [name_label, cost, summary]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


static func _cost_text(definition: BuildingDefinition) -> String:
	return cost_text(definition.cost())


## "150 Scrap  ·  50 Energy" for a cost dictionary; zero amounts are omitted.
static func cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(cost.get(Economy.SCRAP, 0)) > 0:
		parts.append("%d Scrap" % int(cost[Economy.SCRAP]))
	if int(cost.get(Economy.ENERGY, 0)) > 0:
		parts.append("%d Energy" % int(cost[Economy.ENERGY]))
	return "  ·  ".join(parts) if not parts.is_empty() else "Free"


func _on_economy_changed(_resource: StringName, _amount: int) -> void:
	if visible:
		refresh()
