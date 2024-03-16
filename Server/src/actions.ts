// Server to Client
export type ActionConnected = { action: 'connected' }
export type ActionError = { action: 'error'; message: string }
export type ActionJoinedLobby = { action: 'joinedLobby'; code: string }
export type ActionLobbyInfo = {
	action: 'lobbyInfo'
	host: string
	guest?: string
	isHost: boolean
}
export type ActionStopGame = { action: 'stopGame' }
export type ActionStartGame = {
	action: 'startGame'
	deck: string
	stake?: number
	seed?: string
}
export type ActionStartBlind = { action: 'startBlind' }
export type ActionWinGame = { action: 'winGame' }
export type ActionLoseGame = { action: 'loseGame' }
export type ActionGameInfo = {
	action: 'gameInfo'
	small?: string
	big?: string
	boss?: string
}
export type ActionPlayerInfo = { action: 'playerInfo'; lives: number }
export type ActionEnemyInfo = {
	action: 'enemyInfo'
	score: number
	handsLeft: number
}
export type ActionEndPvP = { action: 'endPvP'; lost: boolean }

export type ActionServerToClient =
	| ActionConnected
	| ActionError
	| ActionJoinedLobby
	| ActionLobbyInfo
	| ActionStopGame
	| ActionStartGame
	| ActionStartBlind
	| ActionWinGame
	| ActionLoseGame
	| ActionGameInfo
	| ActionPlayerInfo
	| ActionEnemyInfo
	| ActionEndPvP

// Client to Server
export type ActionUsername = { action: 'username'; username: string }
export type ActionCreateLobby = { action: 'createLobby'; gameMode: string }
export type ActionJoinLobby = { action: 'joinLobby'; code: string }
export type ActionLeaveLobby = { action: 'leaveLobby' }
export type ActionLobbyInfoRequest = { action: 'lobbyInfo' }
export type ActionStopGameRequest = { action: 'stopGame' }
export type ActionStartGameRequest = { action: 'startGame' }
export type ActionReadyBlind = { action: 'readyBlind' }
export type ActionPlayHand = {
	action: 'playHand'
	score: number
	handsLeft: number
}
export type ActionGameInfoRequest = { action: 'gameInfo' }
export type ActionPlayerInfoRequest = { action: 'playerInfo' }
export type ActionEnemyInfoRequest = { action: 'enemyInfo' }

export type ActionClientToServer =
	| ActionUsername
	| ActionCreateLobby
	| ActionJoinLobby
	| ActionLeaveLobby
	| ActionLobbyInfoRequest
	| ActionStopGameRequest
	| ActionStartGameRequest
	| ActionReadyBlind
	| ActionPlayHand
	| ActionGameInfoRequest
	| ActionPlayerInfoRequest
	| ActionEnemyInfoRequest

// Utility actions
export type ActionKeepAlive = { action: 'keepAlive' }
export type ActionKeepAliveAck = { action: 'keepAliveAck' }

export type ActionUtility = ActionKeepAlive | ActionKeepAliveAck

export type Action = ActionServerToClient | ActionClientToServer | ActionUtility

type HandledActions = ActionClientToServer | ActionUtility
export type ActionHandlers = {
	[K in HandledActions['action']]: keyof ActionHandlerArgs<
		Extract<HandledActions, { action: K }>
	> extends never
		? (
				// biome-ignore lint/suspicious/noExplicitAny: Function can receive any arguments
				...args: any[]
		  ) => void
		: (
				action: ActionHandlerArgs<Extract<HandledActions, { action: K }>>,
				// biome-ignore lint/suspicious/noExplicitAny: Function can receive any arguments
				...args: any[]
		  ) => void
}

export type ActionHandlerArgs<T extends HandledActions> = Omit<T, 'action'>
