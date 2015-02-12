
	(function() {
		// utils
		var BC = {}

		ce = function(tag, props) {
			var e = document.createElement(tag)
			if (props) for (var p in props) e[p] = props[p]
			return e
		}
		ac = function(par, el) {
			par.appendChild(el)
		}
		ic = function(par, el, index) {
			par.insertBefore(el, par.childNodes[index])
		}
		rc = function(par, el) {
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
			player : '',
			hand : '',
			table : '',
			pot : '',
			button: '',
			menu : ''
		}

		BC.mapToObj = function(container, name, map) {
			var cons = map['constructor']
			container[name] = cons ? cons : function() {}

			for (var prop in map) {
				container[name].prototype[prop] = map[prop]
			}
		}

		window.BC = BC

		// for (var className in classes) {
		// 	mapToObj(window.BC, className, classes[className])
		// }
	})()
