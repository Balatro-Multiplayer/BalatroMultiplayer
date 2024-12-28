import { type AddressInfo } from 'node:net'
import { v4 as uuidv4 } from 'uuid'
import type Lobby from './Lobby.js'
import type { ActionServerToClient } from './actions.js'

type SendFn = (action: ActionServerToClient) => void
type CloseConnFn = () => void

/* biome-ignore lint/complexity/noBannedTypes: 
	This is how the net module does it */
type Address = AddressInfo | {}

class Client {
	// Connection info
	id: string
	// Could be useful later on to detect reconnects
	address: Address
	sendAction: SendFn
	closeConnection: CloseConnFn

	// Game info
	username = 'Guest'
	lobby: Lobby | null = null
	/** Whether player is ready for next blind */
	isReady = false
	lives = 4
	score = 0n
	handsLeft = 4
	ante = 1

	livesBlocker = false

	constructor(address: Address, send: SendFn, closeConnection: CloseConnFn) {
		this.id = uuidv4()
		this.address = address
		this.sendAction = send
		this.closeConnection = closeConnection
	}

	setUsername = (username: string) => {
		this.username = username
		this.lobby?.broadcastLobbyInfo()
	}

	setLobby = (lobby: Lobby | null) => {
		this.lobby = lobby
	}

	resetBlocker = () => {
		this.livesBlocker = false
	}

	loseLife = () => {
		if (!this.livesBlocker) {
			this.lives -= 1
			this.livesBlocker = true
			this.sendAction({ action: "playerInfo", lives: this.lives });
		}
	}
}

export default Client
