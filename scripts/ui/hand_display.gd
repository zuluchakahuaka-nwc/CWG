extends Control

var _hand: Hand = null
var _card_widgets: Array = []
var _max_display: int = 7

signal card_selected(data: Dictionary)
signal card_played(data: Dictionary)

@onready var _cards_container: HBoxContainer = $CardsContainer

func _ready() -> void:
	pass

func set_hand(hand: Hand) -> void:
	_hand = hand
	refresh_display()

func refresh_display() -> void:
	_clear_widgets()
	if _hand == null:
		return
	var cards: Array = _hand.get_all()
	for i in range(mini(cards.size(), _max_display)):
		var widget: CardWidget = CardWidget.new()
		widget.setup(cards[i])
		widget.card_selected.connect(_on_card_selected)
		widget.card_played.connect(_on_card_played)
		_cards_container.add_child(widget)
		_card_widgets.append(widget)

func _clear_widgets() -> void:
	for w in _card_widgets:
		if is_instance_valid(w):
			w.queue_free()
	_card_widgets.clear()

func _on_card_selected(data: Dictionary) -> void:
	card_selected.emit(data)

func _on_card_played(data: Dictionary) -> void:
	card_played.emit(data)

func highlight_playable(available_money: int) -> void:
	for w in _card_widgets:
		var cost: int = w.get_card_data().get("cost", 0)
		if cost <= available_money:
			w.modulate = Color.WHITE
		else:
			w.modulate = Color(0.5, 0.5, 0.5, 0.7)
