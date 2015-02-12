
	(function() {
		var button = {
				constructor: function(type) {
					this.type = type
					this.el = ce('div', { id: type })
				}
			}

		BC.mapToObj(window.BC, 'button', button)
	})()
