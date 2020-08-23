// import the satellite data from the European Space Agency
var S2 = ee.ImageCollection("COPERNICUS/S2");

//filter for Dubai
S2 = S2.filterBounds(Dubai);
print(S2);

//filter for date
S2 = S2.filterDate("2020-01-01", "2020-05-11");
print(S2);

// Visualize the first image - True colour composite 
var image = ee.Image(S2.first());
Map.addLayer(image,{min:0,max:3000,bands:"B4,B3,B2"}, "Dubai");
// Visualize the first image - False colour composite 
Map.addLayer(image,{min:0,max:3000,bands:"B8,B4,B3"}, "Dubai");

