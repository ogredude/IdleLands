
Event = require "../Event"
Party = require "../Party"

_ = require "lodash"

`/**
 * This event handles building a monster encounter for a player.
 *
 * @name MonsterBattle
 * @category Player
 * @package Events
 */`
class MonsterBattleEvent extends Event
  go: ->
    @event.player = @player

    new Party @game, @player if not @player.party
    party = @player.party
    return if not @player.party

    monsterParty = null

    if party.level() > 100
      monsterParty = @game.monsterGenerator.generateScalableMonsterParty party

    else
      monsterParty = @game.monsterGenerator.generateMonsterParty party.score()

    monsterParty.players = _.compact monsterParty.players
    return if (not monsterParty or monsterParty.players.length is 0)

    @game.startBattle [monsterParty, @player.party], @event
    @player.emit "event.monsterbattle", @player

module.exports = exports = MonsterBattleEvent