$(document).ready(function() {
  function importCheckIns(markerLayer, checkins, userId) {
    for (var i=0; i < checkins.length; i++) {
      var checkin = checkins[i];
      var description = checkin.place.location.city + ', ' + checkin.place.location.country;
      var feature = {
        geometry: {
          coordinates: [checkin.coordinates.longitude, checkin.coordinates.latitude]
        },
        properties: {
          //'marker-color': '#000',
          //'marker-symbol': 'star-stroked',
          'user-id': userId,
          'image': 'https://graph.facebook.com/'+userId+'/picture',
          title: checkin.place.name,
          description: description
        }
      }
      markerLayer.add_feature(feature);
    }
  }

  var map = mapbox.map('map');
  map.addLayer(mapbox.layer().id('chawei.map-85tzbb2w'));

  // Create an empty markers layer
  var markerLayer = mapbox.markers.layer();

  // Add interaction to this marker layer. This
  // binds tooltips to each marker that has title
  // and description defined.
  mapbox.markers.interaction(markerLayer);
  map.addLayer(markerLayer);

  map.zoom(10).center({ lat: 37.626, lon: -122.397 });

  importCheckIns(markerLayer, CHECK_INS['david'].checkins.data, CHECK_INS['david'].checkins.id);
  importCheckIns(markerLayer, CHECK_INS['jackie'].checkins.data, CHECK_INS['jackie'].checkins.id);
  
  $('.filter').click(function(){
    $('.filter').removeClass('active');
    $(this).addClass('active');
    var userId = $(this).attr('user-id');
    
    markerLayer.filter(function(f) {
      return f.properties['user-id'] === userId;
    });
    return false;
  });
        
  markerLayer.factory(function(f) {
      // Define a new factory function. This takes a GeoJSON object
      // as its input and returns an element - in this case an image -
      // that represents the point.
          var img = document.createElement('img');
          img.className = 'marker-image';
          img.setAttribute('src', f.properties.image);
          return img;
      });
  
  map.ui.zoomer.add();
  map.ui.zoombox.add();
  
  // Attribute map
  map.ui.attribution.add()
      .content('<a href="http://mapbox.com/about/maps">Terms &amp; Feedback</a>');
});