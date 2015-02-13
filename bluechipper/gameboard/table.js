
	(function() {
		var table = {
			isActive: false,
			buttonIndex: 0,
			actionIndex: 0,
			players: [],
			smallBlind: 1,
			bigBlind: 2,
			constructor: function (a,b) {
				this.el = ce('div', { id: 'container' })
				this.pot = new BC.pot()
				this.smallBlindButton = new BC.button('sb')
				this.bigBlindButton = new BC.button('bb')
				this.dealerButton = new BC.button('db')
				this.actionButton = new BC.button('ab')
				this.menu = new BC.menu()

				ac(this.el, this.pot.el)
				ac(this.el, this.smallBlindButton.el)
				ac(this.el, this.bigBlindButton.el)
				ac(this.el, this.dealerButton.el)
				ac(this.el, this.actionButton.el)
				ac(this.el, this.menu.el)
			},
			addPlayer: function(name, value) {
				var p = new BC.player(name, value)

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
			},
			randomizePlayers: function() {
				// If we shuffle the players, then remove/add, we change the order
				this.players.shuffle()
				for (var i = 0; i < this.players.length; ++i) {
					rc(this.el, this.players[i].el)
					ac(this.el, this.players[i].el)
				}

				this.buttonIndex = Math.floor(Math.random() * this.players.length)
			},
			startGame: function() {
				this.isActive = true

				// Our button is set
				// We will now communicate back to the native app (TBD)
				// We will then show the action sheet if we are the host player, and the action is on us
				this.positionButtons()
			},
			getFirstActivePlayerIndexFrom: function(startIndex) {
				startIndex = startIndex % this.players.length
				var startPlayer = this.players[startIndex]

				for (var i = 0; i < this.players.length; ++i) {
					var idx = (startIndex + i) % this.players.length
					if (this.players[idx].isInHand) return idx
				}

				return -1
			},
			positionButtons: function() {
				// Button is set, put them onto the screen, and assign action
				// TODO - put rules in for 2 player
				this.players[this.buttonIndex % this.players.length].layoutButton(this.dealerButton)
				this.players[this.getFirstActivePlayerIndexFrom(this.buttonIndex+1)].layoutButton(this.smallBlindButton)
				this.players[this.getFirstActivePlayerIndexFrom(this.buttonIndex+2)].layoutButton(this.bigBlindButton)

				this.actionIndex = this.getFirstActivePlayerIndexFrom(this.buttonIndex+3)
				this.proceed()
			},
			proceed: function () {
				this.players[this.actionIndex % this.players.length].layoutButton(this.actionButton)

				this.menu.show(function(result) {
					this.menu.hide()

					if (result == 'fold') {
						this.players[this.actionIndex].isInHand = false
						this.players[this.actionIndex].el.style.opacity = 0.15 // do something better here
					}

					this.actionIndex = this.getFirstActivePlayerIndexFrom(this.actionIndex+1)

					// TODO - this is where we need to call back to the app
					// PARSE it up
					this.proceed()
				}.bind(this))
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
				for (var i = 0; i < sidePlayersPerSide; i++, elemIndex++) {
					this.players[elemIndex].setPosition(null, ((vertSpace + cellSize) * (i+1)) - cellSize - margin, 0, null)
				}
				// Bottom
				for (var i = 0; i < topPlayersPerSide; i++, elemIndex++) {
					this.players[elemIndex].setPosition(null, null, ((horizSpace + cellSize) * (i+1)) - cellSize - margin, 0)
				}
				// Left -- recalculate spacing since we might not have equal amounts per side, so the spacing is off
				sidePlayersPerSide = this.players.length - topPlayersPerSide*2 - sidePlayersPerSide
				var vertSpace = Math.floor((this.el.clientHeight - sidePlayersPerSide * cellSize) / (sidePlayersPerSide + 1))
				for (var i = 0; i < sidePlayersPerSide && elemIndex < this.players.length; i++, elemIndex++) {
					this.players[elemIndex].setPosition(0, null, null, ((vertSpace + cellSize) * (i+1)) - cellSize - margin)
				}
			}
		}

		BC.mapToObj(window.BC, 'table', table)
	})()
