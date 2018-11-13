// UI Maps
;(function($, window, document, undefined) {
	"use strict";
	// On Window Load
	$(window).on('load', function() {
		if ($('#gmap').length === 1) {
			initialize('gmap');
		}
	});
	// The Google Map 
	function initialize(obj) {
		// Custom JSON Style 
		var stylesArray = {
			'style-1': {
				'style': [{
					"featureType": "all",
					"elementType": "labels",
					"stylers": [{
						"lightness": "26"
					}]
				}, {
					"featureType": "all",
					"elementType": "labels.text",
					"stylers": [{
						"lightness": "77"
					}, {
						"visibility": "on"
					}]
				}, {
					"featureType": "all",
					"elementType": "labels.text.fill",
					"stylers": [{
						"saturation": 36
					}, {
						"color": "#878787"
					}, {
						"lightness": 40
					}]
				}, {
					"featureType": "all",
					"elementType": "labels.text.stroke",
					"stylers": [{
						"visibility": "on"
					}, {
						"color": "#ffffff"
					}, {
						"lightness": 16
					}]
				}, {
					"featureType": "all",
					"elementType": "labels.icon",
					"stylers": [{
						"visibility": "off"
					}]
				}, {
					"featureType": "administrative",
					"elementType": "geometry.fill",
					"stylers": [{
						"color": "#fefefe"
					}, {
						"lightness": 20
					}]
				}, {
					"featureType": "administrative",
					"elementType": "geometry.stroke",
					"stylers": [{
						"color": "#fefefe"
					}, {
						"lightness": 17
					}, {
						"weight": 1.2
					}]
				}, {
					"featureType": "landscape",
					"elementType": "geometry",
					"stylers": [{
						"color": "#f5f5f5"
					}, {
						"lightness": 20
					}]
				}, {
					"featureType": "poi",
					"elementType": "geometry",
					"stylers": [{
						"color": "#f5f5f5"
					}, {
						"lightness": 21
					}]
				}, {
					"featureType": "poi.park",
					"elementType": "geometry",
					"stylers": [{
						"color": "#dedede"
					}, {
						"lightness": 21
					}]
				}, {
					"featureType": "road.highway",
					"elementType": "geometry.fill",
					"stylers": [{
						"color": "#ffffff"
					}, {
						"lightness": 17
					}]
				}, {
					"featureType": "road.highway",
					"elementType": "geometry.stroke",
					"stylers": [{
						"color": "#ffffff"
					}, {
						"lightness": 29
					}, {
						"weight": 0.2
					}]
				}, {
					"featureType": "road.arterial",
					"elementType": "geometry",
					"stylers": [{
						"color": "#ffffff"
					}, {
						"lightness": 18
					}]
				}, {
					"featureType": "road.local",
					"elementType": "geometry",
					"stylers": [{
						"color": "#ffffff"
					}, {
						"lightness": 16
					}]
				}, {
					"featureType": "transit",
					"elementType": "geometry",
					"stylers": [{
						"color": "#f2f2f2"
					}, {
						"lightness": 19
					}]
				}, {
					"featureType": "water",
					"elementType": "geometry",
					"stylers": [{
						"color": "#e9e9e9"
					}, {
						"lightness": 17
					}]
				}]
			}
		};
		// Map, Marker, PopUpWindow
		var map, marker, infowindow;
		// Lat Long
		var lat = $('#' + obj).attr("data-lat");
		var lng = $('#' + obj).attr("data-lng");
		var myLatlng = new google.maps.LatLng(lat, lng);
		// Map Marker
		var image = {
			url: $('#' + obj).attr("data-marker"),
			scaledSize: new google.maps.Size(30, 30)
		};
		// Zoom
		var zoomLevel = parseInt($('#' + obj).attr("data-zoom"), 10);
		// The Style
		var styles = stylesArray[$('#gmap').attr("data-style")]['style'];
		var styledMap = new google.maps.StyledMapType(styles, {
			name: "Styled Map"
		});
		// Settings
		var mapOptions = {
			backgroundColor: '#FFFFFF',
			zoom: zoomLevel,
			disableDefaultUI: true,
			center: myLatlng,
			scrollwheel: false,
			draggable: !("ontouchend" in document),
			mapTypeControlOptions: {
				mapTypeIds: [google.maps.MapTypeId.ROADMAP, 'map_style']
			}
		};
		// Init
		map = new google.maps.Map(document.getElementById(obj), mapOptions);
		map.mapTypes.set('map_style', styledMap);
		map.setMapTypeId('map_style');
		marker = new google.maps.Marker({
			position: myLatlng,
			map: map,
			icon: image
		});
		// Open Info Window On Click
		google.maps.event.addListener(marker, 'click', function() {
			infowindow.open(map, marker);
		});
		// Keep Map Centered On Window Resize
		google.maps.event.addDomListener(window, 'resize', function() {
			map.setCenter(myLatlng);
		});
	}
})(jQuery, window, document);