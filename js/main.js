/* =====================
  Data
===================== */
var censusData = 'mapbox://amsr.cjgx2hey504fgmgn2rc4j5igw-0h4lv';

/* =====================
  Helper functions
===================== */
var parsedData;
var pointParsedData;
var featureGroup;
var theLimits;
var toggleableLayerIds = ['census'];
var currentSlide = null;

/* =====================
  Maps
===================== */

mapboxgl.accessToken = 'pk.eyJ1IjoiYW1zciIsImEiOiJjamY0Y2VtNTcwcmh0MzJsM2U0dGlvazNwIn0.n1yPJwVT5cTlvYsvMpfhFw';
var map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/light-v9',
    center: [-75.2,40],
    zoom: 10
});

map.on('load',function () {

  map.addLayer({
    id: 'transit',
    type: 'fill',
    'source': {
      type: 'vector',
      url: 'mapbox://amsr.cjgx25ja001pb8kp7t01zr41e-68cjm'
    },
    'source-layer': 'transitPoly',
    paint: {
      'fill-color': '#111111',
      'fill-outline-color': '#000000'
    }
  });

  map.addLayer({
    'id': 'census',
    'type': 'fill',
    'source': {
      type: 'vector',
      url: 'mapbox://amsr.cjgx2hey504fgmgn2rc4j5igw-0h4lv'
    },
    'source-layer': 'censusData',
    paint: {
      'fill-color': 'transparent',
      'fill-outline-color': '#000000'
    }
  });

  // Populate the popup and set its coordinates based on the feature found.
  map.on('click', 'census', function(e) {
    var url = e.features[0].properties.planURL;
    new mapboxgl.Popup()
      .setLngLat(e.lngLat)
      .setHTML(
        "<strong>" +
        e.features[0].properties.mapname + // nhood name
        "</strong><br><em class='popup-body'>Poverty Rate: </em>" +
        e.features[0].properties.povPct + "%" +
        "<br><em class='popup-body'>Below Phila Avg? +</em>" +
        e.features[0].properties.lowPov*3 +
        "<br><em class='popup-body'>Homeownership Rate: </em>" +
        e.features[0].properties.homPct + "%" +
        "<br><em class='popup-body'>Above Phila Avg? +</em>" +
        e.features[0].properties.ownerOcc*3 +
        "<br><em class='popup-body'>Community Plan </em>" +
        "<a href = '" + url  + "'> Link </a>"
      )
      .addTo(map);
  });
  map.on('mouseenter', 'census', function () {
      map.getCanvas().style.cursor = 'pointer';
  });
  // Change it back to a pointer when it leaves.
  map.on('mouseleave', 'census', function () {
      map.getCanvas().style.cursor = '';
  });

  map.addLayer( {
    'id': 'housing',
    'type': 'circle',
    'source': {
      type: 'vector',
      url: 'mapbox://amsr.cjgx11tqx021ilco7divskbob-5i5r8'
    },
    'source-layer': 'affHsgPoints',
    paint: {
    }
  });

  // Housing popup
  map.on('click', 'housing', function(e) {
    new mapboxgl.Popup()
      .setLngLat(e.lngLat)
      .setHTML(
        "<strong>" +
        e.features[0].properties.propName +
        "</strong><br><em class='popup-body'>Total Units: </em>" +
        e.features[0].properties.totalUnits +
        "<br><em class='popup-body'>Year Built: </em>" +
        e.features[0].properties.yrBuilt
      )
      .addTo(map);
  });

  map.addLayer( {
    'id': 'schools',
    'type': 'circle',
    'source': {
      type: 'vector',
      url: 'mapbox://amsr.cjgx14wbz01wclmo7ola0wpid-4mrzu'
    },
    'source-layer': 'schoolPoints',
    paint: {
    }
  });

  map.on('click', 'schools', function(e) {
    new mapboxgl.Popup()
      .setLngLat(e.lngLat)
      .setHTML(
        "<strong>" +
        e.features[0].properties.name_1 +
        "</strong><br><em class='popup-body'>Building-Level Academic Score: </em>" +
        e.features[0].properties.BLAS
      )
      .addTo(map);
  });
});

function setupUI() {
  for(var i=0; i<slides.length; i++) {
    var stop = slides[i];
    var stopEl = $("<div class = 'slide'></div>");
    stopEl.html("<h2 class='Slide-title'>" + stop["title"] + "</h2>");
    stopEl.data("stop",stop);

    stopEl.append(stop.description);

    if(window.location.search.indexOf('embed') == -1) {
      var nextEl = $("<p><div class = 'button'>Next -></div></p>");
      NextEl.on('click',advanceStop);
      stopEl.append(nextEl);
    }
    $("#narrative").append(stopEl);
  }

  $("#narrative").on("scroll", function() {
    var closestStop = null;
    var closestDistance = Number.MAX_VALUE;
    $("#narrative .slide").each(function(idx, el) {
      var dist = Math.abs($(el).offset().top);
      if(dist < closestDistance) {
        closestStop = $(el).data("stop");
        closestDistance = dist;
      }
    });
    if(closestStop != null) {
      showTourStop(closestStop);
    }
  });

  $(".button.playback.speed").on("click",function(ev) {
    speed= $(ev.target).data("speed");
    animationSettings.seconds_per_frame = speed;
  });
}
