##################
# Machine Learning
#################

library(RStoolbox)
library(rgdal)
library(sp)
library(maptools)
library(raster)
library(caret)
library(randomForest)

setwd("C:\\Users\\teeja\\Desktop\\RS\\section3\\LT05_L1TP_130045_20060424_20161122_01_T1")

meta2015=readMeta("LT05_L1TP_130045_20060424_20161122_01_T1_MTL.txt")
#refers to the meta-data file
summary(meta2015)

china_2015=stackMeta(meta2015) #stack individual Landsat bands in stack
#obtain TOA: top-of-atmosphere reflectance
china2015_ref=radCor(china_2015, metaData=meta2015, method="apref")



train2015 = readOGR(".","trainP2") #training data

train2015_utm = spTransform(train2015, CRS("+proj=utm +zone=47 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"))

#val2015 = readOGR(".","validationP1")

#val2015_utm = spTransform(val2015, CRS("+proj=utm +zone=47 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"))

plot(china2015_ref$B3_tre)
plot(train2015_utm,col="red", add = TRUE)
#I only want to work with NIR, red, green bands
b=stack(china2015_ref$B3_tre,china2015_ref$B4_tre,china2015_ref$B5_tre)
head(train2015_utm@data)

str(train2015_utm@data$id)
#sets ids as numeric values
train2015_utm@data$Code <- as.numeric(train2015_utm@data$id)
#train2015_utm@data

##rasterize the vector training data
classes <- rasterize(train2015_utm, b, field='Code')

covmasked <- mask(b, classes)
#plot(covmasked)

# combine this new brick with the classes layer to make our input training dataset
names(classes) <- "class"
trainingbrick <- addLayer(covmasked, classes)

##extract spectral values corresponding to training pixels
#into a data frame

# extract all values into a matrix
valuetable <- getValues(trainingbrick)
head(valuetable)
valuetable <- na.omit(valuetable)

valuetable <- as.data.frame(valuetable)
head(valuetable)
summary(valuetable)

valuetable$class <- factor(valuetable$class, levels = c(1:3))
#set classes as factor

#classification with randomForest
modelRF <- randomForest(x=valuetable[ ,c(1:3)], y=valuetable$class, importance = TRUE)

modelRF$confusion
varImpPlot(modelRF)


# Predicting response variable
valuetable$predicted.response = predict(modelRF, valuetable)

# Create Confusion Matrix
print(confusionMatrix(data = valuetable$predicted.response,  
                      reference = valuetable$class,
                      positive = 'class'))



###predict for Mapping

predLC <- predict(b, model=modelRF, na.rm=TRUE)
plot(predLC, legend=TRUE)

##provide legend
cols <- c("dark green","yellow","brown")
plot(predLC, col=cols, legend=FALSE)
legend("bottomright",
       legend=c("Forest", "Degraded", "Bare"),
       fill=cols, bg="white") #customized legend

#########CARET PACKAGE: Different ML algo+ data split

##do all steps till getting valuetable in data frame and set class as factor
valuetable <- as.data.frame(valuetable)
head(valuetable)
summary(valuetable)

valuetable$class <- factor(valuetable$class, levels = c(1:3))

##use caret to split data

set.seed(3456)
trainIndex <- createDataPartition(valuetable$class, p = .7, 
                                  list = FALSE, 
                                  times = 1)

valTrain <- valuetable[ trainIndex,] #70% data for training
valTest  <- valuetable[-trainIndex,] #30% data for testing


#10 cv
fitControl <- trainControl(method = "repeatedcv",number = 10,
                           ## repeated ten times
                           repeats = 10)

set.seed(825)
rfFit1 <- train(class ~ ., data = valTrain, 
                method = "rf", 
                #trControl = fitControl,
                ## This last option is actually one
                ## for rf() that passes through
                verbose = FALSE)
rfFit1

# Predicting response variable
prediction <- predict(rfFit1, valTest)

# Create Confusion Matrix
print(confusionMatrix(data = prediction,  
                      reference = valTest$class,
                      positive = 'class'))
