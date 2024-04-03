import net from 'node:net'
import Client from './Client.js'
import { actionHandlers } from './actionHandlers.js'
import type {
	Action,
	ActionClientToServer,
	ActionCreateLobby,
	ActionHandlerArgs,
	ActionJoinLobby,
	ActionPlayHand,
	ActionServerToClient,
	ActionUsername,
	ActionUtility,
} from './actions.js'

const PORT = 8080

/** The amount of milliseconds we wait before sending the initial keepalive packet  */
const KEEP_ALIVE_INITIAL_TIMEOUT = 5000
/** The amount of milliseconds we wait after sending a new retry packet  */
const KEEP_ALIVE_RETRY_TIMEOUT = 2500
/** The amount of retries we do before we declare the socket dead */
const KEEP_ALIVE_RETRY_COUNT = 3

// biome-ignore lint/suspicious/noExplicitAny: Object is parsed from string
const stringToJson = (str: string): any => {
	const obj: Record<string, string | number> = {}
	for (const part of str.split(',')) {
		const [key, value] = part.split(':')
		const numericValue = Number.parseFloat(value)
		obj[key] = Number.isNaN(numericValue) ? value : numericValue
	}
	return obj
}

/** Serializes an action for transmission to the client */
export const serializeAction = (action: Action): string => {
	const entries = Object.entries(action)
	const parts = entries
		.filter(([_key, value]) => value !== undefined && value !== null)
		.map(([key, value]) => `${key}:${value}`)
	return parts.join(',')
}

const sendActionToSocket =
	(socket: net.Socket) => (action: ActionServerToClient) => {
		if (!socket) {
			return
		}

		const data = serializeAction(action)

		const { action: actionName, ...actionArgs } = action
		console.log(
			`Sent action ${actionName} to client: ${JSON.stringify(actionArgs)}`,
		)

		socket.write(`${data}\n`)
	}

const server = net.createServer((socket) => {
	socket.allowHalfOpen = false
	// Do not wait for packets to buffer, helps
	// improve latency between responses
	socket.setNoDelay()

	const client = new Client(socket.address(), sendActionToSocket(socket))
	client.sendAction({ action: 'connected' })

	let isRetry = false
	let retryCount = 0

	const retryTimer: ReturnType<typeof setTimeout> = setTimeout(() => {
		// Ignore if not retry
		if (!isRetry) {
			return
		}

		client.sendAction({ action: 'keepAlive' })
		retryCount++

		if (retryCount >= KEEP_ALIVE_RETRY_COUNT) {
			socket.end()
		} else {
			retryTimer.refresh()
		}
	}, KEEP_ALIVE_RETRY_TIMEOUT)

	// Once the client connects, we start a timer
	const keepAlive: ReturnType<typeof setTimeout> = setTimeout(() => {
		client.sendAction({ action: 'keepAlive' })
		isRetry = true
		retryTimer.refresh()
	}, KEEP_ALIVE_INITIAL_TIMEOUT)

	socket.on('data', (data) => {
		// Data received, reset keepAlive
		isRetry = false
		retryCount = 0
		keepAlive.refresh()

		const messages = data.toString().split('\n')

		for (const msg of messages) {
			if (!msg) return
			try {
				const message: ActionClientToServer | ActionUtility = stringToJson(msg)
				const { action, ...actionArgs } = message
				console.log(
					`Received action ${action} from ${client.id}: ${JSON.stringify(
						actionArgs,
					)}`,
				)

				switch (action) {
					case 'username':
						actionHandlers.username(
							actionArgs as ActionHandlerArgs<ActionUsername>,
							client,
						)
						break
					case 'createLobby':
						actionHandlers.createLobby(
							actionArgs as ActionHandlerArgs<ActionCreateLobby>,
							client,
						)
						break
					case 'joinLobby':
						actionHandlers.joinLobby(
							actionArgs as ActionHandlerArgs<ActionJoinLobby>,
							client,
						)
						break
					case 'lobbyInfo':
						actionHandlers.lobbyInfo(client)
						break
					case 'leaveLobby':
						actionHandlers.leaveLobby(client)
						break
					case 'startGame':
						actionHandlers.startGame(client)
						break
					case 'readyBlind':
						actionHandlers.readyBlind(client)
						break
					case 'unreadyBlind':
						actionHandlers.unreadyBlind(client)
						break
					case 'keepAlive':
						actionHandlers.keepAlive(client)
						break
					case 'playHand':
						actionHandlers.playHand(
							actionArgs as ActionHandlerArgs<ActionPlayHand>,
							client,
						)
						break
					case 'stopGame':
						actionHandlers.stopGame(client)
						break
					case 'lobbyOptions':
						actionHandlers.lobbyOptions(actionArgs, client)
						break
				}
			} catch (error) {
				const failedToParseError = 'Failed to parse message'
				console.error(failedToParseError, error)
				client.sendAction({
					action: 'error',
					message: failedToParseError,
				})
			}
		}
	})

	socket.on('end', () => {
		console.log(`Client disconnected ${client.id}`)
		actionHandlers.leaveLobby?.(client)
	})

	socket.on(
		'error',
		(
			err: Error & {
				errno: number
				code: string
				syscall: string
			},
		) => {
			if (err.code === 'ECONNRESET') {
				console.warn('TCP connection reset by peer (client).')
			} else {
				console.error('An unexpected error occurred:', err)
			}
			actionHandlers.leaveLobby?.(client)
		},
	)
})

server.listen(PORT, '0.0.0.0', () => {
	console.log(`Server listening on port ${PORT}`)
})
