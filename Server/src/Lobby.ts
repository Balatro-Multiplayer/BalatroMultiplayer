import type Client from "./Client.js";
import GameModes from "./GameMode.js";
import type {
	ActionLobbyInfo,
	ActionServerToClient,
	GameMode,
} from "./actions.js";
import { serializeAction } from "./main.js";

const Lobbies = new Map();

const generateUniqueLobbyCode = (): string => {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	let result = "";
	for (let i = 0; i < 5; i++) {
		result += chars.charAt(Math.floor(Math.random() * chars.length));
	}
	return Lobbies.get(result) ? generateUniqueLobbyCode() : result;
};

class Lobby {
	code: string;
	host: Client | null;
	guest: Client | null;
	gameMode: GameMode;
	// biome-ignore lint/suspicious/noExplicitAny: 
	options: { [key: string]: any };
	roundProcessed: boolean;

	// Attrition is the default game mode
	constructor(host: Client, gameMode: GameMode = "attrition") {
		do {
			this.code = generateUniqueLobbyCode();
		} while (Lobbies.get(this.code));
		Lobbies.set(this.code, this);

		this.host = host;
		this.guest = null;
		this.gameMode = gameMode;
		this.options = {};
		this.roundProcessed = false;

		host.setLobby(this);
		host.sendAction({
			action: "joinedLobby",
			code: this.code,
			type: this.gameMode,
		});
	}

	static get = (code: string) => {
		return Lobbies.get(code);
	};

	leave = (client: Client) => {
		if (this.host?.id === client.id) {
			this.host = this.guest;
			this.guest = null;
		} else if (this.guest?.id === client.id) {
			this.guest = null;
		}

		const lobby = client.lobby;
		client.setLobby(null);
		if (this.host === null) {
			Lobbies.delete(this.code);
		} else {
			// TODO: Refactor for more than 2 players
			// Stop game if someone leaves
			lobby?.broadcastAction({ action: "stopGame" });
			this.broadcastLobbyInfo();
		}
	};

	join = (client: Client) => {
		if (this.guest) {
			client.sendAction({
				action: "error",
				message: "Lobby is full or does not exist.",
			});
			return;
		}
		this.guest = client;
		client.setLobby(this);
		client.sendAction({
			action: "joinedLobby",
			code: this.code,
			type: this.gameMode,
		});
		client.sendAction({ action: "lobbyOptions", ...this.options });
		this.broadcastLobbyInfo();
	};

	broadcastAction = (action: ActionServerToClient) => {
		this.host?.sendAction(action);
		this.guest?.sendAction(action);
	};

	broadcastLobbyInfo = () => {
		if (!this.host) {
			return;
		}

		const action: ActionLobbyInfo = {
			action: "lobbyInfo",
			host: this.host.username,
			isHost: false,
		};

		if (this.guest?.username) {
			action.guest = this.guest.username;
			this.guest.sendAction(action);
		}

		// Should only sent true to the host
		action.isHost = true;
		this.host.sendAction(action);
	};

	setPlayersLives = (lives: number) => {
		// TODO: Refactor for more than 2 players
		if (this.host) this.host.lives = lives;
		if (this.guest) this.guest.lives = lives;

		this.broadcastAction({ action: "playerInfo", lives });
	};

	sendGameInfo = (client: Client) => {
		if (this.host !== client && this.guest !== client) {
			return client.sendAction({
				action: "error",
				message: "Client not in Lobby",
			});
		}

		client.sendAction({
			action: "gameInfo",
			...GameModes[this.gameMode].getBlindFromAnte(client.ante, this.options),
		});
	};

	setOptions = (options: { [key: string]: string }) => {
		for (const key of Object.keys(options)) {
			if (options[key] === "true" || options[key] === "false") {
				this.options[key] = options[key] === "true";
			} else {
				this.options[key] = options[key];
			}
		}
		this.guest?.sendAction({ action: "lobbyOptions", ...options });
	};
}

export default Lobby;
