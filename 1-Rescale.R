#setwd("C:/Users/venkat/My Documents/HAR")
trainData<-read.csv("C:/Users/venkat/My Documents/HAR/Data/train.csv")
testData<-read.csv("C:/Users/venkat/My Documents/HAR/Data/test.csv")

#convert activity and subject to factor
trainData$subject<-as.factor(trainData$subject)
testData$subject<-as.factor(testData$subject)
trainData$activity<-as.factor(trainData$activity)

library(foreach)
library(doSNOW)
library(parallel)
coreNumber<-max(detectCores()-1,1)
cluster <-makeCluster(coreNumber, type = "SOCK",outfile="")
registerDoSNOW(cluster)

rescale <- function(data) {
  subjectArray<-unique(data$subject)
  activityCol<-which(colnames(data)=="activity") 
  
  data<-foreach(i=1:length(subjectArray),.combine=rbind,.packages='foreach')%dopar%{
                    #cbind.data.frame helps combine activity column (if present) with rescaled data
                    cbind.data.frame(
                      foreach(j=1:561,.combine=cbind)%dopar%{              
                        scale(data[data$subject == subjectArray[[i]],j])
                      }
                      ,data[data$subject == subjectArray[[i]],activityCol])
                    }
return(data)
}

trainData2<-rescale(trainData)
trainData$subject<-NULL
names(trainData2)<-names(trainData)
trainData<-trainData2

testData2<-rescale(testData)
testData$subject<-NULL
names(testData2)<-names(testData)
testData<-testData2

#split off validation data from training data
positions       <- sample(nrow(trainData),size=floor(nrow(trainData)*3/4))
trainValidData  <- trainData[positions,]
validData       <- trainData[-positions,]
validationValues<- validData$activity
validData$activity<-NULL

save(trainData,       file = "trainData.Rdata")
save(testData,        file = "testData.Rdata")
save(trainValidData,  file = "trainValidData.Rdata")
save(validData,       file = "validData.Rdata")
save(validationValues,file = "validationValues.Rdata")
