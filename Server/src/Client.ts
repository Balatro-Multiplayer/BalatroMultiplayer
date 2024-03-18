import { v4 as uuidv4 } from 'uuid'
import type Lobby from './Lobby.js'
import type net from 'node:net'

type SendFn = (data: string) => void

/* biome-ignore lint/complexity/noBannedTypes: 
	This is how the net module does it */
type Address = net.AddressInfo | {}

class Client {
	// Connection info
	id: string
	// Could be useful later on to detect reconnects
	address: Address
	send: SendFn

	// Game info
	username = 'Guest'
	lobby: Lobby | null = null
	/** Whether player is ready for next blind */
	isReady = false
	// TODO: Set lives based on game mode
	lives = 4
	score = 0
	handsLeft = 4

	constructor(address: Address, send: SendFn) {
		this.id = uuidv4()
		this.address = address
		this.send = send
	}

	setUsername = (username: string) => {
		this.username = username
		this.lobby?.broadcastLobbyInfo()
	}

	setLobby = (lobby: Lobby | null) => {
		this.lobby = lobby
	}
}

export default Client
