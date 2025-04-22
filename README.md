# Balatro Multiplayer Mod

![ModIcon](https://github.com/Balatro-Multiplayer/BalatroMultiplayer/blob/2cd9015963c1118e0b849f11e7c335f97b74f36c/assets/2x/modicon.png)

A multiplayer mod for Balatro, allowing players to compete with each other.

## 📥 Installation

Detailed installation instructions are available on our website:
[https://balatromp.com/docs/getting-started/installation](https://balatromp.com/docs/getting-started/installation)

Quick installation steps:

1. Download the latest release from the [Releases page](https://github.com/Balatro-Multiplayer/balatro-multiplayer/releases)
2. Extract the files to your Balatro game directory
3. Run the game with the mod enabled
4. Follow the in-game instructions to connect with friends

## 🎲 Usage

1. Launch Balatro with the multiplayer mod enabled
2. From the main menu, select "Play", then "Create Lobby"
3. Select a ruleset/gamemode
4. Press "View Code" and send the code to the person you want to play with
5. The other player will select "Play", then "Join Lobby" and enter the code
6. Press "Start" to start the game!
   
## 🤝 Contributing

We welcome contributions to the Balatro Multiplayer Mod! Here's how you can help:

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow the existing code style and conventions
- Write clear, descriptive commit messages
- Clearly explain the feature you have implemented in the pull request
- Ensure to properly test the feature and provide example seeds where the feature can clearly be seen working (if relevant)

Contributions that make content changes like modifying how the base game works, adding cards or blinds, or adding gamemodes will likely not be accepted. We are currently trying to maintain the competitive integrity of the mod and these types of changes need to be decided on by our team before being added.

### Looking to contribute but don't have a feature in mind?

Here are some features we're planning to implement in future releases that aren't being worked on yet:

- **Timer Config**: Add a Lobby Option to change the timer values, as well as letting players pause the timer after starting
- **Nemesis Deck View**: Implement a button on the game over and game won screens to view the Nemesis' deck
- **Rulesets Selection Rework**: Change the rulesets screen to be more like the challenges screen, in order to be clear about what the rulesets affect
- **In Pool Rework**: Update the pooling function and related multiplayer code to independently handle ruleset and gamemode bans (to prevent our card and ruleset logic from interfering with each other)
- **Return of Gamemodes**: Re-implement gamemodes and have a secondary selection screen after the rulesets to select a gamemode. Here is a list of gamemodes:
  - Attrition: This is how the Multiplayer mod works right now, ever boss blind is a Nemesis blind
  - Showdown: After the first 2 antes every blind is a Nemesis blind, the amount of antes before this happens should be configurable in Lobby Options
  - Vanilla+: The player who beats the farthest blind wins. (No lives, once your opponent dies you just need to beat the blind they lost on to win)
- **Multiplayer Context System**: Convert cards like "SPEEDRUN" and "Let's Go Gambling" (Phantom) to use new contexts that are passed by network actions (the server)
- **Trap Cards**: Please DM "virtualized" on discord if you are interested in working on this

## 📜 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](https://github.com/V-rtualized/balatro-multiplayer/blob/main/LICENSE.md) file for details.

## 👏 Acknowledgements

- The LocalThunk for creating such an amazing game
- [All the contributors](https://github.com/Balatro-Multiplayer/BalatroMultiplayer/graphs/contributors) for their hard work
- Our Discord community for feedback, testing, and support

---

Join our [Discord server](https://discord.gg/balatromp) for support, to report bugs, or just to chat!
[Website](https://balatromp.com) | [GitHub](https://github.com/Balatro-Multiplayer/balatro-multiplayer)
