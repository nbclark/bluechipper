(function() {
	// classes
	var player = {
		isActive: true,
		isPaused: false,
		isInHand: true,
		isCurrentUser: true,
		purse: 5,
		constructor: function(id, name, value) {
			this.id = id
			this.name = name
			this.el = ce('div', { className: 'player', innerHTML: name })
			this.withdraw(0)
		},
		withdraw: function(sum) {
			// TODO bounds checking
			this.purse -= sum

			this.el.innerHTML = this.name + ' - ' + this.purse
		},
		deposit: function(sum) {
			// TODO bounds checking
			this.purse += sum

			this.el.innerHTML = this.name + ' - ' + this.purse
		},
		setPosition: function(l, t, r, b) {
			this.l = l, this.t = t, this.r = r, this.b = b
			this.el.style.left = (l !== null) ? l + 'px' : 'initial'
			this.el.style.top = (t !== null) ? t + 'px' : 'initial'
			this.el.style.right = (r !== null) ? r + 'px' : 'initial'
			this.el.style.bottom = (b !== null) ? b + 'px' : 'initial'
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
