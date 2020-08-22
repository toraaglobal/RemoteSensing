########################
# Atmospheric Correction
########################

library(RStoolbox)

setwd("C:\\Users\\teeja\\Desktop\\RS\\section3\\LT05_L1TP_130045_20060424_20161122_01_T1")

meta2011 = readMeta('LT05_L1TP_130045_20060424_20161122_01_T1_MTL.txt')
summary(meta2011)

p22_2011 = stackMeta(meta2011) # stack individual landsat bands in a stack

dn2_rad=meta2011$CALRAD # extract offset gain data

dn2_rad

# convert dn to top of the atmospheric radiant
p22_2011_rad= radCor(p22_2011,metaData = meta2011, method = 'rad')
p22_2011_rad

# Obtain TOA: Top of atmosphere reflectance
p22_2011_ref = radCor(p22_2011, metaData = meta2011, method = 'apref')
p22_2011_ref

# haze correction
haze = estimateHaze(p22_2011,darkProp = 0.01, hazeBands = c("B1_dn", "B2_dn","B3_dn","B4_dn"))
haze

# DOS : dark object extraction
p22_2011_dos = radCor(p22_2011, metaData = meta2011,darkProp = 0.01, method = 'dos')
p22_2011_dos 

################
# CALCULATE NDVI
################
ndvi = spectralIndices(p22_2011, red = "B3_dn", nir = 'B4_dn', indices = 'NDVI')





