/* ========================================================================
 * Bootstrap: transition.js v3.3.7
 * http://getbootstrap.com/javascript/#transitions
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */
+ function($) {
	'use strict';
	// CSS TRANSITION SUPPORT (Shoutout: http://www.modernizr.com/)
	// ============================================================
	function transitionEnd() {
		var el = document.createElement('bootstrap')
		var transEndEventNames = {
			WebkitTransition: 'webkitTransitionEnd',
			MozTransition: 'transitionend',
			OTransition: 'oTransitionEnd otransitionend',
			transition: 'transitionend'
		}
		for (var name in transEndEventNames) {
			if (el.style[name] !== undefined) {
				return {
					end: transEndEventNames[name]
				}
			}
		}
		return false // explicit for ie8 (  ._.)
	}
	// http://blog.alexmaccaw.com/css-transitions
	$.fn.emulateTransitionEnd = function(duration) {
		var called = false
		var $el = this
		$(this).one('bsTransitionEnd', function() {
			called = true
		})
		var callback = function() {
			if (!called) $($el).trigger($.support.transition.end)
		}
		setTimeout(callback, duration)
		return this
	}
	$(function() {
		$.support.transition = transitionEnd()
		if (!$.support.transition) return
		$.event.special.bsTransitionEnd = {
			bindType: $.support.transition.end,
			delegateType: $.support.transition.end,
			handle: function(e) {
				if ($(e.target).is(this)) return e.handleObj.handler.apply(this, arguments)
			}
		}
	})
}(jQuery);
/* ========================================================================
 * Bootstrap: dropdown.js v3.3.7
 * http://getbootstrap.com/javascript/#dropdowns
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */
+ function($) {
	'use strict';
	// DROPDOWN CLASS DEFINITION
	// =========================
	var backdrop = '.dropdown-backdrop'
	var toggle = '[data-toggle="dropdown"]'
	var Dropdown = function(element) {
		$(element).on('click.bs.dropdown', this.toggle)
	}
	Dropdown.VERSION = '3.3.7'

	function getParent($this) {
		var selector = $this.attr('data-target')
		if (!selector) {
			selector = $this.attr('href')
			selector = selector && /#[A-Za-z]/.test(selector) && selector.replace(/.*(?=#[^\s]*$)/, '') // strip for ie7
		}
		var $parent = selector && $(selector)
		return $parent && $parent.length ? $parent : $this.parent()
	}

	function clearMenus(e) {
		if (e && e.which === 3) return
		$(backdrop).remove()
		$(toggle).each(function() {
			var $this = $(this)
			var $parent = getParent($this)
			var relatedTarget = {
				relatedTarget: this
			}
			if (!$parent.hasClass('open')) return
			if (e && e.type == 'click' && /input|textarea/i.test(e.target.tagName) && $.contains($parent[0], e.target)) return
			$parent.trigger(e = $.Event('hide.bs.dropdown', relatedTarget))
			if (e.isDefaultPrevented()) return
			$this.attr('aria-expanded', 'false')
			$parent.removeClass('open').trigger($.Event('hidden.bs.dropdown', relatedTarget))
		})
	}
	Dropdown.prototype.toggle = function(e) {
		var $this = $(this)
		if ($this.is('.disabled, :disabled')) return
		var $parent = getParent($this)
		var isActive = $parent.hasClass('open')
		clearMenus()
		if (!isActive) {
			if ('ontouchstart' in document.documentElement && !$parent.closest('.navbar-nav').length) {
				// if mobile we use a backdrop because click events don't delegate
				$(document.createElement('div')).addClass('dropdown-backdrop').insertAfter($(this)).on('click', clearMenus)
			}
			var relatedTarget = {
				relatedTarget: this
			}
			$parent.trigger(e = $.Event('show.bs.dropdown', relatedTarget))
			if (e.isDefaultPrevented()) return
			$this.trigger('focus').attr('aria-expanded', 'true')
			$parent.toggleClass('open').trigger($.Event('shown.bs.dropdown', relatedTarget))
		}
		return false
	}
	Dropdown.prototype.keydown = function(e) {
			if (!/(38|40|27|32)/.test(e.which) || /input|textarea/i.test(e.target.tagName)) return
			var $this = $(this)
			e.preventDefault()
			e.stopPropagation()
			if ($this.is('.disabled, :disabled')) return
			var $parent = getParent($this)
			var isActive = $parent.hasClass('open')
			if (!isActive && e.which != 27 || isActive && e.which == 27) {
				if (e.which == 27) $parent.find(toggle).trigger('focus')
				return $this.trigger('click')
			}
			var desc = ' li:not(.disabled):visible a'
			var $items = $parent.find('.dropdown-menu' + desc)
			if (!$items.length) return
			var index = $items.index(e.target)
			if (e.which == 38 && index > 0) index-- // up
				if (e.which == 40 && index < $items.length - 1) index++ // down
					if (!~index) index = 0
			$items.eq(index).trigger('focus')
		}
		// DROPDOWN PLUGIN DEFINITION
		// ==========================
	function Plugin(option) {
		return this.each(function() {
			var $this = $(this)
			var data = $this.data('bs.dropdown')
			if (!data) $this.data('bs.dropdown', (data = new Dropdown(this)))
			if (typeof option == 'string') data[option].call($this)
		})
	}
	var old = $.fn.dropdown
	$.fn.dropdown = Plugin
	$.fn.dropdown.Constructor = Dropdown
		// DROPDOWN NO CONFLICT
		// ====================
	$.fn.dropdown.noConflict = function() {
			$.fn.dropdown = old
			return this
		}
		// APPLY TO STANDARD DROPDOWN ELEMENTS
		// ===================================
	$(document).on('click.bs.dropdown.data-api', clearMenus).on('click.bs.dropdown.data-api', '.dropdown form', function(e) {
		e.stopPropagation()
	}).on('click.bs.dropdown.data-api', toggle, Dropdown.prototype.toggle).on('keydown.bs.dropdown.data-api', toggle, Dropdown.prototype.keydown).on('keydown.bs.dropdown.data-api', '.dropdown-menu', Dropdown.prototype.keydown)
}(jQuery);
/* ========================================================================
 * Bootstrap: tab.js v3.3.7
 * http://getbootstrap.com/javascript/#tabs
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */
+ function($) {
	'use strict';
	// TAB CLASS DEFINITION
	// ====================
	var Tab = function(element) {
		// jscs:disable requireDollarBeforejQueryAssignment
		this.element = $(element)
			// jscs:enable requireDollarBeforejQueryAssignment
	}
	Tab.VERSION = '3.3.7'
	Tab.TRANSITION_DURATION = 150
	Tab.prototype.show = function() {
		var $this = this.element
		var $ul = $this.closest('ul:not(.dropdown-menu)')
		var selector = $this.data('target')
		if (!selector) {
			selector = $this.attr('href')
			selector = selector && selector.replace(/.*(?=#[^\s]*$)/, '') // strip for ie7
		}
		if ($this.parent('li').hasClass('active')) return
		var $previous = $ul.find('.active:last a')
		var hideEvent = $.Event('hide.bs.tab', {
			relatedTarget: $this[0]
		})
		var showEvent = $.Event('show.bs.tab', {
			relatedTarget: $previous[0]
		})
		$previous.trigger(hideEvent)
		$this.trigger(showEvent)
		if (showEvent.isDefaultPrevented() || hideEvent.isDefaultPrevented()) return
		var $target = $(selector)
		this.activate($this.closest('li'), $ul)
		this.activate($target, $target.parent(), function() {
			$previous.trigger({
				type: 'hidden.bs.tab',
				relatedTarget: $this[0]
			})
			$this.trigger({
				type: 'shown.bs.tab',
				relatedTarget: $previous[0]
			})
		})
	}
	Tab.prototype.activate = function(element, container, callback) {
			var $active = container.find('> .active')
			var transition = callback && $.support.transition && ($active.length && $active.hasClass('fade') || !!container.find('> .fade').length)

			function next() {
				$active.removeClass('active').find('> .dropdown-menu > .active').removeClass('active').end().find('[data-toggle="tab"]').attr('aria-expanded', false)
				element.addClass('active').find('[data-toggle="tab"]').attr('aria-expanded', true)
				if (transition) {
					element[0].offsetWidth // reflow for transition
					element.addClass('in')
				} else {
					element.removeClass('fade')
				}
				if (element.parent('.dropdown-menu').length) {
					element.closest('li.dropdown').addClass('active').end().find('[data-toggle="tab"]').attr('aria-expanded', true)
				}
				callback && callback()
			}
			$active.length && transition ? $active.one('bsTransitionEnd', next).emulateTransitionEnd(Tab.TRANSITION_DURATION) : next()
			$active.removeClass('in')
		}
		// TAB PLUGIN DEFINITION
		// =====================
	function Plugin(option) {
		return this.each(function() {
			var $this = $(this)
			var data = $this.data('bs.tab')
			if (!data) $this.data('bs.tab', (data = new Tab(this)))
			if (typeof option == 'string') data[option]()
		})
	}
	var old = $.fn.tab
	$.fn.tab = Plugin
	$.fn.tab.Constructor = Tab
		// TAB NO CONFLICT
		// ===============
	$.fn.tab.noConflict = function() {
			$.fn.tab = old
			return this
		}
		// TAB DATA-API
		// ============
	var clickHandler = function(e) {
		e.preventDefault()
		Plugin.call($(this), 'show')
	}
	$(document).on('click.bs.tab.data-api', '[data-toggle="tab"]', clickHandler).on('click.bs.tab.data-api', '[data-toggle="pill"]', clickHandler)
}(jQuery);
/*!
 * imagesLoaded PACKAGED v4.1.3
 * JavaScript is all like "You images are done yet or what?"
 * MIT License
 */

/**
 * EvEmitter v1.1.0
 * Lil' event emitter
 * MIT License
 */

/* jshint unused: true, undef: true, strict: true */

( function( global, factory ) {
  // universal module definition
  /* jshint strict: false */ /* globals define, module, window */
  if ( typeof define == 'function' && define.amd ) {
    // AMD - RequireJS
    define( 'ev-emitter/ev-emitter',factory );
  } else if ( typeof module == 'object' && module.exports ) {
    // CommonJS - Browserify, Webpack
    module.exports = factory();
  } else {
    // Browser globals
    global.EvEmitter = factory();
  }

}( typeof window != 'undefined' ? window : this, function() {



function EvEmitter() {}

var proto = EvEmitter.prototype;

proto.on = function( eventName, listener ) {
  if ( !eventName || !listener ) {
    return;
  }
  // set events hash
  var events = this._events = this._events || {};
  // set listeners array
  var listeners = events[ eventName ] = events[ eventName ] || [];
  // only add once
  if ( listeners.indexOf( listener ) == -1 ) {
    listeners.push( listener );
  }

  return this;
};

proto.once = function( eventName, listener ) {
  if ( !eventName || !listener ) {
    return;
  }
  // add event
  this.on( eventName, listener );
  // set once flag
  // set onceEvents hash
  var onceEvents = this._onceEvents = this._onceEvents || {};
  // set onceListeners object
  var onceListeners = onceEvents[ eventName ] = onceEvents[ eventName ] || {};
  // set flag
  onceListeners[ listener ] = true;

  return this;
};

proto.off = function( eventName, listener ) {
  var listeners = this._events && this._events[ eventName ];
  if ( !listeners || !listeners.length ) {
    return;
  }
  var index = listeners.indexOf( listener );
  if ( index != -1 ) {
    listeners.splice( index, 1 );
  }

  return this;
};

proto.emitEvent = function( eventName, args ) {
  var listeners = this._events && this._events[ eventName ];
  if ( !listeners || !listeners.length ) {
    return;
  }
  var i = 0;
  var listener = listeners[i];
  args = args || [];
  // once stuff
  var onceListeners = this._onceEvents && this._onceEvents[ eventName ];

  while ( listener ) {
    var isOnce = onceListeners && onceListeners[ listener ];
    if ( isOnce ) {
      // remove listener
      // remove before trigger to prevent recursion
      this.off( eventName, listener );
      // unset once flag
      delete onceListeners[ listener ];
    }
    // trigger listener
    listener.apply( this, args );
    // get next listener
    i += isOnce ? 0 : 1;
    listener = listeners[i];
  }

  return this;
};

proto.allOff =
proto.removeAllListeners = function() {
  delete this._events;
  delete this._onceEvents;
};

return EvEmitter;

}));

/*!
 * imagesLoaded v4.1.3
 * JavaScript is all like "You images are done yet or what?"
 * MIT License
 */

( function( window, factory ) { 'use strict';
  // universal module definition

  /*global define: false, module: false, require: false */

  if ( typeof define == 'function' && define.amd ) {
    // AMD
    define( [
      'ev-emitter/ev-emitter'
    ], function( EvEmitter ) {
      return factory( window, EvEmitter );
    });
  } else if ( typeof module == 'object' && module.exports ) {
    // CommonJS
    module.exports = factory(
      window,
      require('ev-emitter')
    );
  } else {
    // browser global
    window.imagesLoaded = factory(
      window,
      window.EvEmitter
    );
  }

})( typeof window !== 'undefined' ? window : this,

// --------------------------  factory -------------------------- //

function factory( window, EvEmitter ) {



var $ = window.jQuery;
var console = window.console;

// -------------------------- helpers -------------------------- //

// extend objects
function extend( a, b ) {
  for ( var prop in b ) {
    a[ prop ] = b[ prop ];
  }
  return a;
}

// turn element or nodeList into an array
function makeArray( obj ) {
  var ary = [];
  if ( Array.isArray( obj ) ) {
    // use object if already an array
    ary = obj;
  } else if ( typeof obj.length == 'number' ) {
    // convert nodeList to array
    for ( var i=0; i < obj.length; i++ ) {
      ary.push( obj[i] );
    }
  } else {
    // array of single index
    ary.push( obj );
  }
  return ary;
}

// -------------------------- imagesLoaded -------------------------- //

/**
 * @param {Array, Element, NodeList, String} elem
 * @param {Object or Function} options - if function, use as callback
 * @param {Function} onAlways - callback function
 */
function ImagesLoaded( elem, options, onAlways ) {
  // coerce ImagesLoaded() without new, to be new ImagesLoaded()
  if ( !( this instanceof ImagesLoaded ) ) {
    return new ImagesLoaded( elem, options, onAlways );
  }
  // use elem as selector string
  if ( typeof elem == 'string' ) {
    elem = document.querySelectorAll( elem );
  }

  this.elements = makeArray( elem );
  this.options = extend( {}, this.options );

  if ( typeof options == 'function' ) {
    onAlways = options;
  } else {
    extend( this.options, options );
  }

  if ( onAlways ) {
    this.on( 'always', onAlways );
  }

  this.getImages();

  if ( $ ) {
    // add jQuery Deferred object
    this.jqDeferred = new $.Deferred();
  }

  // HACK check async to allow time to bind listeners
  setTimeout( function() {
    this.check();
  }.bind( this ));
}

ImagesLoaded.prototype = Object.create( EvEmitter.prototype );

ImagesLoaded.prototype.options = {};

ImagesLoaded.prototype.getImages = function() {
  this.images = [];

  // filter & find items if we have an item selector
  this.elements.forEach( this.addElementImages, this );
};

/**
 * @param {Node} element
 */
ImagesLoaded.prototype.addElementImages = function( elem ) {
  // filter siblings
  if ( elem.nodeName == 'IMG' ) {
    this.addImage( elem );
  }
  // get background image on element
  if ( this.options.background === true ) {
    this.addElementBackgroundImages( elem );
  }

  // find children
  // no non-element nodes, #143
  var nodeType = elem.nodeType;
  if ( !nodeType || !elementNodeTypes[ nodeType ] ) {
    return;
  }
  var childImgs = elem.querySelectorAll('img');
  // concat childElems to filterFound array
  for ( var i=0; i < childImgs.length; i++ ) {
    var img = childImgs[i];
    this.addImage( img );
  }

  // get child background images
  if ( typeof this.options.background == 'string' ) {
    var children = elem.querySelectorAll( this.options.background );
    for ( i=0; i < children.length; i++ ) {
      var child = children[i];
      this.addElementBackgroundImages( child );
    }
  }
};

var elementNodeTypes = {
  1: true,
  9: true,
  11: true
};

ImagesLoaded.prototype.addElementBackgroundImages = function( elem ) {
  var style = getComputedStyle( elem );
  if ( !style ) {
    // Firefox returns null if in a hidden iframe https://bugzil.la/548397
    return;
  }
  // get url inside url("...")
  var reURL = /url\((['"])?(.*?)\1\)/gi;
  var matches = reURL.exec( style.backgroundImage );
  while ( matches !== null ) {
    var url = matches && matches[2];
    if ( url ) {
      this.addBackground( url, elem );
    }
    matches = reURL.exec( style.backgroundImage );
  }
};

/**
 * @param {Image} img
 */
ImagesLoaded.prototype.addImage = function( img ) {
  var loadingImage = new LoadingImage( img );
  this.images.push( loadingImage );
};

ImagesLoaded.prototype.addBackground = function( url, elem ) {
  var background = new Background( url, elem );
  this.images.push( background );
};

ImagesLoaded.prototype.check = function() {
  var _this = this;
  this.progressedCount = 0;
  this.hasAnyBroken = false;
  // complete if no images
  if ( !this.images.length ) {
    this.complete();
    return;
  }

  function onProgress( image, elem, message ) {
    // HACK - Chrome triggers event before object properties have changed. #83
    setTimeout( function() {
      _this.progress( image, elem, message );
    });
  }

  this.images.forEach( function( loadingImage ) {
    loadingImage.once( 'progress', onProgress );
    loadingImage.check();
  });
};

ImagesLoaded.prototype.progress = function( image, elem, message ) {
  this.progressedCount++;
  this.hasAnyBroken = this.hasAnyBroken || !image.isLoaded;
  // progress event
  this.emitEvent( 'progress', [ this, image, elem ] );
  if ( this.jqDeferred && this.jqDeferred.notify ) {
    this.jqDeferred.notify( this, image );
  }
  // check if completed
  if ( this.progressedCount == this.images.length ) {
    this.complete();
  }

  if ( this.options.debug && console ) {
    console.log( 'progress: ' + message, image, elem );
  }
};

ImagesLoaded.prototype.complete = function() {
  var eventName = this.hasAnyBroken ? 'fail' : 'done';
  this.isComplete = true;
  this.emitEvent( eventName, [ this ] );
  this.emitEvent( 'always', [ this ] );
  if ( this.jqDeferred ) {
    var jqMethod = this.hasAnyBroken ? 'reject' : 'resolve';
    this.jqDeferred[ jqMethod ]( this );
  }
};

// --------------------------  -------------------------- //

function LoadingImage( img ) {
  this.img = img;
}

LoadingImage.prototype = Object.create( EvEmitter.prototype );

LoadingImage.prototype.check = function() {
  // If complete is true and browser supports natural sizes,
  // try to check for image status manually.
  var isComplete = this.getIsImageComplete();
  if ( isComplete ) {
    // report based on naturalWidth
    this.confirm( this.img.naturalWidth !== 0, 'naturalWidth' );
    return;
  }

  // If none of the checks above matched, simulate loading on detached element.
  this.proxyImage = new Image();
  this.proxyImage.addEventListener( 'load', this );
  this.proxyImage.addEventListener( 'error', this );
  // bind to image as well for Firefox. #191
  this.img.addEventListener( 'load', this );
  this.img.addEventListener( 'error', this );
  this.proxyImage.src = this.img.src;
};

LoadingImage.prototype.getIsImageComplete = function() {
  return this.img.complete && this.img.naturalWidth !== undefined;
};

LoadingImage.prototype.confirm = function( isLoaded, message ) {
  this.isLoaded = isLoaded;
  this.emitEvent( 'progress', [ this, this.img, message ] );
};

// ----- events ----- //

// trigger specified handler for event type
LoadingImage.prototype.handleEvent = function( event ) {
  var method = 'on' + event.type;
  if ( this[ method ] ) {
    this[ method ]( event );
  }
};

LoadingImage.prototype.onload = function() {
  this.confirm( true, 'onload' );
  this.unbindEvents();
};

LoadingImage.prototype.onerror = function() {
  this.confirm( false, 'onerror' );
  this.unbindEvents();
};

LoadingImage.prototype.unbindEvents = function() {
  this.proxyImage.removeEventListener( 'load', this );
  this.proxyImage.removeEventListener( 'error', this );
  this.img.removeEventListener( 'load', this );
  this.img.removeEventListener( 'error', this );
};

// -------------------------- Background -------------------------- //

function Background( url, element ) {
  this.url = url;
  this.element = element;
  this.img = new Image();
}

// inherit LoadingImage prototype
Background.prototype = Object.create( LoadingImage.prototype );

Background.prototype.check = function() {
  this.img.addEventListener( 'load', this );
  this.img.addEventListener( 'error', this );
  this.img.src = this.url;
  // check if image is already complete
  var isComplete = this.getIsImageComplete();
  if ( isComplete ) {
    this.confirm( this.img.naturalWidth !== 0, 'naturalWidth' );
    this.unbindEvents();
  }
};

Background.prototype.unbindEvents = function() {
  this.img.removeEventListener( 'load', this );
  this.img.removeEventListener( 'error', this );
};

Background.prototype.confirm = function( isLoaded, message ) {
  this.isLoaded = isLoaded;
  this.emitEvent( 'progress', [ this, this.element, message ] );
};

// -------------------------- jQuery -------------------------- //

ImagesLoaded.makeJQueryPlugin = function( jQuery ) {
  jQuery = jQuery || window.jQuery;
  if ( !jQuery ) {
    return;
  }
  // set local variable
  $ = jQuery;
  // $().imagesLoaded()
  $.fn.imagesLoaded = function( options, callback ) {
    var instance = new ImagesLoaded( this, options, callback );
    return instance.jqDeferred.promise( $(this) );
  };
};
// try making plugin
ImagesLoaded.makeJQueryPlugin();

// --------------------------  -------------------------- //

return ImagesLoaded;

});