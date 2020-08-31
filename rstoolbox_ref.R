#################
## Remote Sensing Toolbox
## RStoolbox Packages
################
library(RStoolbox)
library(raster)
library(ggplot2)

setwd("C:\\Users\\teeja\\Desktop\\RS\\section3\\LT05_L1TP_130045_20060424_20161122_01_T1")

meta2015=readMeta("LT05_L1TP_130045_20060424_20161122_01_T1_MTL.txt")
#refers to the meta-data file
summary(meta2015)


#######################################################################
## Classify Landsat QA bands
#######################################################################
## QA classes
qa = raster('LT05_L1TP_130045_20060424_20161122_01_T1_BQA.TIF')
qacs <- classifyQA(img = qa)
## Confidence levels
qacs_conf <- classifyQA(img = qa, confLayers = TRUE)


########################################################################
### Simple Cloud Detection
########################################################################
## Import Landsat example subset
data(lsat)
## We have two tiny clouds in the east
ggRGB(lsat, stretch = "lin")

## Calculate cloud index
cldmsk <- cloudMask(lsat, blue = 1, tir = 6)
ggR(cldmsk, 2, geom_raster = TRUE)

## Everything above the threshold is masked
## In addition we apply a region-growing around the core cloud pixels
cldmsk_final <- cloudMask(cldmsk, threshold = 0.1, buffer = 5)

## Plot cloudmask
ggRGB(lsat, stretch = "lin") +
  ggR(cldmsk_final[[1]], ggLayer = TRUE, forceCat = TRUE, geom_raster = TRUE) +
  scale_fill_manual(values = c("red","green"), na.value = NA)

#' ## Estimate cloud shadow displacement
## Interactively (click on cloud pixels and the corresponding shadow pixels)
## Not run: shadow <- cloudShadowMask(lsat, cldmsk_final, nc = 2)
## Non-interactively. Pre-defined shadow displacement estimate (shiftEstimate)
shadow <- cloudShadowMask(lsat, cldmsk_final, shiftEstimate = c(-16,-6))

## Plot
csmask <- raster::merge(cldmsk_final[[1]], shadow)
ggRGB(lsat, stretch = "lin") +
  ggR(csmask, ggLayer = TRUE, forceCat = TRUE, geom_raster = TRUE) +
  scale_fill_manual(values = c("blue", "yellow"),
                    labels = c("shadow", "cloud"), na.value = NA)




########################################################################
### Cloud Shadow Masking for Flat Terrain
########################################################################
## Import Landsat example subset
data(lsat)
## We have two tiny clouds in the east
ggRGB(lsat, stretch = "lin")
## Calculate cloud index
cldmsk <- cloudMask(lsat, blue = 1, tir = 6)
ggR(cldmsk, 2, geom_raster = TRUE)

## Define threshold (re-use the previously calculated index)
## Everything above the threshold is masked
## In addition we apply a region-growing around the core cloud pixels
cldmsk_final <- cloudMask(cldmsk, threshold = 0.1, buffer = 5)

## Plot cloudmask
ggRGB(lsat, stretch = "lin") +
  ggR(cldmsk_final[[1]], ggLayer = TRUE, forceCat = TRUE, geom_raster = TRUE) +
  scale_fill_manual(values = c("red","green"), na.value = NA)

#' ## Estimate cloud shadow displacement
## Interactively (click on cloud pixels and the corresponding shadow pixels)
## Not run: shadow <- cloudShadowMask(lsat, cldmsk_final, nc = 2)
## Non-interactively. Pre-defined shadow displacement estimate (shiftEstimate)
shadow <- cloudShadowMask(lsat, cldmsk_final, shiftEstimate = c(-16,-6))
## Plot
csmask <- raster::merge(cldmsk_final[[1]], shadow)
ggRGB(lsat, stretch = "lin") +
  ggR(csmask, ggLayer = TRUE, forceCat = TRUE, geom_raster = TRUE) +
  scale_fill_manual(values = c("blue", "yellow"),
                    labels = c("shadow", "cloud"), na.value = NA)






########################################################################
### Image to Image Co-Registration based on Mutual Information
########################################################################
library(raster)
library(ggplot2)
library(reshape2)
data(rlogo)
reference <- rlogo

## Shift reference 2 pixels to the right and 3 up
missreg <- shift(reference, 2, 3)

## Compare shift
p <- ggR(reference, sat = 1, alpha = .5)
p + ggR(missreg, sat = 1, hue = .5, alpha = 0.5, ggLayer=TRUE)

## Coregister images (and report statistics)
coreg <- coregisterImages(missreg, master = reference,
                          nSamples = 500, reportStats = TRUE)

## Plot mutual information per shift
ggplot(coreg$MI) + geom_raster(aes(x,y,fill=mi))

## Plot joint histograms per shift (x/y shift in facet labels)
df <- melt(coreg$jointHist)
df$L1 <- factor(df$L1, levels = names(coreg$jointHist))
df[df$value == 0, "value"] <- NA ## don't display p = 0
ggplot(df) + geom_raster(aes(x = Var2, y = Var1,fill=value)) + facet_wrap(~L1) +
  scale_fill_gradientn(name = "p", colours = heat.colors(10), na.value = NA)

## Compare correction
ggR(reference, sat = 1, alpha = .5) +
  ggR(coreg$coregImg, sat = 1, hue = .5, alpha = 0.5, ggLayer=TRUE)


########################################################################
### estimateHaze Estimate Image Haze for Dark Object Subtraction (DOS)
########################################################################
data(lsat)
## Estimate haze for blue, green and red band
haze <- estimateHaze(lsat, hazeBands = 1:3, plot = TRUE)
haze
## Find threshold interactively
#### Return the frequency tables for re-use
#### avoids having to sample the Raster again and again
haze <- estimateHaze(lsat, hazeBands = 1:3, returnTables = TRUE)

## Use frequency table instead of lsat and fiddle with
haze <- estimateHaze(haze, hazeBands = 1:3, darkProp = .1, plot = TRUE)
haze$SHV


########################################################################
### fCover Fractional Cover Analysis
########################################################################
library(raster)
library(caret)
## Create fake input images
data(rlogo)
lsat <- rlogo
agg.level <- 9
modis <- aggregate(lsat, agg.level)

## Perform classification
lc <- unsuperClass(lsat, nClass=2)

## Calculate the true cover, which is of course only possible in this example,
## because the fake corse resolution imagery is exactly res(lsat)*9
trueCover <- aggregate(lc$map, agg.level, fun = function(x, ...){sum(x == 1, ...)/sum(!is.na)})

## Run with randomForest and support vector machine (radial basis kernel)
## Of course the SVM is handicapped in this example due to poor tuning (tuneLength)
par(mfrow=c(2,3))
for(model in c("rf", "svmRadial")){
  fc <- fCover(
    classImage = lc$map ,
    predImage = modis,
    classes=1,
    model=model,
    nSample = 50,
    number = 5,
    tuneLength=2
  )

## How close is it to the truth?
compare.rf <- trueCover - fc$map
plot(fc$map, main = paste("Fractional Cover: Class 1\nModel:", model))
plot(compare.rf, main = "Diffence\n true vs. predicted")
plot(trueCover[],fc$map[], xlim = c(0,1), ylim =c(0,1),
     xlab = "True Cover", ylab = "Predicted Cover" )
abline(coef=c(0,1))
rmse <- sqrt(cellStats(compare.rf^2, sum))/ncell(compare.rf)
r2 <- cor(trueCover[], fc$map[], "complete.obs")
text(0.9,0.1,paste0(paste(c("RMSE:","R2:"),
                          round(c(rmse, r2),3)),collapse="\n"), adj=1)
}
## Reset par
par(mfrow=c(1,1))


########################################################################
### fortify.raster Fortify method for classes from the raster package.
########################################################################
library(ggplot2)
data(rlogo)
r_df <- fortify(rlogo)
head(r_df)


########################################################################
### getMeta Extract bandwise information from ImageMetaData
########################################################################
setwd("C:\\Users\\teeja\\Desktop\\RS\\section3\\LT05_L1TP_130045_20060424_20161122_01_T1")

meta = readMeta('LT05_L1TP_130045_20060424_20161122_01_T1_MTL.txt')
summary(meta)

lsat <- stackMeta(meta)

## Get integer scale factors
getMeta(lsat, metaData = meta, what = "SCALE_FACTOR")

## Conversion factors for brightness temperature
getMeta("B6_dn", metaData = meta, what = "CALBT")

## Conversion factors to top-of-atmosphere radiance
## Band order not corresponding to metaData order
getMeta(lsat[[5:1]], metaData = meta, what = "CALRAD")

## Get integer scale factors
getMeta(lsat, metaData = meta, what = "SCALE_FACTOR")
## Get file basenames
getMeta(lsat, metaData = meta, what = "FILES")


########################################################################
### getValidation Extract validation results from superClass objects
########################################################################
library(pls)
## Fit classifier (splitting training into 70\% training data, 30\% validation data)
train <- readRDS(system.file("external/trainingPoints.rds", package="RStoolbox"))
SC <- superClass(rlogo, trainData = train, responseCol = "class",
                 model="pls", trainPartition = 0.7)

## Independent testset-validation
getValidation(SC)
getValidation(SC, metrics = "classwise")
## Cross-validation based
getValidation(SC, from = "cv")



########################################################################
### ggR Plot RasterLayers in ggplot with greyscale
########################################################################
library(ggplot2)
library(raster)
data(rlogo); data(lsat); data(srtm)
## Simple grey scale annotation
ggR(rlogo)
## With linear stretch contrast enhancement
ggR(rlogo, stretch = "lin", quantiles = c(0.1,0.9))
## ggplot with geom_raster instead of annotation_raster
## and default scale_fill*
ggR(rlogo, geom_raster = TRUE)
## with different scale
ggR(rlogo, geom_raster = TRUE) +
  scale_fill_gradientn(name = "mojo", colours = rainbow(10)) +
  ggtitle("**Funkadelic**")

## Plot multiple layers
ggR(lsat, 1:6, geom_raster=TRUE, stretch = "lin") +
  scale_fill_gradientn(colors=grey.colors(100), guide = FALSE) +
  theme(axis.text = element_text(size=5),
        axis.text.y = element_text(angle=90),
        axis.title=element_blank())


## Don't plot, just return a data.frame
df <- ggR(rlogo, ggObj = FALSE)
head(df, n = 3)


## Layermode (ggLayer=TRUE)
data <- data.frame(x = c(0, 0:100,100), y = c(0,sin(seq(0,2*pi,pi/50))*10+20, 0))
ggplot(data, aes(x, y)) + ggR(rlogo, geom_raster= FALSE, ggLayer = TRUE) +
  geom_polygon(aes(x, y), fill = "blue", alpha = 0.4) +
  coord_equal(ylim=c(0,75))

## Categorical data
## In this case you probably want to use geom_raster=TRUE
## in order to perform aestetic mapping (i.e. a meaningful legend)
rc <- raster(rlogo)
rc[] <- cut(rlogo[[1]][], seq(0,300, 50))
ggR(rc, geom_raster = TRUE)

## Legend cusomization etc. ...
ggR(rc, geom_raster = TRUE) + scale_fill_discrete(labels=paste("Class", 1:6))

## Creating a nicely looking DEM with hillshade background
terr <- terrain(srtm, c("slope", "aspect"))
hill <- hillShade(terr[["slope"]], terr[["aspect"]])
ggR(hill)

ggR(hill) +
  ggR(srtm, geom_raster = TRUE, ggLayer = TRUE, alpha = 0.3) +
  scale_fill_gradientn(colours = terrain.colors(100), name = "elevation")










