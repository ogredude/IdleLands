
_ = require "lodash"
Equipment = require "../item/Equipment"
chance = new (require "chance")()

class BossFactory
  constructor: (@game) ->

  createBossPartyNames: (partyName) ->
    BossInformation.parties[partyName]

  createBoss: (name) ->
    currentTimer = BossInformation.timers[name]

    try
      respawnTimer = BossInformation.bosses[name].respawn or 3600
    catch e
      @game.errorHandler.captureException new Error "INVALID BOSS RESPAWN/NAME: #{name}"

    return if ((new Date) - currentTimer) < respawnTimer * 1000

    setAllItemClasses = "guardian"

    baseObj = BossInformation.bosses[name]
    statObj = baseObj.stats
    statObj.name = name
    monster = @game.monsterGenerator.generateMonster baseObj.score, statObj
    _.each baseObj.items, (item) ->
      baseItem = _.clone BossInformation.items[item.name]
      baseItem.name = item.name
      baseItem.itemClass = setAllItemClasses
      monster.equip new Equipment baseItem

    monster.on "combat.party.lose", (winningParty) =>
      _.each winningParty, (member) =>

        return if member.isMonster

        _.each baseObj.items, (item) =>
          probability = Math.max 0, Math.min 100, item.dropPercent + member.calc.luckBonus()
          return if not (chance.bool likelihood: probability)
          baseItem = _.clone BossInformation.items[item.name]
          baseItem.name = item.name
          baseItem.itemClass = setAllItemClasses

          itemInst = new Equipment baseItem

          @game.equipmentGenerator.addPropertiesToItem itemInst, member.calc.luckBonus()

          event = rangeBoost: 2, remark: "%player looted %item from the corpse of <player.name>#{name}</player.name>."

          if @game.eventHandler.tryToEquipItem event, member, itemInst
            member.emit "event.bossbattle.loot", member, name, item

        _.each baseObj.collectibles, (item) ->
          probability = Math.max 0, Math.min 100, item.dropPercent + member.calc.luckBonus()
          return if not (chance.bool likelihood: probability)

          baseCollectible =
            name: item.name
            rarity: "guardian"

          member.handleCollectible baseCollectible

          member.emit "event.bossbattle.lootcollectible", member, name, item

        member.emit "event.bossbattle.win", member, name

      BossInformation.timers[name] = new Date()

    monster.on "combat.party.win", (losingParty) ->

      _.each losingParty, (member) ->
        member.emit "event.bossbattle.lose", member, name

        member.handleTeleport tile: object: properties: toLoc: baseObj.teleportOnDeath, movementType: "teleport" if baseObj.teleportOnDeath

    monster

class BossInformation
  @timers = {}
  @parties = require "../../config/bossparties.json"
  @items = require "../../config/bossitems.json"
  @bosses = require "../../config/boss.json"

module.exports = exports = BossFactory
