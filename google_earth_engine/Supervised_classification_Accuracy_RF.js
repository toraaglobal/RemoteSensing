Validation of supervised image

// Script Link:
https://code.earthengine.google.com/9e1350bd315bf08a9580b6ba2de4323f

// Script  - imports of training / validation data will not work - use link
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

// you can create a validation set in a similar vay and cross check your results

var validationData = ValWater.merge(ValVegetation).merge(ValUrban).merge(ValSand).merge(ValRocks);

var validation = image.sampleRegions({collection: validationData, properties: ['land_class'], scale:20,tileScale: 16});

var validated = validation.classify(classifier);

// Get confusion matrix  and user / producer's accuracies, overall accuracires and Kappa
var testAccuracy = validated.errorMatrix('land_class', 'classification');
print('Validation error matrix: ', testAccuracy);
print('Validation overall accuracy: ', testAccuracy.accuracy(), testAccuracy.consumersAccuracy(),  testAccuracy.kappa(), 
      testAccuracy.producersAccuracy());