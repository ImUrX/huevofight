extends Control

var _client = WebSocketClient.new()
var code = 1000
var reason = "Unknown"

var lobby = ""

signal lobby_joined(lobby)
signal connected(id)
signal disconnected()
signal peer_connected(id)
signal peer_disconnected(id)
signal offer_received(id, offer)
signal answer_received(id, answer)
signal candidate_received(id, mid, index, sdp)
signal lobby_sealed()

func _init():
	_client.connect("data_received", self, "_parse_msg")
	_client.connect("connection_established", self, "_connected")
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("server_close_request", self, "_close_request")

func connect_to_url(url):
	close()
	code = 1000
	reason = "Unknown"
	_client.connect_to_url(url)

func close():
	_client.disconnect_from_host()

func join_lobby(lobby):
	return _client.get_peer(1).put_packet(("J: %s\n" % lobby).to_utf8())


func seal_lobby():
	return _client.get_peer(1).put_packet("S: \n".to_utf8())


func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg("C", id, "\n%s\n%d\n%s" % [mid, index, sdp])


func send_offer(id, offer) -> int:
	return _send_msg("O", id, offer)


func send_answer(id, answer) -> int:
	return _send_msg("A", id, answer)

func _closed(was_clean = true):
	emit_signal("disconnected")

func _close_request(code, reason):
	self.code = code
	self.reason = reason

func _connected(protocol = ""):
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	join_lobby(lobby)

func _parse_msg():
	var pkt_str: String = _client.get_peer(1).get_packet().get_string_from_utf8()

	var req: PoolStringArray = pkt_str.split("\n", true, 1)
	if req.size() != 2: # Invalid request size
		return

	var type: String = req[0]
	if type.length() < 3: # Invalid type size
		return

	if type.begins_with("J: "):
		emit_signal("lobby_joined", type.substr(3, type.length() - 3))
		return
	elif type.begins_with("S: "):
		emit_signal("lobby_sealed")
		return

	var src_str: String = type.substr(3, type.length() - 3)
	if not src_str.is_valid_integer(): # Source id is not an integer
		return

	var src_id: int = int(src_str)

	if type.begins_with("I: "):
		emit_signal("connected", src_id)
	elif type.begins_with("N: "):
		# Client connected
		emit_signal("peer_connected", src_id)
	elif type.begins_with("D: "):
		# Client connected
		emit_signal("peer_disconnected", src_id)
	elif type.begins_with("O: "):
		# Offer received
		emit_signal("offer_received", src_id, req[1])
	elif type.begins_with("A: "):
		# Answer received
		emit_signal("answer_received", src_id, req[1])
	elif type.begins_with("C: "):
		# Candidate received
		var candidate: PoolStringArray = req[1].split("\n", false)
		if candidate.size() != 3:
			return
		if not candidate[1].is_valid_integer():
			return
		emit_signal("candidate_received", src_id, candidate[0], int(candidate[1]), candidate[2])

func _send_msg(type, id, data) -> int:
	return _client.get_peer(1).put_packet(("%s: %d\n%s" % [type, id, data]).to_utf8())

func _process(delta):
	var status: int = _client.get_connection_status()
	if status == WebSocketClient.CONNECTION_CONNECTING or status == WebSocketClient.CONNECTION_CONNECTED:
		_client.poll()
