# A Balatro Multiplayer Mod

This is an **WIP** Balatro multiplayer mod developed by virtualized and TGMM.

If you want to get in touch for any reason add `virtualized` on discord or send an email to `v@virtualized.dev`.

This project will remain free and open source. It will also be continuously maintained, at least within the near future.

If you make a video or stream Balatro using this mod then feel free to send me a DM on either platform above with a link, I would love to take a look :)

## Goals for First Release

- A public server everyone will connect to by default
  - We may support private servers but probably won't be making an non-programmer friendly way of making one (eg. Basic knowledge of Docker and port forwarding)
- At least 2 out of 4 planned game modes implemented

## Planned Gamemodes

- Attrition (1v1)
  - Both players start with 4 lives, every boss round is a competition between players where the player with the lower score loses a life.
- Draft (1v1)
  - Both players play a set amount of antes simultaneously, then they play an ante where every round the player with the higher scorer wins, player with the most round wins in the final ante is the victor.
- Heads Up (1v1)
  - Both players play the first ante, then must keep beating the opponents previous score or lose.
- Battle Royale (8p)
  - Draft, except there are up to 8 players and every player only has 1 life.

\*Gamemode names and descriptions subject to change. 8p gamemodes will not be focused on until 1v1 gamemodes are stable.

## Installation

\*These steps won't work out of the box at the moment, as there is no public server to connect to. If you would like to host your own server to test the current progress then follow the steps below to 

### 1. Install [Steamodded](https://github.com/Steamopollys/Steamodded/tree/main)

- Follow instructions to intall at that link
- Currently Windows Defender recognizes Steamodded as a Trojan, you should always do your own research and not just randomly trust me to tell you it isn't a Trojan, but it isn't
  - If this is scary, you can alternatively run the source code by running steamodded_injector.py instead of the exe file in releases

### 2. Download the "Multiplayer" folder into your Balatro Mods folder

(I may add a release to make this more straight forward but for now) 
- Click the green "Code" button > "Download Zip" 
- Unzip and move the "Multiplayer" folder inside to your Balatro mods folder
  - Steamodded creates this folder
  - Default location is `%appdata%/Balatro/Mods on Windows`

### 3. Set `Config.lua`

- If there is no `Config.lua` file in the Multiplayer folder, then there is no public server yet, you need to either [Create a Dedicated Server](#creating-a-dedicated-server) or have a friend that does.
- The `example.Config.lua` file does nothing and is just there for you to use as a Config template 
  - ie. when you have a dedicated server to connect to, rename this file to `Config.lua` and change the values

### 4. Launch Balatro

- You can confirm that the mod is working if you see the "x.x.x-Multiplayer" version tag in the top right of the main menu
  - Note, this does not confirm whether you are successfully connected to the server, just whether the mod is installed properly
- Alternatively you can click Steamodded's "Mods" button in the main menu and "Multiplayer by Virtualized" should be listed there

## Creating a Dedicated Server

*This will not be required on full release, there will be a public server available to anyone

*Dedicated is a bit missleading, there is no matchmaking or server browser, it is just a seperate program from the base mod

*These steps assume you have solid understanding of computers and a bit of programming knowledge

### 1. Install [Docker Compose](https://docs.docker.com/compose/install/)

### 2. Download the "Server" folder

### 3. Run the `Server/docker-compose.yml` file with Docker Compose

- Use Docker Desktop for GUI or the `docker compose up` command in terminal/cmd

- Port 8788 needs to be forwarded for anyone else to connect, this port can be configured by changing this line in `docker-compose.yml`:
```
ports:
      - "your_port_here:8080"
```

- All clients that you want to connect to the server needs to modify their `Multiplayer/Config.lua` to have your ip as the value for `Config.URL` and your port (if you changed it) for the value of `Config.PORT`
