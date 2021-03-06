
(function() {
	var bridge = {
			constructor: function() {
				this.handStartNeededCallback = function() { table._startHand() }
				// function(actionStates, playerid) -- { call : double, fold: double, raise: double, check : double}
				this.playerActionNeeded = function(menu, actionStates, playerid) {
					if (this.signalPlayerActionNeeded) {
						this.signalPlayerActionNeeded(actionStates, playerid)
					} else {
						menu.show()
					}
				}
				
				// function(state, winners) -- state = start, flop, turn, river, end
				this.handStateChanged = function(hand, state, winners, callback) {
					this.handStateChangedCallback = callback
					if (this.signalHandStateChanged) {
						this.signalHandStateChanged(state, winners)
					} else {
						if (state === 'end') {
							alert('finished with ' + winners.length + ' players')
						} else if (state == 'start') {
							// Do nothing for now
							// alert('start')
						} else {
							alert('get ready for the ' + state)
						}
						callback()
					}
				}
				
				this.handStartNeeded = function(table, callback) {
					this.handStartNeededCallback = callback
					if (this.signalHandStartNeeded) {
						this.signalHandStartNeeded()
					} else {
						alert('click to start new hand')
						callback()
					}
				}
				
				// function(pots) -- call some named callback - { sum : [ playerids in pot ] }
				this.handResultNeeded = function(hand, pots, callback) {
					this.handResultNeededCallback = callback

					if (this.signalHandResultNeeded) {
						this.signalHandResultNeeded(pots)
					} else {
						for (var i = 0; i < pots.length; ++i) {
							pots[i].winners = [pots[i].players[0]]
						}
						alert('finished with ' + hand.playersInHand.length + ' players')
						callback(pots)
						// hand.table.startHand()
					}
				}
			},
			signalPlayerActionNeeded : null,
			signalHandStateChanged : null,
			signalHandResultNeeded : null,
			signalHandStartNeeded : null
		}

	BC.mapToObj(window.BC, 'bridge', bridge)
})()
