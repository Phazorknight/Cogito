extends Control

@onready var currency_icon: TextureRect = $HBoxContainer/CurrencyIcon
@onready var currency_label_value: Label = $HBoxContainer/CurrencyLabelValue
@onready var currency_label_max: Label = $HBoxContainer/CurrencyLabelMax

var assigned_player_currency : CogitoCurrency

func initiate_currency_ui(_player_currency: CogitoCurrency):
	assigned_player_currency = _player_currency
	
	#Setting up icon and labels
	currency_icon.texture = assigned_player_currency.currency_icon
	currency_label_value.text = str(assigned_player_currency.value_current)
	currency_label_max.text = str(assigned_player_currency.value_max)
	
	_player_currency.currency_changed.connect(on_currency_changed)
	
	
func on_currency_changed(_currency_name:String,_value_current:float,_value_max:float,_has_increased:bool):
	currency_label_value.text = str(int(_value_current))
