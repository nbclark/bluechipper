
	(function() {
		// classes
		var player = {
			isActive: false,
			isPaused: false,
			isInHand: true,
			purse: 100,
			constructor: function(name, value) {
				this.name = name
				this.el = ce('div', { className: 'player', innerHTML: name })
			},
			setPosition: function(l, t, r, b) {
				this.l = l, this.t = t, this.r = r, this.b = b
				if (l !== null) this.el.style.left = l + 'px'
				if (t !== null) this.el.style.top = t + 'px'
				if (r !== null) this.el.style.right = r + 'px'
				if (b !== null) this.el.style.bottom = b + 'px'
			},
			setActive: function(active) {
				this.isActive = active
			},
			setPurse: function(purse) {
				this.purse = purse
			},
			layoutButton: function(button) {
				button.el.style.left = (this.l !== null)  ? this.l + 'px' : 'initial'
				button.el.style.top = (this.t !== null) ? this.t + 'px' : 'initial'
				button.el.style.right = (this.r !== null) ? this.r + 'px' : 'initial'
				button.el.style.bottom = (this.b !== null) ? this.b + 'px' : 'initial'
			}
		}

		BC.mapToObj(window.BC, 'player', player)
	})()
