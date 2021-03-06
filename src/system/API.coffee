
Q = require "q"

class API

  @gameInstance: null

  @validateIdentifier: (identifier) ->
    defer = Q.defer()
    player = @gameInstance.playerManager.getPlayerById identifier

    defer.resolve {isSuccess: yes, code: 999999, player: player} if player #lol
    defer.resolve {isSuccess: no, code: 10, message: "You aren't logged in!"}

    defer.promise

  # Called on game initialization
  @game =
    handlers:
      broadcastHandler: (handler, context) =>
        @gameInstance.registerBroadcastHandler handler, context
      colorMap: (map) =>
        @gameInstance.registerColors map
      playerLoadHandler: (handler) =>
        @gameInstance.playerManager.registerLoadAllPlayersHandler handler
    content:
      map: (mapName) =>
        @gameInstance.world.maps[mapName]
      battle: (battleId) =>
        @gameInstance.componentDatabase.retrieveBattle battleId

  # Invoked manually to either update or mess with the game
  @gm =
    teleport:
      location:
        single: (playerName, location) =>
          player = @gameInstance.playerManager.getPlayerByName playerName
          @gameInstance.gmCommands.teleportLocation player, location
          null
        mass: (location) =>
          @gameInstance.gmCommands.massTeleportLocation location
          null
      map:
        single: (playerName, map, x, y) =>
          player = @gameInstance.playerManager.getPlayerByName playerName
          @gameInstance.gmCommands.teleport player, map, x, y
          null
        mass: (map, x, y) =>
          @gameInstance.gmCommands.massTeleport map, x, y
          null

    data:
      update: =>
        @gameInstance.doCodeUpdate()
      reload: =>
        @gameInstance.componentDatabase.importAllData()
      setPassword: (identifier, password) =>
        @gameInstance.playerManager.storePasswordFor identifier, password

    event:
      single: (player, eventType, callback) =>
        @gameInstance.eventHandler.doEventForPlayer player, eventType, callback
      global: (eventType, callback) =>
        @gameInstance.globalEventHandler.doEvent eventType, callback

    status:
      ban: (name, callback) =>
        @gameInstance.playerManager.banPlayer name, callback
      unban: (name, callback) =>
        @gameInstance.playerManager.unbanPlayer name, callback

    player:
      createItem: (playerName, type, itemString) =>
        player = @gameInstance.playerManager.getPlayerByName playerName
        @gameInstance.gmCommands.createItemFor player, type, itemString

      giveGold: (playerName, gold) =>
        player = @gameInstance.playerManager.getPlayerByName playerName
        player.gold.add gold

    arrangeBattle: (names) =>
      @gameInstance.gmCommands.arrangeBattle names

  # Invoked either automatically (by means of taking a turn), or when a player issues a command
  @player =
    takeTurn: (identifier) =>
      @validateIdentifier identifier
      .then (res) =>
        @gameInstance.playerManager.playerTakeTurn identifier if res.isSuccess

    gender:
      set: (identifier, newGender) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setGender newGender if res.isSuccess

      remove: (identifier) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setGender '' if res.isSuccess

    auth:
      register: (options) =>
        @gameInstance.playerManager.registerPlayer options

      login: (identifier, suppress) =>
        @gameInstance.playerManager.addPlayer identifier, suppress, no

      loginWithPassword: (identifier, password) =>
        @gameInstance.playerManager.loginWithPassword identifier, password

      setPassword: (identifier, password) =>
        @validateIdentifier identifier
        .then (res) =>
          return (@gameInstance.playerManager.storePasswordFor identifier, password) if res.isSuccess
          res

      authenticate: (identifier, password) =>
        @gameInstance.playerManager.checkPassword identifier, password, yes

      logout: (identifier) =>
        @validateIdentifier identifier
        .then (res) =>
          return (@gameInstance.playerManager.removePlayer identifier) if res.isSuccess
          res

      isTokenValid: (identifier, token) =>
        @validateIdentifier identifier
        .then (res) =>
          return (@gameInstance.playerManager.checkToken identifier, token) if res.isSuccess
          res

    overflow:
      add: (identifier, slot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.manageOverflow "add", slot if res.isSuccess

      sell: (identifier, slot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.manageOverflow "sell", slot if res.isSuccess

      swap: (identifier, slot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.manageOverflow "swap", slot if res.isSuccess

    personality:
      add: (identifier, personality) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.addPersonality personality if res.isSuccess

      remove: (identifier, personality) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.removePersonality personality if res.isSuccess

    priority:
      add: (identifier, stat, points) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.addPriority stat, points if res.isSuccess

      set: (identifier, stats) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setPriorities stats if res.isSuccess

      remove: (identifier, stat, points) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.addPriority stat, -points if res.isSuccess

    pushbullet:
      set: (identifier, apiKey) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setPushbulletKey apiKey if res.isSuccess

      remove: (identifier) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setPushbulletKey '' if res.isSuccess

    string:
      set: (identifier, stringType, string) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setString stringType, string if res.isSuccess

      remove: (identifier, stringType) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setString stringType if res.isSuccess

    pet:
      buy: (identifier, type, name, attr1, attr2) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.buyPet type, name, attr1, attr2 if res.isSuccess

      upgrade: (identifier, stat) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.upgradePet stat if res.isSuccess

      feed: (identifier) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.feedPet() if res.isSuccess

      takeGold: (identifier) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.takePetGold() if res.isSuccess

      giveEquipment: (identifier, itemSlot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.givePetItem itemSlot if res.isSuccess

      sellEquipment: (identifier, itemSlot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.sellPetItem itemSlot if res.isSuccess

      takeEquipment: (identifier, itemSlot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.takePetItem itemSlot if res.isSuccess

      equipItem: (identifier, itemSlot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.equipPetItem itemSlot if res.isSuccess

      unequipItem: (identifier, itemUid) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.unequipPetItem itemUid if res.isSuccess

      setOption: (identifier, option, value) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.setPetOption option, value if res.isSuccess

      swapToPet: (identifier, petId) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.swapToPet petId if res.isSuccess

      changeClass: (identifier, petClass) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.changePetClass petClass if res.isSuccess

    guild:
      create: (identifier, guildName) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.createGuild identifier, guildName if res.isSuccess

      invite: (identifier, invName) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.sendInvite identifier, invName if res.isSuccess

      manageInvite: (identifier, accepted, guildName) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.manageInvite identifier, accepted, guildName if res.isSuccess

      promote: (identifier, memberName) =>
        @validateIdentifier identifier
        .then (res) =>
          return if not res.isSuccess
          guild = res.player.guild
          @gameInstance.guildManager.guildHash[guild].promote identifier, memberName

      demote: (identifier, memberName) =>
        @validateIdentifier identifier
        .then (res) =>
          return if not res.isSuccess
          guild = res.player.guild
          @gameInstance.guildManager.guildHash[guild].demote identifier, memberName if res.isSuccess

      kick: (identifier, playerName) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.kickPlayer identifier, playerName if res.isSuccess

      disband: (identifier) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.disband identifier if res.isSuccess

      leave: (identifier) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.leaveGuild identifier if res.isSuccess

      donate: (identifier, gold) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.donate identifier, gold if res.isSuccess

      buff: (identifier, type, tier) =>
        @validateIdentifier identifier
        .then (res) =>
          @gameInstance.guildManager.addBuff identifier, type, tier if res.isSuccess

    shop:
      buy: (identifier, slot) =>
        @validateIdentifier identifier
        .then (res) ->
          res.player.buyShop slot if res.isSuccess
      
module.exports = exports = API