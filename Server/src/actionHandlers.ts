import type Client from "./Client.js";
import GameModes from "./GameMode.js";
import Lobby from "./Lobby.js";
import type {
	ActionCreateLobby,
	ActionHandlerArgs,
	ActionHandlers,
	ActionJoinLobby,
	ActionPlayHand,
	ActionSetAnte,
	ActionSetLocation,
	ActionUsername,
	ActionVersion,
} from "./actions.js";
import { generateSeed } from "./utils.js";

const usernameAction = (
	{ username, modHash }: ActionHandlerArgs<ActionUsername>,
	client: Client,
) => {
	client.setUsername(username);
	client.setModHash(modHash);
};

const createLobbyAction = (
	{ gameMode }: ActionHandlerArgs<ActionCreateLobby>,
	client: Client,
) => {
	/** Also sets the client lobby to this newly created one */
	new Lobby(client, gameMode);
};

const joinLobbyAction = (
	{ code }: ActionHandlerArgs<ActionJoinLobby>,
	client: Client,
) => {
	const newLobby = Lobby.get(code);
	if (!newLobby) {
		client.sendAction({
			action: "error",
			message: "Lobby does not exist.",
		});
		return;
	}
	newLobby.join(client);
};

const leaveLobbyAction = (client: Client) => {
	client.lobby?.leave(client);
};

const lobbyInfoAction = (client: Client) => {
	client.lobby?.broadcastLobbyInfo();
};

const keepAliveAction = (client: Client) => {
	// Send an ack back to the received keepAlive
	client.sendAction({ action: "keepAliveAck" });
};

const startGameAction = (client: Client) => {
	const lobby = client.lobby;
	// Only allow the host to start the game
	if (!lobby || lobby.host?.id !== client.id) {
		return;
	}

	const lives = lobby.options.starting_lives
		? Number.parseInt(lobby.options.starting_lives)
		: GameModes[lobby.gameMode].startingLives;

	lobby.broadcastAction({
		action: "startGame",
		deck: "c_multiplayer_1",
		seed: lobby.options.different_seeds ? undefined : generateSeed(),
	});
	// Reset players' lives
	lobby.setPlayersLives(lives);
};

const readyBlindAction = (client: Client) => {
	client.isReady = true;

	// TODO: Refactor for more than two players
	if (client.lobby?.host?.isReady && client.lobby.guest?.isReady) {
		// Reset ready status for next blind
		client.lobby.host.isReady = false;
		client.lobby.guest.isReady = false;

		// Reset scores for next blind
		client.lobby.host.score = 0n;
		client.lobby.guest.score = 0n;

		// Reset hands left for next blind
		client.lobby.host.handsLeft = 4;
		client.lobby.guest.handsLeft = 4;

		client.lobby.broadcastAction({ action: "startBlind" });
	}
};

const unreadyBlindAction = (client: Client) => {
	client.isReady = false;
};

const playHandAction = (
	{ handsLeft, score }: ActionHandlerArgs<ActionPlayHand>,
	client: Client,
) => {
	if (!client.lobby) {
		return;
	}

	client.score = BigInt(String(score));
	client.handsLeft =
		typeof handsLeft === "number" ? handsLeft : Number(handsLeft);

	const lobby = client.lobby;
	// Update the other party about the
	// enemy's score and hands left
	// TODO: Refactor for more than two players
	if (lobby.host?.id === client.id) {
		lobby.guest?.sendAction({
			action: "enemyInfo",
			handsLeft,
			score,
		});
	} else if (lobby.guest?.id === client.id) {
		lobby.host?.sendAction({
			action: "enemyInfo",
			handsLeft,
			score,
		});
	}

	if (!lobby.host || !lobby.guest) {
		stopGameAction(client);
		return;
	}
	// This info is only sent on a boss blind, so it shouldn't
	// affect other blinds
	if (
		(lobby.guest.handsLeft === 0 && lobby.host.score > lobby.guest.score) ||
		(lobby.host.handsLeft === 0 && lobby.guest.score > lobby.host.score) ||
		(lobby.host.handsLeft === 0 && lobby.guest.handsLeft === 0)
	) {
		const roundWinner =
			lobby.host.score > lobby.guest.score ? lobby.host : lobby.guest;
		const roundLoser =
			roundWinner.id === lobby.host.id ? lobby.guest : lobby.host;

		if (lobby.host.score !== lobby.guest.score) {
			roundLoser.loseLife();

			// If no lives are left, we end the game
			if (lobby.host.lives === 0 || lobby.guest.lives === 0) {
				const gameWinner =
					lobby.host.lives > lobby.guest.lives ? lobby.host : lobby.guest;
				const gameLoser =
					gameWinner.id === lobby.host.id ? lobby.guest : lobby.host;

				gameWinner?.sendAction({ action: "winGame" });
				gameLoser?.sendAction({ action: "loseGame" });
				return;
			}
		}

		roundWinner.sendAction({ action: "endPvP", lost: false });
		roundLoser.sendAction({ action: "endPvP", lost: true });
	}
};

const stopGameAction = (client: Client) => {
	client.lobby?.broadcastAction({ action: "stopGame" });
};

// Deprecated
const gameInfoAction = (client: Client) => {
	client.lobby?.sendGameInfo(client);
};

const lobbyOptionsAction = (
	options: Record<string, string>,
	client: Client,
) => {
	client.lobby?.setOptions(options);
};

const failRoundAction = (client: Client) => {
	const lobby = client.lobby;

	if (!lobby) return;

	if (lobby.options.death_on_round_loss) {
		client.loseLife()
	}

	if (client.lives === 0) {
		let gameLoser = null;
		let gameWinner = null;
		if (client.id === lobby.host?.id) {
			gameLoser = lobby.host;
			gameWinner = lobby.guest;
		} else {
			gameLoser = lobby.guest;
			gameWinner = lobby.host;
		}

		gameWinner?.sendAction({ action: "winGame" });
		gameLoser?.sendAction({ action: "loseGame" });
	}
};

const setAnteAction = (
	{ ante }: ActionHandlerArgs<ActionSetAnte>,
	client: Client,
) => {
	client.ante = ante;
};

// TODO: Fix this
const serverVersion = "0.1.6-MULTIPLAYER";
/** Verifies the client version and allows connection if it matches the server's */
const versionAction = (
	{ version }: ActionHandlerArgs<ActionVersion>,
	client: Client,
) => {
	const versionMatch = version.match(/^(\d+\.\d+\.\d+)-MULTIPLAYER$/);
	if (versionMatch) {
			const clientVersion = versionMatch[1];
			const serverVersionNumber = serverVersion.split('-')[0];
			
			const [clientMajor, clientMinor, clientPatch] = clientVersion.split('.').map(Number);
			const [serverMajor, serverMinor, serverPatch] = serverVersionNumber.split('.').map(Number);
			
			if (clientMajor < serverMajor || 
					(clientMajor === serverMajor && clientMinor < serverMinor) ||
					(clientMajor === serverMajor && clientMinor === serverMinor && clientPatch < serverPatch)) {
					client.sendAction({ 
							action: "error", 
							message: `[WARN] Server expecting version ${serverVersion}` 
					});
			}
	}
};

const setLocation = ({ location }: ActionHandlerArgs<ActionSetLocation>, client: Client) => {
	client.setLocation(location);
}

const newRound = (client: Client) => {
	client.resetBlocker()
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
	stopGame: stopGameAction,
	gameInfo: gameInfoAction,
	lobbyOptions: lobbyOptionsAction,
	failRound: failRoundAction,
	setAnte: setAnteAction,
	version: versionAction,
	setLocation: setLocation,
	newRound: newRound,
} satisfies Partial<ActionHandlers>;
