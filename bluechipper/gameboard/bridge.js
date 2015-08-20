
(function() {
	var bridge = {
			constructor: function() {
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
							alert('start')
						} else {
							alert('get ready for the ' + state)
						}
						callback()
					}
				}
				
				// function(pots) -- call some named callback - { sum : [ playerids in pot ] }
				this.handResultNeeded = function(hand, pots, callback) {
					this.handResultNeededCallback = callback
					alert('handResultNeeded')
					if (this.signalHandResultNeeded) {
						this.signalHandResultNeeded(pots)
					} else {
						hand.playersInHand[0].withdraw(-hand.totalPot)
						alert('finished with ' + hand.playersInHand.length + ' players')
						hand.table.startHand()
					}
				}
			},
			signalPlayerActionNeeded : null,
			signalHandStateChanged : null,
			signalHandResultNeeded : null
		}

	BC.mapToObj(window.BC, 'bridge', bridge)
})()
