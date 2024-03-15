import { v4 as uuidv4 } from 'uuid'
import type Lobby from './Lobby.js'
import type net from 'node:net'

type SendFn = (data: string) => void

/* biome-ignore lint/complexity/noBannedTypes: 
	This is how the net module does it */
type Address = net.AddressInfo | {}

class Client {
	id: string
	// Could be useful later on to detect reconnects
	address: Address
	username: string
	lobby: Lobby | null
	send: SendFn

	constructor(address: Address, send: SendFn) {
		this.id = uuidv4()
		this.lobby = null
		this.username = 'Guest'
		this.address = address
		this.send = send
	}

	setUsername = (username: string) => {
		this.username = username
		this.lobby?.broadcast()
	}

	setLobby = (lobby: Lobby | null) => {
		this.lobby = lobby
	}
}

export default Client
