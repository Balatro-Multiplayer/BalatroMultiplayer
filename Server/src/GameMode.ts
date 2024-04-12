import { GameMode } from "./actions.js"

type GameModeData = {
  startingLives: number

  getBlindFromAnte: (ante: number, options: any) => { 
    small?: string
    big?: string
    boss?: string 
  }

  // TODO: Validate lobby options when they differ per gamemode
}

const GameModes: {
  [key in GameMode]: GameModeData
} = {
  'attrition': {
    startingLives: 4,
    getBlindFromAnte: (ante, options) => {
      return { boss: 'bl_pvp' }
    }
  },
  'draft': {
    startingLives: 2,
    getBlindFromAnte: (ante, options) => {
      const starting_antes = options?.draft_starting_antes ? parseInt(options.draft_starting_antes) : 3
      if (ante <= starting_antes) return { }
      else return { small: 'bl_pvp', big: 'bl_pvp', boss: 'bl_pvp' }
    }
  }
}

export default GameModes