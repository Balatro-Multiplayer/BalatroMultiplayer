import { GameMode } from "./actions.js"

type GameModeData = {
  startingLives: number

  getBlindFromAnte: (ante: number) => { 
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
    getBlindFromAnte: (ante) => {
      return { boss: 'bl_pvp' }
    }
  },
  'draft': {
    startingLives: 2,
    getBlindFromAnte: (ante) => {
      if (ante < 2) return { }
      else return { small: 'bl_pvp', big: 'bl_pvp', boss: 'bl_pvp' }
    }
  }
}

export default GameModes