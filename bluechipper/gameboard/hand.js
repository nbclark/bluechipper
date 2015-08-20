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
		totalPot: 0,
		lastRaise: 0,
		lastRaiserIndex: -1,
		round: 0,
		constructor: function(bridge, players, dealerButtonIndex, table) {
			this.bridge = bridge
			this.players = players
			this.dealerButtonIndex = dealerButtonIndex
			this.table = table

			for (var i = 0; i < this.players.length; ++i) {
				this.playerActions[i] = { bet: 0, totalBet: 0 }
				this.players[i].isInHand = true
			}

			this.assignButtons()

			// TODO - we need to handle if they have money, but not the full blind
			this.exchangeSum(this.smallBlindIndex, this.table.smallBlind)

			// TODO - we need to handle if they have money, but not the full blind
			this.exchangeSum(this.bigBlindIndex, this.table.bigBlind)

			this.totalBet = this.lastRaise = this.table.bigBlind // min bet

			// Action is on actionIndex
			// this.proceed()
		},
		getState: function() {
			return {
				dealerButtonIndex: this.dealerButtonIndex,
				smallBlindIndex: this.smallBlindIndex,
				bigBlindIndex: this.bigBlindIndex,
				actionIndex: this.actionIndex,
				totalBet: this.totalBet,
				totalPot: this.totalPot,
				lastRaise: this.lastRaise,
				lastRaiserIndex: this.lastRaiserIndex,
				round: this.round,
				players: this.players.map(function(p) { return p.getState() }),
				playerActions: this.playerActions
			}
		},
		loadState: function(state, players) {
			this.dealerButtonIndex = state.dealerButtonIndex
			this.smallBlindIndex = state.smallBlindIndex
			this.bigBlindIndex = state.bigBlindIndex

			// Do some layout
			this.positionButtons()
			
			// Set some more - actionIndex is modified in positionButtons
			this.actionIndex = state.actionIndex
			this.totalBet = state.totalBet
			this.totalPot = state.totalPot
			this.lastRaise = state.lastRaise
			this.lastRaiserIndex = state.lastRaiserIndex
			this.round = state.round
			this.players = players
			this.playerActions = state.playerActions
			
			// Let's go
			this.start()
		},
		start: function() {
			var playersInHand = this.playersInHand()
			this.bridge.handStateChanged(this, 'start', playersInHand.map(function(player) { return player.id }), function() {
				this.proceed()
			}.bind(this))
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
			this.playerActions[index].totalBet += sum

			this.totalPot += sum
			this.table.pot.el.innerHTML = this.totalPot
		},
		signalResult: function(playerRanks) {
			// [[]]
		},
		checkState: function() {
			var roundFinished = false
			var handFinished = false
			var playersInHand = this.playersInHand()
			// If we have called around, we are finished
			if (playersInHand.length == 1) {
				handFinished = true
			} else if (this.actionIndex === this.lastRaiserIndex) {
				roundFinished = true
			} else {
				// We need to check if this.lastRaiserIndex is out of the hand
				// and if so, we need to end if we skipped over him/her
				if (!this.players[this.lastRaiserIndex].isInHand) {
					this.lastRaiserIndex = this.actionIndex
				}
			}

			if (handFinished) {
				// TODO assign chips here
				// We actually need to know who won the hand, huh? Well one person, so I guess we know
				// For now we will give it all to the first person
				playersInHand[0].withdraw(-this.totalPot)
				this.table.pot.el.innerHTML = 0
				
				this.bridge.handStateChanged(this, 'end', playersInHand.map(function(player) { return player.id }), function() {
					// Start another hand?
					this.table.startHand()
				}.bind(this))
			} else if (roundFinished) {
				// TODO - change the state around
				if (this.round == 3) {
					// We are at the river
					var pots = {}
					for (var i = 0; i < this.players.length; ++i) {
						if (this.players[i].isInHand) {
							var total = this.playerActions[i].totalBet;
							if (!pots[total]) {
								pots[total] = [];
							}
							pots[total].push(this.players[i].id)
						}
					}
					
					// Fire off a request for the winners of the main + side pots
					this.bridge.handResultNeeded(this, pots)
					return
				} else {
					this.totalBet = 0
					this.lastRaise = this.table.bigBlind
					this.round++
					var roundName;
					
					if (this.round == 1) {
						roundName = 'flop'
					} else if (this.round == 2) {
						roundName = 'turn'
					} else if (this.round == 3) {
						roundName = 'river'
					}

					this.bridge.handStateChanged(this, roundName, playersInHand.map(function(player) { return player.id }), function() {
						for (var i = 0; i < this.players.length; ++i) {
							this.playerActions[i].bet = 0
							this.players[i].el.style.opacity = '1'
						}
	
						this.actionIndex = this.getFirstActivePlayerIndexFrom(this.smallBlindIndex)
						this.lastRaiserIndex = this.actionIndex
						
						this.proceed()
					}.bind(this))
				}
			} else {
				// Do nothing - just keep proceeding around
			}

			this.proceed()
		},
		proceed : function() {
			// We need to calculate the options given the current player and the state
			//
			this.players[this.actionIndex].layoutButton(this.table.actionButton)

			var player = this.players[this.actionIndex]
			var playerAction = this.playerActions[this.actionIndex]
			var options = { call : undefined, check: undefined, raise: undefined, fold: 0 } // you can always fold

			if (playerAction.bet < this.totalBet) {
				// Their options are to call, raise, fold

				// They don't have enough to call, so put them all in
				if (playerAction.bet + player.purse <= this.totalBet) {
					options['call'] = playerAction.bet + player.purse
				} else {
					options['call'] = this.totalBet

					// They have enough to call, but not to raise the full amount
					// They can go all in, but we have to do side-pots here
					// For now, perhaps just detect this situation and prompt to reconcile
					// Either way, we need to keep the min raise to what the previous raise was
					// not the new partial raise
					//
					// Actually, we know the total amount put in by each player (playerAction.totalBet)
					// so we can simply use those amounts to group and award the pots/side-pots
					if (playerAction.bet + player.purse < this.totalBet + this.lastRaise) {
						options['raise'] = playerAction.bet + player.purse
						this.sidePotReconcilliationNeeded = true
					} else {
						options['raise'] = this.totalBet + this.lastRaise
					}
				}

			} else {
				// You can check
				if (playerAction.bet + player.purse < this.totalBet + this.table.bigBlind) {
					if (player.purse > 0) {
						options['raise'] = player.purse
					}
				} else {
					options['raise'] = this.totalBet + this.table.bigBlind
				}
				options['check'] = 0

				// If we have the option to check, that means we are all square, right?
				this.lastRaise = 0
			}

			if (this.players[this.actionIndex].isCurrentUser) {
				// We can act on this device
				this.table.menu.setOptions(options)
				this.table.menu.requestAction(this.players[this.actionIndex].id, function(action, value) {
					switch (action) {
						case 'check' : {
							// continue on
						} break
						case 'call' : {
							// We called to get to a value of 'value'
							var exchange = value - playerAction.bet
							this.exchangeSum(this.actionIndex, exchange)
							// Change nothing with bets or raises

							needStateCheck = true
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
							player.isInHand = false
							// TODO - not this
							player.el.style.opacity = '0.15'

							if (this.lastRaiserIndex === this.actionIndex) {
								// We folded when we were the last person around
								// This shouldn't really happen...
								// It only happens if they are first to act and fold - ugh
								// But when it does, how do we handle?
								// TODO - perhaps we just don't let them fold for now
							}
						} break
					}

					this.actionIndex = this.getFirstActivePlayerIndexFrom(this.actionIndex+1)

					this.checkState()
				}.bind(this))
			} else {
				// We need to reach out to the other device for the action
			}
		},
		playersInHand: function() {
			return this.players.filter(function(p) { return p.isInHand })
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

			this.players[this.dealerButtonIndex].layoutButton(this.table.dealerButton)
			this.players[this.smallBlindIndex].layoutButton(this.table.smallBlindButton)
			this.players[this.bigBlindIndex].layoutButton(this.table.bigBlindButton)
			this.players[this.actionIndex].layoutButton(this.table.actionButton)
		},
		assignButtons: function() {
			// Button is set, put them onto the screen, and assign action
			// TODO - put rules in for 2 player
			this.dealButtonIndex = this.dealerButtonIndex % this.players.length
			this.smallBlindIndex = this.getFirstActivePlayerIndexFrom(this.dealerButtonIndex+1)
			this.bigBlindIndex = this.getFirstActivePlayerIndexFrom(this.dealerButtonIndex+2)
			this.actionIndex = this.getFirstActivePlayerIndexFrom(this.dealerButtonIndex+3)
			this.lastRaiserIndex = this.actionIndex
			
			this.positionButtons()
		},
	}

	BC.mapToObj(window.BC, 'hand', hand)
})()
