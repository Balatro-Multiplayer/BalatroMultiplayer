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
	modHash = 'NULL'
	lobby: Lobby | null = null
	/** Whether player is ready for next blind */
	isReady = false
	lives = 4
	score = 0n
	handsLeft = 4
	ante = 1

	livesBlocker = false

	location = 'loc_selecting'

	constructor(address: Address, send: SendFn, closeConnection: CloseConnFn) {
		this.id = uuidv4()
		this.address = address
		this.sendAction = send
		this.closeConnection = closeConnection
	}

	setLocation = (location: string) => {
		this.location = location
		if (this.lobby) {
			if (this.lobby.host === this) {
				this.lobby.guest?.sendAction({ action: "enemyLocation", location: this.location })
			} else {
				this.lobby.host?.sendAction({ action: "enemyLocation", location: this.location })
			}
		}
	}

	setUsername = (username: string) => {
		this.username = username
		this.lobby?.broadcastLobbyInfo()
	}

	setModHash = (modHash: string) => {
		this.modHash = modHash
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
