extends Node
class_name CurrencyCheck


signal transaction_success()
signal transaction_failed()


@export_group("Currency Check Settings")
##How much it costs to use this button, If set to 0 currency interaction will be ignored
@export var currency_cost : int = 0
##Text that joins Press & Cost for Interaction 
@export var currency_text_joiner : String = " | Cost: "
##Name of the currency needed for this interaction to proceed - default is credits
@export var currency_name : String = "credits"
##Currency icon location for Interaction UI
@export var currency_icon = "res://addons/cogito/Assets/Graphics/UiIcons/Ui_Icon_Currency.png"
##Hint that displays if player doesn't have enough currency to interact
@export var not_enough_currency_hint : String
##Should the player lose money after Currency check?
@export var apply_transaction : bool = true


var player_interaction_component : PlayerInteractionComponent
var icon_bbcode : String
var currency_text : String


func _ready():
	if currency_cost != 0: 
		icon_bbcode = "[img width=16 height=16]" + currency_icon + "[/img]"
		currency_text = currency_text_joiner + str(currency_cost) + icon_bbcode + " "
 

func check_for_currency(player: Node) -> bool:
	var found_currency
	for attribute in player.find_children("", "CogitoCurrency", false):
		if attribute is CogitoCurrency and attribute.currency_name == currency_name:
			found_currency = attribute
			break
	
	if found_currency and found_currency.value_current >= currency_cost:
		if apply_transaction:
			found_currency.value_current -= currency_cost
		transaction_success.emit()
		return true
	else:
		transaction_failed.emit()
		return false
