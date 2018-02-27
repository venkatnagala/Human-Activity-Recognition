#Takes some time to complete the run
#setwd("C:/Users/venkat/My Documents/HAR")
load("trainData.Rdata")
load("testData.Rdata")
load("topFactors.Rdata")

library(e1071)

library(foreach)
library(doSNOW)
library(parallel)
# coreNumber<-max(detectCores()-2,1)
coreNumber<-max(detectCores()-1,1)
cluster <-makeCluster(coreNumber, type = "SOCK",outfile="")
registerDoSNOW(cluster)

iScoreTop<-as.character(iScore[,1])

repNo    <- 27
bagRatio <- 0.9

# Start the clock!
ptm <- proc.time()
predictedValuesSVM <-foreach(1:repNo, .combine='+',.packages='e1071',.inorder=FALSE) %dopar%{
  
  training_positions <- sample(nrow(trainData), size=floor((nrow(trainData)*bagRatio)),
                               replace = FALSE)
  train_pos<-1:nrow(trainData) %in% training_positions

  svmMod<-tune.svm(trainData[train_pos,iScoreTop], trainData[train_pos,"activity"],probability=TRUE)$best.model  
  svm.pred<-predict(svmMod, testData[,iScoreTop],probability=TRUE)
  round(attr(svm.pred, "prob")[1:nrow(testData),],4)    
}

predictedValuesSVM<-data.frame(round((predictedValuesSVM/repNo),5))

predictedValuesSVM$predict<-""
for(j in 1:nrow(predictedValuesSVM)){
  predictedValuesSVM[j,]$predict<-names(which.max(predictedValuesSVM[j,]))
}

# Stop the clock
proc.time() - ptm

save(predictedValuesSVM,file="Venkat_svmBagPredict.Rdata")

# submit prediction
write.table(predictedValuesSVM$predict, file = "Venkat_svmBagPredict.csv", row.names = FALSE, col.names = FALSE)
