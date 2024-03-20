import type Client from './Client.js'
import Lobby from './Lobby.js'
import type {
	ActionCreateLobby,
	ActionHandlerArgs,
	ActionHandlers,
	ActionJoinLobby,
	ActionPlayHand,
	ActionUsername,
} from './actions.js'
import { generateSeed } from './utils.js'

const usernameAction = (
	{ username }: ActionHandlerArgs<ActionUsername>,
	client: Client,
) => {
	client.setUsername(username)
}

const createLobbyAction = (
	{ gameMode }: ActionHandlerArgs<ActionCreateLobby>,
	client: Client,
) => {
	/** Also sets the client lobby to this newly created one */
	new Lobby(client)
}

const joinLobbyAction = (
	{ code }: ActionHandlerArgs<ActionJoinLobby>,
	client: Client,
) => {
	const newLobby = Lobby.get(code)
	if (!newLobby) {
		client.sendAction({
			action: 'error',
			message: 'Lobby does not exist.',
		})
		return
	}
	newLobby.join(client)
}

const leaveLobbyAction = (client: Client) => {
	client.lobby?.leave(client)
}

const lobbyInfoAction = (client: Client) => {
	client.lobby?.broadcastLobbyInfo()
}

const keepAliveAction = (client: Client) => {
	// Send an ack back to the received keepAlive
	client.sendAction({ action: 'keepAliveAck' })
}

const startGameAction = (client: Client) => {
	// Only allow the host to start the game
	if (!client.lobby || client.lobby.host?.id !== client.id) {
		return
	}

	// Hardcoded for testing
	client.lobby.broadcastAction({
		action: 'startGame',
		deck: 'c_multiplayer_1',
		seed: 'JA9C3',
	})
}

const readyBlindAction = (client: Client) => {
	client.isReady = true

	// TODO: Refactor for more than two players
	if (client.lobby?.host?.isReady && client.lobby.guest?.isReady) {
		// Reset ready status for next blind
		client.lobby.host.isReady = false
		client.lobby.guest.isReady = false

		// Reset scores for next blind
		client.lobby.host.score = 0
		client.lobby.guest.score = 0

		// Reset hands left for next blind
		client.lobby.host.handsLeft = 4
		client.lobby.guest.handsLeft = 4

		client.lobby.broadcastAction({ action: 'startBlind' })
	}
}

const unreadyBlindAction = (client: Client) => {
	client.isReady = false
}

const playHandAction = (
	{ handsLeft, score }: ActionHandlerArgs<ActionPlayHand>,
	client: Client,
) => {
	if (!client.lobby) {
		return
	}

	// Should this be additive or just
	// the latest score?
	client.score = score
	client.handsLeft =
		typeof handsLeft === 'number' ? handsLeft : Number(handsLeft)

	const lobby = client.lobby
	// Update the other party about the
	// enemy's score and hands left
	// TODO: Refactor for more than two players
	if (lobby.host?.id === client.id) {
		lobby.guest?.sendAction({
			action: 'enemyInfo',
			handsLeft,
			score,
		})
	} else if (lobby.guest?.id === client.id) {
		lobby.host?.sendAction({
			action: 'enemyInfo',
			handsLeft,
			score,
		})
	}

	console.log(
		`Host hands: ${lobby.host?.handsLeft}, Guest hands: ${lobby.guest?.handsLeft}`,
	)
	// This info is only sent on a boss blind, so it shouldn't
	// affect other blinds
	if (lobby.host?.handsLeft === 0 && lobby.guest?.handsLeft === 0) {
		const winner =
			lobby.host.score > lobby.guest.score ? lobby.host : lobby.guest
		const loser = winner.id === lobby.host.id ? lobby.guest : lobby.host

		console.log('Winner:', winner.username)
		console.log('Loser:', loser.username)

		loser.lives -= 1
		loser.sendAction({ action: 'playerInfo', lives: loser.lives })

		winner.sendAction({ action: 'endPvP', lost: false })
		loser.sendAction({ action: 'endPvP', lost: true })
	}
}

// Declared partial for now untill all action handlers are defined
export const actionHandlers = {
	username: usernameAction,
	createLobby: createLobbyAction,
	joinLobby: joinLobbyAction,
	lobbyInfo: lobbyInfoAction,
	leaveLobby: leaveLobbyAction,
	keepAlive: keepAliveAction,
	startGame: startGameAction,
	readyBlind: readyBlindAction,
	unreadyBlind: unreadyBlindAction,
	playHand: playHandAction,
} satisfies Partial<ActionHandlers>
