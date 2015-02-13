
	(function() {
		// classes
		var classes = {
			menu : {
				options: [],
				callback: function() {},
				constructor: function() {
					this.el = ce('div', { id: 'menu' })
					var os = ['check','call','fold','bet','raise']
					for (var i = 0; i < os.length; ++i) {
						var o = new BC.menuOption(os[i], false, this.menuOptionCallback.bind(this))
						this.options.push(o)
						ac(this.el, o.el)
					}
				},
				menuOptionCallback: function(action) {
					this.callback(action)
				},
				show: function(callback) {
					this.callback = callback
					this.el.style.bottom = 0
				},
				hide: function() {
					this.el.style.bottom = -this.el.clientHeight
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
