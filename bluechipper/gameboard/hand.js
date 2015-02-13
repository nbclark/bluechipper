
	(function() {
		// classes
		var hand = {
			players: null,
			playerActions: {},
			table: {},
			dealerButtonIndex: 0,
			smallBlindIndex: 0,
			bigBlindIndex: 0,
			actionIndex: 0,
			totalBet: 0,
			lastRaise: 0,
			lastRaiserIndex: -1,
			constructor: function(players, dealerButtonIndex, table) {
				this.players = players
				this.dealerButtonIndex = dealerButtonIndex
				this.table = table

				for (var i = 0; i < this.players.length; ++i) {
					this.playerActions[i] = { bet: 0 }
				}

				this.positionButtons()

				this.exchangeSum(this.smallBlindIndex, this.table.smallBlind)
				this.exchangeSum(this.bigBlindIndex, this.table.bigBlind)

				this.totalBet = this.lastRaise = this.table.bigBlind // min bet

				// Action is on actionIndex
				this.proceed()
			},
			exchangeSum: function(index, sum) {
				player = this.players[index]
				if (player.purse < sum) {
					// TODO
					throw new Exception('Not enough')
				}

				player.withdraw(sum)

				// TODO fix this
				this.playerActions[index].bet += sum
			},
			proceed : function() {
				// We need to calculate the options given the current player and the state
				//
				var player = this.players[this.actionIndex]
				var playerAction = this.playerActions[this.actionIndex]
				var options = { call : undefined, check: undefined, raise: undefined, fold: 0 } // you can always fold

				if (playerAction.bet < this.totalBet) {
					// Their options are to call, raise, fold

					if (playerAction.bet + player.purse <= this.totalBet) {
						options['call'] = playerAction.bet + player.purse
					} else {
						options['call'] = this.totalBet
						options['raise'] = this.totalBet + this.lastRaise
					}

				} else {
					// You can check
					if (this.actionIndex === this.lastRaiserIndex) {
						alert('We are done')
					} else {
						options['raise'] = this.totalBet + this.table.bigBlind
						options['check'] = 0
					}
					// If we have the option to check, that means we are all square, right?
					this.lastRaise = 0
				}

				if (this.players[this.actionIndex].isCurrentUser) {
					// We can act on this device
					this.table.menu.setOptions(options)
					this.table.menu.show(function(action, value) {
						switch (action) {
							case 'check' : {
								// continue on
							} break
							case 'call' : {
								// We called to get to a value of 'value'
								var exchange = value - playerAction.bet
								this.exchangeSum(this.actionIndex, exchange)
								// Change nothing with bets or raises
							} break
							case 'raise' : {
								var exchange = value - playerAction.bet
								this.exchangeSum(this.actionIndex, exchange)
								// We need to increase our raise now
								var raiseAmount = (value) - (this.totalBet) // the raise amount is the amount over the bet
								this.lastRaise = value - this.totalBet
								this.totalBet = value
								this.lastRaiserIndex = this.actionIndex
							} break
							case 'fold' : {
								//
							} break
						}

						this.actionIndex = this.getFirstActivePlayerIndexFrom(this.actionIndex+1)
						this.players[this.actionIndex].layoutButton(this.table.actionButton)
						this.proceed()
					}.bind(this))
				} else {
					// We need to reach out to the other device for the action
				}
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
				this.dealButtonIndex = this.dealerButtonIndex % this.players.length
				this.smallBlindIndex = this.getFirstActivePlayerIndexFrom(this.dealerButtonIndex+1)
				this.bigBlindIndex = this.getFirstActivePlayerIndexFrom(this.dealerButtonIndex+2)

				this.players[this.dealerButtonIndex].layoutButton(this.table.dealerButton)
				this.players[this.smallBlindIndex].layoutButton(this.table.smallBlindButton)
				this.players[this.bigBlindIndex].layoutButton(this.table.bigBlindButton)

				this.actionIndex = this.getFirstActivePlayerIndexFrom(this.dealerButtonIndex+3)
				this.players[this.actionIndex].layoutButton(this.table.actionButton)

				this.lastRaiserIndex = this.actionIndex
			},
		}

		BC.mapToObj(window.BC, 'hand', hand)
	})()
