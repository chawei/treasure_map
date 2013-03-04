var currentUser = null;
var friends  = {};
var allUsers = {};

var App = function() {
  this.Config = {
    FirebaseURL : "https://steampunk.firebaseIO.com",
  };
  
  this.Map         = null;
  this.MarkerLayer = null;
  
  //this.currentUser = null;
};

App.prototype = {
  init: function(currentUserId) {
    var that = this;
    this.Config.usersRef       = new Firebase(App.Config.FirebaseURL + '/users');
    this.Config.currentUserRef = new Firebase(App.Config.FirebaseURL + '/users' + '/' + currentUserId);
    this.Config.currentUserRef.once('value', function(snapshot) {
      currentUser = snapshot.val();
      that.renderUI(currentUserId);
      that.renderFriends(currentUserId);
      that.renderMap();
      that.fetchAndRenderBookmarks(currentUserId);
      //that.renderBookmarks(currentUser.bookmarks);
    });
    
    this.Config.bookmarksRef = new Firebase(App.Config.FirebaseURL + '/users/' + currentUserId + '/bookmarks');
  },
  
  renderFriends : function(currentUserId) {
    var that = this;
    this.Config.usersRef.once('value', function(snapshot) {
      var users = snapshot.val();
      window.allUsers = users;
      $('#friend_filter ').empty();
      for (userId in users) {
        var user = users[userId];
        if (user.fb_info.id != currentUserId.toString()) {
          console.log('add user: '+ user.fb_info.name);
          friends[user.fb_info.id] = user;
          $('#friend_filter ').append("<li><a href='#' class='filter active' user-id='"+user.fb_info.id+"'>"+user.fb_info.name+"</a></li>");
          that.importCheckIns(user.checkins, user.fb_info.id);
        }
      }
    });
  },
  
  renderUI : function(currentUserId) {
    $('#map-ui').removeClass('hidden');
    $('#me_btn').attr('user-id', currentUserId);
    
    var that = this;
    $(document).on("click", '.marker-title .save_btn', function(){
      var markerTooltip = $(this).parents('.marker-tooltip');
      var markerTitle   = markerTooltip.find('.marker-title');
      var userId        = markerTitle.attr('user-id');
      var checkinId     = markerTitle.attr('checkin-id');
      console.log('Saving '+markerTitle.text());
      console.log(checkinId);
      
      var checkin        = that.findCheckin(userId, checkinId);
      var checkinId      = parseFloat(checkinId);
      var bookmarksRef   = new Firebase("https://steampunk.firebaseIO.com/users/"+currentUserId+"/bookmarks");
      var bookmarksQuery = bookmarksRef.startAt(checkinId).endAt(checkinId);
      bookmarksQuery.once('value', function(snapshot) {
        if (snapshot.val() === null) {
          var newBookmarkRef = App.Config.bookmarksRef.push();
          newBookmarkRef.setWithPriority({origin: {id: userId}, checkin: checkin}, checkinId);
          console.log('treasure saved');
          $(".marker-image[checkin-id="+checkinId.toString()+"]").addClass('bookmarked');
        }
      });
      return false;
    });
  },
  
  removeBookmark : function(bookmarkId, checkinId) {
    var currentUserId = currentUser.fb_info.id;
    var bookmarkRef   = new Firebase("https://steampunk.firebaseIO.com/users/"+currentUserId+"/bookmarks/"+bookmarkId);
    bookmarkRef.remove();
    $(".marker-image[checkin-id="+checkinId.toString()+"]").removeClass('bookmarked');
  },
  
  fetchAndRenderBookmarks : function(userId) {
    var that = this;
    var bookmarksRef = new Firebase("https://steampunk.firebaseIO.com/users/"+userId+"/bookmarks");
    var bookmarksQuery = bookmarksRef.limit(10);
    bookmarksQuery.on('value', function(snapshot) {
      var bookmarks = snapshot.val();
      that.renderBookmarks(bookmarks);
    });
  },
  
  renderBookmarks : function(bookmarks) {
    var bookmarksElem = $('#bookmarks');
    bookmarksElem.empty();
    for (bookmarkId in bookmarks) {
      var bookmark = bookmarks[bookmarkId];
      var checkin  = bookmark.checkin;
      bookmarksElem.prepend(['<div class="bookmark cf" checkin-id="', checkin.id, '" bookmark-id="', bookmarkId, '">', 
                                '<img class="shared_by" src="', 
                                  'https://graph.facebook.com/', bookmark.origin.id, '/picture', '" />',
                                '<div class="name">', checkin.place.name, '</div>',
                                '<a class="remove_btn" href="#">remove</a></div>'].join('')
                            );
      $(".marker-image[checkin-id="+checkin.id.toString()+"]").addClass('bookmarked');
    }
    
    var that = this;
    $('.remove_btn').click(function(e){
      e.preventDefault();
      
      var btn          = $(this);
      var bookmarkElem = btn.parents('.bookmark');
      var bookmarkId   = bookmarkElem.attr('bookmark-id');
      var checkinId    = bookmarkElem.attr('checkin-id');
      that.removeBookmark(bookmarkId, checkinId);
      bookmarkElem.remove();
    });
  },
  
  findCheckin : function(userId, checkinId) {
    var targetCheckin = null;
    var user = allUsers[userId];
    $.each(user.checkins, function(index, checkin) {
      if (checkin.id === checkinId.toString()) {
        targetCheckin = checkin;
        return false;
      }
    });
    return targetCheckin;
  },
  
  renderMap : function() {
    var map = mapbox.map('map');
    map.addLayer(mapbox.layer().id('chawei.map-85tzbb2w'));
    
    this.MarkerLayer = mapbox.markers.layer();
    var markerLayer    = this.MarkerLayer;
    var interaction = mapbox.markers.interaction(markerLayer);
    map.addLayer(markerLayer);
    
    interaction.formatter(function(feature) {
      var o = ['<div class="marker-title" user-id="', feature.properties["user-id"], '" checkin-id="', feature.properties["checkin-id"], '">',
                  feature.properties.title,
                  '<a class="save_btn" href="#">save</a>',
                '</div>',
                '<div class="marker-description">',
                  feature.properties.description,
                '</div>'].join('');
      return o;
    });

    map.zoom(10).center({ lat: 37.626, lon: -122.397 });
    
    this.importCheckIns(currentUser.checkins, currentUser.fb_info.id);
    this.initFilterEvents();

    markerLayer.factory(function(f) {
        // Define a new factory function. This takes a GeoJSON object
        // as its input and returns an element - in this case an image -
        // that represents the point.
            var img = document.createElement('img');
            img.className = 'marker-image';
            img.setAttribute('src', f.properties.image);
            img.setAttribute('checkin-id', f.properties["checkin-id"]);
            return img;
        });

    map.ui.zoomer.add();
    map.ui.zoombox.add();

    // Attribute map
    map.ui.attribution.add()
        .content('<a href="http://mapbox.com/about/maps">Terms &amp; Feedback</a>');
  },
  
  initFilterEvents : function() {
    var that = this;
    $(document).on('click', '.filter', function(e){
      e.preventDefault();
      
      var thisElem = $(this);
      var userId   = thisElem.attr('user-id');
      if (thisElem.hasClass('active')) {
        thisElem.removeClass('active');
      } else {
        thisElem.addClass('active');
      } 

      var activeUserIds = [];
      $.each($('#map-ui .active'), function(index, item) {
        activeUserIds.push($(item).attr('user-id'));
      });
      that.MarkerLayer.filter(function(f) {
        return ($.inArray(f.properties['user-id'], activeUserIds) !== -1);
      });
    });
  },
  
  importCheckIns : function(checkins, userId) {
    var markerLayer = this.MarkerLayer;
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
          'checkin-id': checkin.id,
          title: checkin.place.name,
          description: description
        }
      }
      markerLayer.add_feature(feature);
    }
  },
  
  refreshCheckins : function() {
    
  }
};

var App = new App();

var User = function(user) {
  this.facebookId = user.id;
  this.fullName   = user.name;
  this.firstName  = user.first_name;
  this.fbInfo     = user;
  this.checkins   = null;
};

$(document).ready(function() {
  /*
  window.authClient = new FirebaseAuthClient(rootRef, function(error, user) {
    if (error) {
      // an error occurred while attempting login
      console.log(error);
    } else if (user) {
      // user authenticated with Firebase
      console.log('User ID: ' + user.id + ', Provider: ' + user.provider);
      
    } else {
      // user is logged out
    }
  });
  */
  
  $('#fb_login').click(function(){
    FB.login(function(response) {
      if (response.authResponse) {
        console.log('Welcome!  Fetching your information.... ');
        FB.api('/me', function(response) {
          console.log('Good to see you, ' + response.name + '.');
          console.log(response);
          currentUser = new User(response);
          var currentUserRef = App.Config.usersRef.child(currentUser.facebookId);
          currentUserRef.child('fb_info').set(response);
       
          FB.api('/me/checkins?fields=from,message,place,coordinates,created_time&limit=30', function(response) {
            currentUser.checkins = response.data;
            currentUserRef.child('checkins').set(currentUser.checkins);
          });
        });
      } else {
        console.log('User cancelled login or did not fully authorize.');
      }
    }, {scope: 'email,user_status'});
    
    return false;
  });

});