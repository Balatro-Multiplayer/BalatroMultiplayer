import net from 'node:net'
import Client from './Client.js'
import { actionHandlers } from './actionHandlers.js'
import type { Action, ActionClientToServer, ActionUtility } from './actions.js'

const PORT = 8080

/** The amount of milliseconds we wait before sending the initial keepalive packet  */
const KEEP_ALIVE_INITIAL_TIMEOUT = 5000
/** The amount of milliseconds we wait after sending a new retry packet  */
const KEEP_ALIVE_RETRY_TIMEOUT = 2500
/** The amount of retries we do before we declare the socket dead */
const KEEP_ALIVE_RETRY_COUNT = 3

// biome-ignore lint/suspicious/noExplicitAny: Object is parsed from string
const stringToJson = (str: string): any => {
	// biome-ignore lint/suspicious/noExplicitAny: Object is parsed from string
	const obj: any = {}
	for (const part of str.split(',')) {
		const [key, value] = part.split(':')
		obj[key] = value
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

const sendToSocket = (socket: net.Socket) => (data: string) => {
	if (!socket) {
		return
	}
	socket.write(`${data}\n`)
}

const server = net.createServer((socket) => {
	socket.allowHalfOpen = false
	// Do not wait for packets to buffer, helps
	// improve latency between responses
	socket.setNoDelay()

	const client = new Client(socket.address(), sendToSocket(socket))
	client.send(serializeAction({ action: 'connected' }))

	let isRetry = false
	let retryCount = 0

	const retryTimer: ReturnType<typeof setTimeout> = setTimeout(() => {
		// Ignore if not retry
		if (!isRetry) {
			return
		}

		client.send(serializeAction({ action: 'keepAlive' }))
		retryCount++

		if (retryCount >= KEEP_ALIVE_RETRY_COUNT) {
			socket.end()
		} else {
			retryTimer.refresh()
		}
	}, KEEP_ALIVE_RETRY_TIMEOUT)

	// Once the client connects, we start a timer
	const keepAlive: ReturnType<typeof setTimeout> = setTimeout(() => {
		client.send(serializeAction({ action: 'keepAlive' }))
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
				console.log(`Received action ${action} from ${client.id}`)

				// This only works for now, once we add more arguments
				// we'll need to refactor this
				// Maybe add a context type that includes everything
				// connection related?
				Object.keys(actionArgs).length > 0
					? actionHandlers[action]?.(actionArgs, client)
					: actionHandlers[action]?.(client)
			} catch (error) {
				const failedToParseError = 'Failed to parse message'
				console.error(failedToParseError, error)
				client.send(
					serializeAction({
						action: 'error',
						message: failedToParseError,
					}),
				)
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
