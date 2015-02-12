
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
		var hand = {
			constructor: function() {
				//
			}
		}

		BC.mapToObj(window.BC, 'hand', hand)
	})()
