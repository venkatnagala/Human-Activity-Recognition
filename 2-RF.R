#takes about 10mins to complete the run
#setwd("C:/Users/venkat/My Documents/HAR")
load("C:/Users/venkat/My Documents/HAR/trainData.Rdata")
load("C:/Users/venkat/My Documents/HAR/testData.Rdata")

library(randomForest)
library(foreach)
library(doSNOW)
library(parallel)

coreNumber<-max(detectCores()-1,1)
cluster <-makeCluster(coreNumber, type = "SOCK",outfile="")
registerDoSNOW(cluster)

treeAmt  <-2001

ptm <- proc.time()

#Repeat the tuning 5 times and determine the best mtry value via voting 
mtryBest<-1:5
for(i in 1:5){
  mtryBestTemp <-data.frame(tuneRF(trainData[,1:length(trainData)-1], trainData$activity, stepFactor=1.5,improve=0.005))
  mtryBest[i]  <-mtryBestTemp[which.min(mtryBestTemp[,2]),1]
}
mtryBest<-as.numeric(names(which.max(summary(as.factor(mtryBest)))))

rf  <-foreach(ntree=rep(round(2001/coreNumber),coreNumber), .combine=combine, .packages='randomForest',.inorder=FALSE) %dopar%{
              randomForest(trainData[,1:length(trainData)-1], trainData$activity, 
              keep.forest=TRUE,ntree=ntree, mtry=mtryBest)
}

proc.time() - ptm

#This table represents how much removing each variable reduces the accuracy of the model.
iScore <- importance(rf)
iScore <- data.frame(rownames(iScore),iScore)
names(iScore) <- c("attribute","importance")
iScore <- iScore[with(iScore,order(-importance)),]
iScore$importance <- sqrt(iScore$importance)

cutoffPt <-1
iScore <- iScore[iScore$importance>cutoffPt,]

save(iScore,file="topFactors.Rdata")