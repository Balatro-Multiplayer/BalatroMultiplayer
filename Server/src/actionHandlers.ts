import type Client from './Client'
import Lobby from './Lobby'
import type {
	ActionCreateLobby,
	ActionFnArgs,
	ActionHandlers,
	ActionJoinLobby,
	ActionUsername,
} from './actions'
import { serializeAction } from './main'

const usernameAction = (
	{ username }: ActionFnArgs<ActionUsername>,
	client: Client,
) => {
	client.setUsername(username)
}

const createLobbyAction = (
	{ gameMode }: ActionFnArgs<ActionCreateLobby>,
	client: Client,
) => {
	new Lobby(client)
}

const joinLobbyAction = (
	{ code }: ActionFnArgs<ActionJoinLobby>,
	client: Client,
) => {
	const newLobby = Lobby.get(code)
	if (!newLobby) {
		client.send(
			serializeAction({
				action: 'error',
				message: 'Lobby does not exist.',
			}),
		)
		return
	}
	newLobby.join(client)
}

const leaveLobbyAction = (client: Client) => {
	client.lobby?.leave(client)
}

const lobbyInfoAction = (client: Client) => {
	client.lobby?.broadcast()
}

// Declared partial for now untill all action handlers are defined
export const actionHandlers: Partial<ActionHandlers> = {
	username: usernameAction,
	createLobby: createLobbyAction,
	joinLobby: joinLobbyAction,
	lobbyInfo: lobbyInfoAction,
	leaveLobby: leaveLobbyAction,
}
