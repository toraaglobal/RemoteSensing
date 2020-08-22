#############
# Band Ratio
#############

library(raster)


b4 = raster('LT05_L1TP_130045_20060424_20161122_01_T1_B4.TIF')
b5 = raster('LT05_L1TP_130045_20060424_20161122_01_T1_B5.TIF') 

x =b4/b5

plot(x)
