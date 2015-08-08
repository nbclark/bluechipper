(function() {
	// classes
	var pot = {
		players : {},
		constructor: function() {
			this.el = ce('div', { id: 'pot' })
		},
	}

	BC.mapToObj(window.BC, 'pot', pot)
})()
