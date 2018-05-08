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
var tourStops=[1,2,3,4,5]
var toggleableLayerIds = ['transit','census','housing','schools'];
var currentTourStop = null;

/* =====================
  Functionality
===================== */

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
  if(window.location.search.indexOf('embed') !== -1) map.scrollZoom.disable();
  setupUI();

  map.addLayer({
    id: 'transit',
    type: 'fill',
    'source': {
      type: 'vector',
      url: 'mapbox://amsr.cjgx25ja001pb8kp7t01zr41e-68cjm'
    },
    'source-layer': 'transitPoly',
    paint: {
      'fill-color': '#8c8081',
      'fill-opacity': 0.5,
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
      'fill-color': [
        'match',
        ['get', 'lowPov'],
        'No', '#F03400',
        'Yes', '#758540',
        '#ccc'
      ],
      'fill-opacity': 0.2,
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
        e.features[0].properties.lowPov +
        "<p></p><br><em class='popup-body'>Homeownership Rate: </em>" +
        e.features[0].properties.homPct + "%" +
        "<br><em class='popup-body'>Above Phila Avg? +</em>" +
        e.features[0].properties.ownerOcc +
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
    id: 'housing',
    type: 'circle',
    source: {
      type: 'vector',
      url: 'mapbox://amsr.cjgx11tqx021ilco7divskbob-5i5r8'
    },
    'source-layer': 'affHsgPoints',
    paint: {
      'circle-radius': [
        'interpolate',
        ['linear'],
        ['get', 'totalUnits'],
        4,
        4,
        728,
        18
      ],
      'circle-opacity': 0.6,
      'circle-color': '#d9a60f',
      'circle-stroke-color': '#000000',
      'circle-stroke-width': 0.5
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
      'circle-radius': [
        'interpolate',
        ['linear'],
        ['get', 'BLAS'],
        30,
        4,
        100,
        18
      ],
      'circle-opacity': 0.6,
      'circle-color': '#451515',
      'circle-stroke-color': '#000000',
      'circle-stroke-width': 0.5
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

// Create layer toggles
for (var i = 0; i < toggleableLayerIds.length; i++) {
    var id = toggleableLayerIds[i];

    var link = document.createElement('a');
    link.href = '#';
    link.className = 'active';
    link.textContent = id;

    link.onclick = function (e) {
        var clickedLayer = this.textContent;
        e.preventDefault();
        e.stopPropagation();

        var visibility = map.getLayoutProperty(clickedLayer, 'visibility');

        if (visibility === 'visible') {
            map.setLayoutProperty(clickedLayer, 'visibility', 'none');
            this.className = '';
        } else {
            this.className = 'active';
            map.setLayoutProperty(clickedLayer, 'visibility', 'visible');
        }
    };

    var layers = document.getElementById('menu');
    layers.appendChild(link);
}

// Create scrolly dude
function setupUI() {
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

  $(".button.playback.speed").on("click",function() {
    speed = $(ev.target).data("speed");
  });
}

var geocoder = new MapboxGeocoder({
   accessToken: mapboxgl.accessToken
 });

 map.addControl(geocoder);

 map.addSource('single-point', {
     "type": "geojson",
     "data": {
       "type": "FeatureCollection",
       "features": []
     }
   });

   map.addLayer({
     "id": "point",
     "source": "single-point",
     "type": "circle",
     "paint": {
       "circle-radius": 10,
       "circle-color": "#007cbf"
     }
  });

  geocoder.on('result', function(ev) {
    map.getSource('single-point').setData(ev.result.geometry);
  });
