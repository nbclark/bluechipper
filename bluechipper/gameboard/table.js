
	(function() {
		var table = {
			isActive: false,
			buttonIndex: 0,
			players: [],
			smallBlind: 1,
			bigBlind: 2,
			_hand: null,
			constructor: function (bridge) {
				this.bridge = bridge
				this.el = ce('div', { id: 'container' })
				this.loadingEl = ce('div', { id: 'loading' })
				this.pot = new BC.pot()
				this.smallBlindButton = new BC.button('sb')
				this.bigBlindButton = new BC.button('bb')
				this.dealerButton = new BC.button('db')
				this.actionButton = new BC.button('ab')
				this.menu = new BC.menu(bridge)
				this.players = []

				ac(this.el, this.loadingEl)
				ac(this.el, this.pot.el)
				ac(this.el, this.smallBlindButton.el)
				ac(this.el, this.bigBlindButton.el)
				ac(this.el, this.dealerButton.el)
				ac(this.el, this.actionButton.el)
				ac(this.el, this.menu.el)
			},
			getState: function() {
				return {
					isActive: this.isActive,
					buttonIndex: this.buttonIndex,
					players : this.players.map(function (p) { return p.getState() }),
					hand : this._hand ? this._hand.getState() : null
				}
			},
			loadState: function(state) {
				// Adjust our current state to match the one passed in
				// Ideally we should do a diff and only change what we need to
				// The first time we load, we can add players, and skip the randomize
				// to put people in a fixed order
				// (I guess randomizing we can skip since they came in order)
				// We should be able to call this function over and over with no effect
				this.buttonIndex = state.buttonIndex
				
				// Load the players (in theory we should remove old players)
				// Or at least do a diff of the new ones
				// TODO - diff new players
				for (var i = 0; i < state.players.length; ++i) {
					var p = state.players[i]
					var player = (i < this.players.length) ? this.players[i] : this.addPlayer(p.id, p.name, p.purse)
					player.loadState(p)
				}
				
				// Remove any extra players we may have (in case someone dropped out)
				if (state.players.length < this.players.length) {
					for (var i = this.players.length; i > state.players.length; i--) {
						// TODO - not sure the syntax, but remove from array, and remove from dom
						this.players.slice(i-1, i)[0].remove()
					}
				}
				
				// Get players in position
				this.layoutPlayers()
				
				// We are active now
				this.isActive = state.isActive

				if (state.hand) {
					// Load the hand (only create if new)
					if (!this._hand || this._hand.dealerButtonIndex != state.hand.dealerButtonIndex) {
						this._hand = new BC.hand(this.bridge, this.activePlayers(), state.hand.dealerButtonIndex, this)
					}
					this._hand.loadState(state.hand, this.activePlayers())
				} else {
					this.startHand()
				}
			},
			addPlayer: function(id, name, value) {
				var p = new BC.player(id, name, value)

				if (this.isActive) {
					// Game is active, we need to insert them randomly
					var index = Math.floor(Math.random()*(this.players.length+1))
					this.players.splice(index, 0, p)
					ic(this.el, p.el, index)
				} else {
					// We can push to the end
					this.players.push(p)
					ac(this.el, p.el)
				}
				
				return p
			},
			randomizePlayers: function() {
				// If we shuffle the players, then remove/add, we change the order
				this.players.shuffle()
				for (var i = 0; i < this.players.length; ++i) {
					rc(this.el, this.players[i].el)
					ac(this.el, this.players[i].el)
				}

				// Select the first player randomly
				this.buttonIndex = Math.floor(Math.random() * this.activePlayers().length)
			},
			startGame: function() {
				this.isActive = true
				this.loadingEl.style.display = 'none'

				// Our button is set
				// We will now communicate back to the native app (TBD)
				// We will then show the action sheet if we are the host player, and the action is on us
				this.startHand(true)
			},
			activePlayers: function() {
				return this.players.filter(function(p) { return p.isActive })
			},
			startHand: function(force) {
				this._hand = null
				
				if (force) {
					this._startHand()
				} else {
					this.bridge.handStartNeeded(this, function() {
						this._startHand()
					}.bind(this))
				}
			},
			_startHand : function() {
				this._hand = new BC.hand(this.bridge, this.activePlayers(), this.buttonIndex, this)
				this.buttonIndex = (this.buttonIndex + 1) % this.activePlayers().length;
				
				this._hand.start()
			},
			layoutPlayers: function() {
				var ratio = this.el.clientHeight / this.el.clientWidth
				var cellSize = this.players[0].el.clientWidth
				var margin = 5

				// If we assume that we have one side as the unit length 1,
				// then the unit-perimeter is 2 + the ratio * 2
				var totalSideSpace = ratio * 2 + 2
				var playersPerSide = this.players.length / totalSideSpace
				var topPlayersPerSide = 0
				var sidePlayersPerSide = 0

				// Taller than we are wide
				if (ratio > 1) {
					topPlayersPerSide = Math.ceil(playersPerSide)
				} else {
					topPlayersPerSide = Math.floor(playersPerSide)
				}

				sidePlayersPerSide = Math.ceil((this.players.length - 2 * topPlayersPerSide) / 2)

				// We are going to put playersPerSide on the top, bottom, left, right until we are full
				var elemIndex = 0
				var horizSpace = Math.floor((this.el.clientWidth - topPlayersPerSide * cellSize) / (topPlayersPerSide + 1))
				var vertSpace = Math.floor((this.el.clientHeight - sidePlayersPerSide * cellSize) / (sidePlayersPerSide + 1))

				// Top
				for (var i = 0; i < topPlayersPerSide; i++, elemIndex++) {
					this.players[elemIndex].setPosition(((horizSpace + cellSize) * (i+1)) - cellSize - margin, 0)
				}
				// Right
				for (var i = 0; i < sidePlayersPerSide && elemIndex < this.players.length; i++, elemIndex++) {
					this.players[elemIndex].setPosition(null, ((vertSpace + cellSize) * (i+1)) - cellSize - margin, 0, null)
				}
				// Bottom
				for (var i = 0; i < topPlayersPerSide && elemIndex < this.players.length; i++, elemIndex++) {
					this.players[elemIndex].setPosition(null, null, ((horizSpace + cellSize) * (i+1)) - cellSize - margin, 0)
				}
				// Left -- recalculate spacing since we might not have equal amounts per side, so the spacing is off
				sidePlayersPerSide = this.players.length - topPlayersPerSide*2 - sidePlayersPerSide
				var vertSpace = Math.floor((this.el.clientHeight - sidePlayersPerSide * cellSize) / (sidePlayersPerSide + 1))
				for (var i = 0; i < sidePlayersPerSide && elemIndex < this.players.length; i++, elemIndex++) {
					this.players[elemIndex].setPosition(0, null, null, ((vertSpace + cellSize) * (i+1)) - cellSize - margin)
				}
				
				if (this._hand) {
					this._hand.positionButtons()
				}
			}
		}

		BC.mapToObj(window.BC, 'table', table)
	})()
