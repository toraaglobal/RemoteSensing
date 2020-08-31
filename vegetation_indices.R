####################
# Vegetation Indices
#####################

library(RStoolbox)
library(ggplot2)
library(raster)

setwd("C:\\Users\\teeja\\Desktop\\RS\\section3\\LT05_L1TP_130045_20060424_20161122_01_T1")

meta2011 = readMeta('LT05_L1TP_130045_20060424_20161122_01_T1_MTL.txt')
summary(meta2011)

p22_2011 = stackMeta(meta2011) # stack individual landsat bands in a stack

# Calculate NDVI usinig uncorrected data / it can be calculated using uncorrected data
ndvi = spectralIndices(p22_2011, red = "B3_dn", nir = 'B4_dn', indices = 'NDVI')

plot(ndvi)



# Convert DN to reflectance
inds_ref = radCor(p22_2011, metaData = meta2011, method = 'apref')

# spectral indices
SI = spectralIndices(inds_ref, red = 'B3_tre',nir = 'B4_tre' )
plot(SI)


ggR(ndvi, geom_raster = TRUE) + scale_fill_gradientn(colours=c('blue','red'))



