import net from 'node:net'
import Client from './Client.js'
import { actionHandlers } from './actionHandlers.js'
import type { ActionClientToServer, ActionServerToClient } from './actions.js'

const PORT = 8080

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
export const serializeAction = (action: ActionServerToClient): string => {
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
	const client = new Client(sendToSocket(socket))
	client.send(serializeAction({ action: 'connected' }))

	socket.on('data', (data) => {
		const messages = data.toString().split('\n')

		for (const msg of messages) {
			if (!msg) return
			try {
				const message: ActionClientToServer = stringToJson(msg)
				const { action, ...actionArgs } = message

				// This only works for now, once we add more arguments
				// we'll need to refactor this
				// Maybe add a context type that includes everything
				// connection related?
				actionArgs
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
