extends Control

const URL = "ws://ws.2dgirls.date"
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _verify_user():
	if $Start/UserInput.text.empty():
		$ErrorDiag.dialog_text = "You didn't input a username"
		$ErrorDiag.popup_centered()
		return true
	$Lobby.own_info["name"] = $Start/UserInput.text
	return false

func _on_HostButton_pressed():
	$Lobby/StartButton.disabled = false
	if _verify_user():
		return
	$Client.start(URL)

func _on_ConnectButton_pressed():
	if $Start/ConnectButton/SecretInput.text.empty():
		$ErrorDiag.dialog_text = "The secret is empty!"
		return $ErrorDiag.popup_centered()
	$Lobby/StartButton.disabled = true
	if _verify_user():
		return
	$Client.start(URL, $Start/ConnectButton/SecretInput.text)

func _on_Client_lobby_joined(lobby):
	$Start.visible = false
	$Lobby.visible = true
	$Lobby.show_players()
	$Lobby/SecretEdit.text = lobby
	get_tree().network_peer = $Client.rtc_mp

func _on_Client_disconnected():
	if $Client.code >= 4000:
		$ErrorDiag.dialog_text = $Client.reason
		$ErrorDiag.popup_centered()
