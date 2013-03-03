$(document).ready(function() {
  function importCheckIns(markerLayer, checkins) {
    for (var i=0; i < checkins.length; i++) {
      var checkin = checkins[i];
      var description = checkin.place.location.city + ', ' + checkin.place.location.country;
      var feature = {
        geometry: {
          coordinates: [checkin.coordinates.longitude, checkin.coordinates.latitude]
        },
        properties: {
          'marker-color': '#000',
          'marker-symbol': 'star-stroked',
          title: checkin.place.name,
          description: description
        }
      }
      markerLayer.add_feature(feature);
    }
  }

  var map = mapbox.map('map');
  map.addLayer(mapbox.layer().id('examples.map-20v6611k'));

  // Create an empty markers layer
  var markerLayer = mapbox.markers.layer();

  // Add interaction to this marker layer. This
  // binds tooltips to each marker that has title
  // and description defined.
  mapbox.markers.interaction(markerLayer);
  map.addLayer(markerLayer);

  map.zoom(5).center({ lat: 37, lon: -77 });

  importCheckIns(markerLayer, CHECK_INS['wei'].checkins.data);

  // Attribute map
  map.ui.attribution.add()
      .content('<a href="http://mapbox.com/about/maps">Terms &amp; Feedback</a>');
});