#################
# Alos Palsar
#################

library(raster)

setwd("C:\\Users\\teeja\\Desktop\\RS\\section6\\alos")


hh=raster("N06E115_07_sl_HH_Spk.tif") 
#plot(hh)

sighh=((10*log10(hh*hh))-83) ##correction factor. We get sigma dB of HH

plot(sighh)

hv=raster("N06E115_07_sl_HV_Spk.tif") 

#plot(hv)

sighv=((10*log10(hv*hv))-83) #sigma dB of HV

#plot(sighv)



############# Now we convert sigma to linear

linhh=10^(sighh/10) ##For HH

plot(linhh)

linhv=10^(sighv/10) ##For HV

Rlin=(linhh-linhv)/(linhh+linhv)  ##RFDI with linear HH and HV
plot(Rlin)