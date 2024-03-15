import { v4 as uuidv4 } from 'uuid'
import type Lobby from './Lobby.js'

type SendFn = (data: string) => void

class Client {
	id: string
	username: string
	lobby: Lobby | null
	send: SendFn

	constructor(send: SendFn) {
		this.id = uuidv4()
		this.lobby = null
		this.username = 'Guest'
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
