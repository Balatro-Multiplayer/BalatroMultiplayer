# Server API Documentation

This server is written using good faith, there is no verification of data sent from the client, we have to assume there has been no tampering. That being said, it would be possible to maliciously manipulate other's games if you can impersonate another socket connection, though I am not sure how possible/easy this is. I would love to implement TLS but at this moment I don't think it is possible for me to add lua packages (such as an SSL package) without including the full source code. A security-based C module for the mod might be nessesary in the future.

For ease of parsing in lua, communications between the client and server are in CSV, where the "action" column is manditory with every socket message. The rest of the columns are action-specific. Columns do not need to be in any particular order.

## Actions

example_action_name: param1, param2?
- description of action
- param1: description of param1
- param2?: description of optional param2

### Server to Client

connected
- Client successfully connected

---

error: message
- An error, this should only be used when needed since it is very intrusive

---

joinedLobby: code
- Client should act as if in a lobby with given code
- code: 5 letter code acting as a lobby ID

---

lobbyInfo: host, guest?
- Gives clients info on the lobby state
- host: Lobby host's username
- guest?: Lobby guest's username

*This will obviously need reworking for 8 players but it is the simplest way of doing it for now

---

stopGame
- Tells the client to return to the lobby. This should be sent if any client returns to lobby.

---

startGame: deck, stake?, seed?
- Tells the client to start the run
- deck: Deck or challenge id to start the game with, must be a [deck type](#deck-types) or [challenge type](#deck-types)
- stake?: Stake to start the deck with, does not affect challenges, must be a number between 1 and 8
- seed?: Seed that the clients will start the run with, must be a [seed type](#seed-types)

---

startBlind
- Tells the client to start the next blind. This should be sent when both clients are ready.

---

winGame
- Tells the client to force win the run.

---

loseGame
- Tells the client to force lose the run.

---

gameInfo: small?, big?, boss?
- Info to send to the client before each blind set is displayed, overwrites the blinds
- small?: Blind type to set the small blind in the set to, defaults to the normal small blind, must be a [blind type](#blind-types)
- big?: Blind type to set the big blind in the set to, defaults to the normal big blind, must be a [blind type](#blind-types)
- boss?: Blind type to set the boss in the set to, defaults to a random boss, must be a [blind type](#blind-types)

---

playerInfo: lives
- Info to send to the client at the start of the game and whenever it is requested
- lives: Amount of lives the client currently has, must be a number

---

enemyInfo: score, handsLeft
- Updates the client on their enemy's score and hands left. This should be sent when the enemy plays a hand

---

endPvP: lost
- Needs to be sent at the end of a PvP blind, clients will wait for this
- lost: Whether the client lost the PvP, client will take this as a life lost (server should reflect this), must be a boolean value (client will interpret this as a string)

---

### Client to Server

username: username
- Set the client's username
- username: The value

---

createLobby: type
- Request to make a lobby and be given a code. Expecting a 'joinedLobby' response.
- type: Requested gamemode type, must be a [server type](#server-types)

---

joinLobby: code
- Request to join an existing lobby, by given code. Expecting a 'joinedLobby' or 'error' response.
- code: 5 letter code acting as a lobby ID

---

leaveLobby
- Leave the joined lobby, a code is not provided because this should be *almost* equivalent to when a client socket is destroyed, so it needs to be functional without providing a code

---

lobbyInfo
- Request for an accurate 'lobbyInfo' response, for the lobby the client is connected to

---

stopGame
- Client is returning to lobby. Server should send other clients back to lobby as well.

---

startGame
- Request to start the run. Expecting a 'startGame' response.

---

readyBlind
- Declare ready to start next blind. Expecting 'startBlind' response.

---

playHand: score, handsLeft
- Client has played a hand.
- score: The total score of all hands played in the blind so far, must be a number
- handsLeft: The total number of hands left that the client can play this blind, must be a number

---

gameInfo
- Request a gameInfo update.

---

playerInfo
- Request a playerInfo update.

---

enemyInfo
- Request an enemyInfo update.

---

### Utility

keepAlive
- Request a keepAliveAck response.

---

keepAliveAck
- Send a response to the keepAlive request.

## Server Types

- attrition
  - Both players start with 4 lives
  - Every set's boss should be PvP
- draft
  - Both players start with 2 lives
  - First 4 antes are normal, rest of antes are only PvP blinds

## Game Types

### Blind Types

One of the following, left side is the values, right side is the corosponding in-game name:
- bl_small          = Small Blind
- bl_big            = Big Blind
- bl_ox             = The Ox
- bl_hook           = The Hook
- bl_mouth          = The Mouth
- bl_fish           = The Fish
- bl_club           = The Club
- bl_manacle        = The Manacle
- bl_tooth          = The Tooth
- bl_wall           = The Wall
- bl_house          = The House
- bl_mark           = The Mark
- bl_final_bell     = Cerulean Bell
- bl_wheel          = The Wheel
- bl_arm            = The Arm
- bl_psychic        = The Psychic
- bl_goad           = The Goad
- bl_water          = The Water
- bl_eye            = The Eye
- bl_plant          = The Plant
- bl_needle         = The Needle
- bl_head           = The Head
- bl_final_leaf     = Verdant Leaf
- bl_final_vessel   = Violet Vessel
- bl_window         = The Window
- bl_serpent        = The Serpent
- bl_pillar         = The Pillar
- bl_flint          = The Flint
- bl_final_acorn    = Amber Acorn
- bl_final_heart    = Crimson Heart
- **b1_pvp          = Your Nemesis** <-- This is the blind that needs to be set for players to play against eachother's scores

### Deck Types

One of the following, left side is the values, right side is the corosponding in-game name:
- b_red         = Red Deck
- b_blue        = Blue Deck
- b_yellow      = Yellow Deck
- b_green       = Green Deck
- b_black       = Black Deck
- b_magic       = Magic Deck
- b_nebula      = Nebula Deck
- b_ghost       = Ghost Deck
- b_abandoned   = Abandoned Deck
- b_checkered   = Checkered Deck
- b_zodiac      = Zodiac Deck
- b_painted     = Painted Deck
- b_anaglyph    = Anaglyph Deck
- b_plasma      = Plasma Deck
- b_erratic     = Erratic Deck

### Challenge Types

One of the following, left side is the values, right side is the corosponding in-game name:
- c_omelette_1        = The Omelette
- c_city_1            = 15 Minute City
- c_rich_1            = Rich get Richer
- c_knife_1           = On a Knife's Edge
- c_xray_1            = X-ray Vision
- c_mad_world_1       = Mad World
- c_luxury_1          = Luxury Tax
- c_non_perishable_1  = Non-Perishable
- c_medusa_1          = Medusa
- c_double_nothing_1  = Double or Nothing
- c_typecast_1        = Typecast
- c_inflation_1       = Inflation
- c_bram_poker_1      = Bram Poker
- c_fragile_1         = Fragile
- c_monolith_1        = Monolith
- c_blast_off_1       = Blast Off
- c_five_card_1       = Five-Card Draw
- c_golden_needle_1   = Golden Needle
- c_cruelty_1         = Cruelty
- c_jokerless_1       = Jokerless
- **c_multiplayer_1   = Multiplayer Default** <-- This is the default deck until deck selection implementation (will be removed)

### Seed Type

- String
- Exactly 8 Characters Long
- Only Uppercase Letters and Numbers