(function() {
	// classes
	var classes = {
		menu : {
			options: {},
			actionValues: {},
			callback: function() {},
			menuHandler : null,
			constructor: function(bridge) {
				this.bridge = bridge
				this.el = ce('div', { id: 'menu' })
				var os = ['check','call','fold','raise']
				for (var i = 0; i < os.length; ++i) {
					var o = new BC.menuOption(os[i], false, this.menuOptionCallback.bind(this))
					this.options[os[i]] = o
					ac(this.el, o.el)
				}
			},
			menuOptionCallback: function(action) {
				this.callback(action, this.actionValues[action])
			},
			requestAction: function(playerId, callback) {
				this.callback = callback
				this.bridge.playerActionNeeded(this, this.actionValues, playerId)
			},
			show: function() {
				this.el.style.bottom = 0
			},
			hide: function() {
				this.el.style.bottom = -this.el.clientHeight
			},
			setOptions: function(actions) {
				this.actionValues = {}
				// { call : amount, check: 0, raise: min, fold:0 }
				var optionCount = 0
				if (actions['call'] !== undefined) {
					this.options['call'].el.style.display = 'block'
					this.options['call'].el.innerHTML = 'Call (' + actions['call'] + ')'
					this.actionValues['call'] = actions['call']
					optionCount++
				} else {
					this.options['call'].el.style.display = 'none'
				}

				if (actions['check'] !== undefined) {
					this.options['check'].el.style.display = 'block'
					this.options['check'].el.innerHTML = 'Check (' + actions['check'] + ')'
					this.actionValues['check'] = 0
					optionCount++
				} else {
					this.options['check'].el.style.display = 'none'
				}

				if (actions['raise'] !== undefined) {
					this.options['raise'].el.style.display = 'block'
					this.options['raise'].el.innerHTML = 'Raise (' + actions['raise'] + '+)'
					this.actionValues['raise'] = actions['raise']
					optionCount++
				} else {
					this.options['raise'].el.style.display = 'none'
				}

				if (actions['fold'] !== undefined) {
					this.options['fold'].el.style.display = 'block'
					this.options['fold'].el.innerHTML = 'Fold (' + actions['fold'] + ')'
					this.actionValues['fold'] = 0
					optionCount++
				} else {
					this.options['fold'].el.style.display = 'none'
				}

				// TODO - putting a height here is bad
				this.el.style.height = (optionCount * 50) + 'px'
			}
		},
		menuOption : {
			disabled: false,
			callback: function() {},
			constructor: function(action, disabled, callback) {
				this.action = action
				this.el = ce('a', { id: action })
				this.el.innerHTML = action
				this.el.onclick = this.clicked.bind(this)
				this.callback = callback
			},
			clicked: function() {
				this.callback(this.action)
			}
		}
	}

	for (var className in classes) {
		BC.mapToObj(window.BC, className, classes[className])
	}
})()
