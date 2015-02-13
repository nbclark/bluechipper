
	(function() {
		// classes
		var classes = {
			menu : {
				options: {},
				actionValues: {},
				callback: function() {},
				constructor: function() {
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
				show: function(callback) {
					this.callback = callback
					this.el.style.bottom = 0
				},
				hide: function() {
					this.el.style.bottom = -this.el.clientHeight
				},
				setOptions: function(actions) {
					// { call : amount, check: 0, raise: min, fold:0 }
					if (actions['call'] !== undefined) {
						this.options['call'].el.style.display = 'block'
						this.options['call'].el.innerHTML = 'Call (' + actions['call'] + ')'
						this.actionValues['call'] = actions['call']
					} else {
						this.options['call'].el.style.display = 'none'
					}

					if (actions['check'] !== undefined) {
						this.options['check'].el.style.display = 'block'
						this.options['check'].el.innerHTML = 'Check (' + actions['check'] + ')'
						this.actionValues['check'] = 0
					} else {
						this.options['check'].el.style.display = 'none'
					}

					if (actions['raise'] !== undefined) {
						this.options['raise'].el.style.display = 'block'
						this.options['raise'].el.innerHTML = 'Raise (' + actions['raise'] + '+)'
						this.actionValues['raise'] = actions['raise']
					} else {
						this.options['raise'].el.style.display = 'none'
					}

					if (actions['fold'] !== undefined) {
						this.options['fold'].el.style.display = 'block'
						this.options['fold'].el.innerHTML = 'Fold (' + actions['fold'] + ')'
						this.actionValues['fold'] = 0
					} else {
						this.options['fold'].el.style.display = 'none'
					}
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
