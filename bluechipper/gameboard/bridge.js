
(function() {
	var bridge = {
			constructor: function() {
				this.playerActionNeeded = null // function(actionStates, playerid) -- { call : double, fold: double, raise: double, check : double}
				this.handStateChanged = null // function(state, winners) -- state = start, flop, turn, river, end
				this.handResultNeeded = null // function(pots) -- call some named callback - { sum : [ playerids in pot ] }
			}
		}

	BC.mapToObj(window.BC, 'bridge', bridge)
})()
