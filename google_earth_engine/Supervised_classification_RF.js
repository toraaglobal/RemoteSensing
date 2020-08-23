//Code Link: https://code.earthengine.google.com/50a349a862786afbef11238ee1eef8f5

SUpervised LCassification with Random Forest 
var Dubai = 
    /* color: #d63000 */
    /* shown: false */
    /* displayProperties: [
      {
        "type": "rectangle"
      }
    ] */
    ee.Geometry.Polygon(
        [[[55.25107984413207, 25.218326927334207],
          [55.25107984413207, 25.160541442818463],
          [55.38291578163207, 25.160541442818463],
          [55.38291578163207, 25.218326927334207]]], null, false);
          
// import the satellite data from the European Space Agency
var S2 = ee.ImageCollection("COPERNICUS/S2");

//filter for Dubai
S2 = S2.filterBounds(Dubai);
print(S2);

//filter for date
S2 = S2.filterDate("2020-01-01", "2020-05-11");
print(S2);

var image = ee.Image(S2.first());
print(image)

Map.addLayer(image,{min:0,max:3000,bands:"B4,B3,B2"}, "Dubai");

//Map.addLayer(image,{min:0,max:3000,bands:"B8,B4,B3"}, "Dubai");

// set the selection bands
var predictionBands = image.bandNames();
//print (predictionBands);

var trainingData = Water.merge(Vegetation).merge(Urban).merge(Sand).merge(Rocks);

// sample the regions
var classifierTraining = image.select(predictionBands).sampleRegions(
                       {collection: trainingData, 
                         properties: ['land_class'], scale: 20 });

//train the classifier
var classifier =  ee.Classifier.smileRandomForest(300).train({features:classifierTraining, 
                                                    classProperty:'land_class', 
                                                   inputProperties: predictionBands});

// get the classified image
var classified = image.select(predictionBands).classify(classifier);

var Palette = [
  
  'aec3d4', //  Water
  '369b47', // Vegetation
  'cc0013', // Urban
  'cdb33b', // Sand
  'f7e084' // barren
 ];


//add the classified image to the map
Map.addLayer(classified,  {min: 1, max: 5, palette: Palette}, "LULC Dubai");