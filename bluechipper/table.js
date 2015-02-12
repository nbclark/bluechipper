
	(function() {
		// utils
		function ce(tag, props) {
			var e = document.createElement(tag)
			if (props) for (var p in props) e[p] = props[p]
			return e
		}
		function ac(par, el) {
			par.appendChild(el)
		}
		function ic(par, el, index) {
			par.insertBefore(el, par.childNodes[index])
		}
		function rc(par, el) {
			par.removeChild(el)
		}
		Array.prototype.shuffle = function() {
		    for (var i = this.length - 1; i > 0; i--) {
		        var j = Math.floor(Math.random() * (i + 1));
		        var temp = this[i];
		        this[i] = this[j];
		        this[j] = temp;
		    }
		}

		// classes
		var classes = {
			player : {
				isActive: false,
				isPaused: false,
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
			},
			table : {
				isActive: false,
				button: 0,
				action: 0,
				players: [],
				smallBlind: 1,
				bigBlind: 2,
				constructor: function (a,b) {
					this.el = ce('div', { id: 'container' })
					this.pot = new BC.pot()
					this.smallBlindButton = new BC.button('sb')
					this.bigBlindButton = new BC.button('bb')
					this.dealerButton = new BC.button('db')
					this.menu = new BC.menu()

					ac(this.el, this.pot.el)
					ac(this.el, this.smallBlindButton.el)
					ac(this.el, this.bigBlindButton.el)
					ac(this.el, this.dealerButton.el)
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

					this.button = Math.floor(Math.random() * this.players.length)
				},
				startGame: function() {
					this.isActive = true

					// Our button is set
				},
				positionButtons: function() {
					// Button is set, put them onto the screen, and assign action
					// TODO - put rules in for 2 player
					this.players[this.button % this.players.length].layoutButton(this.dealerButton)
					this.players[(this.button+1) % this.players.length].layoutButton(this.smallBlindButton)
					this.players[(this.button+2) % this.players.length].layoutButton(this.bigBlindButton)
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
					var elemIndex = 0;
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
			},
			pot : {
				players : {},
				constructor: function() {
					this.el = ce('div', { id: 'pot' })
				},
			},
			button: {
				constructor: function(type) {
					this.type = type
					this.el = ce('div', { id: type })
				}
			},
			menu : {
				options: [],
				constructor: function() {
					this.el = ce('div', { id: 'menu' })
					var os = ['check','call','fold','bet','raise']
					for (var i = 0; i < os.length; ++i) {
						var o = new BC.menuOption(os[i])
						this.options.push(o)
						ac(this.el, o.el)
					}
				},
				show: function() {
					this.el.style.bottom = 0;
				},
				hide: function() {
					this.el.style.bottom = -this.el.clientHeight;
				}
			},
			menuOption : {
				disabled: false,
				constructor: function(action, disabled) {
					this.action = action
					this.el = ce('a', { id: action })
					this.el.innerHTML = action
					this.el.onclick = this.clicked.bind(this)
				},
				clicked: function() {
					alert(this.action)
				}
			}
		}

		function mapToObj(container, name, map) {
			var cons = map['constructor']
			container[name] = cons ? cons : function() {}

			for (var prop in map) {
				container[name].prototype[prop] = map[prop]
			}
		}

		window.BC = {}

		for (var className in classes) {
			mapToObj(window.BC, className, classes[className])
		}
	})()

	var table = new BC.table()
	for (var i = 0; i < 8; ++i) {
		table.addPlayer(i+1, 100)
	}

	document.body.appendChild(table.el)

	table.randomizePlayers()
	table.layoutPlayers()
	table.startGame()