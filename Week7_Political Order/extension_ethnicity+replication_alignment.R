#################################################################
##########				Packages/Functions			   ##########
#################################################################

library(texreg)
library(foreign)
library(maptools)
library(sandwich)
library(survival)
library(lme4)
library(arm)
library(lmtest)

cl   <- function(dat,fm, cluster){
  require(sandwich, quietly = TRUE)
  require(lmtest, quietly = TRUE)
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- fm$rank
  dfc <- (M/(M-1))*((N-1)/(N-K))
  uj  <- apply(estfun(fm),2, function(x) tapply(x, cluster, sum));
  vcovCL <- dfc*sandwich(fm, meat=crossprod(uj)/N)
  coeftest(fm, vcovCL) }
###
predict.rob <- function(x,clcov,newdata, n){
  if(missing(newdata)){ newdata <- x$model }
  tt <- terms(x)
  Terms <- delete.response(tt)
  m.mat <- model.matrix(Terms,data=newdata)
  m.coef <- x$coef
  fit <- as.vector(m.mat %*% x$coef)
  se.fit <- sqrt(diag(m.mat%*%clcov%*%t(m.mat)))
  error <- qnorm(.95)*se.fit/sqrt(n)
  left <- fit - error
  right <- fit + error
  return(list(fit=fit,se.fit=se.fit, error = error, left = left, right = right))}

#################################################################
##########				Getting Data Ready			   ##########
#################################################################

setwd("C:/DUKE/2017spring/poli-econ development/replication project")
dat <- read.table("Shuffle_replication_data.tab", sep="\t", header = T, fill = TRUE)
dat.avg <- dat[dat$year == 1997,]
dat.avg1 <- dat.avg[dat.avg$avg_drop_indicator==1,]
dat.9298 <- dat[dat$year < 1998,]

#### Test: District-Level Ethnicity ####

dist_eth <- read.table("Ethnicity by District.txt", header = T, sep=",",fill=FALSE)
# This dataset is created by identifying ethnicity controlled districts with ArcGIS
colnames(dist_eth)[2] <- "district_str"

data_m <- merge(dat.avg1, dist_eth, by = "district_str")
data_m$eth <- NA
data_m$eth[data_m$Ethnicity == 0] = "None"
data_m$eth[data_m$Ethnicity == 1] = "Kal"
data_m$eth[data_m$Ethnicity == 2] = "Kik"
data_m$eth[data_m$Ethnicity == 3] = "Both"

### Plot for Ethnicity by District ###
library(ggplot2)
ggplot(data = data_m, aes(eth, fill = eth)) + 
  geom_bar(stat = "count") + 
  labs(x = "Ethnicity", y= "District Numbers") + 
  scale_x_discrete(labels=c("Both","Kalenjin","Kikuyu","Neither")) +
  theme(#axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text = element_text(size=20), 
    axis.title.x = element_text(vjust=-0.1, size=20),
    axis.title.y = element_text(vjust=+1.1, size=20),
    plot.background = element_blank(),
    panel.grid.major = element_blank(),
    legend.position="none")

kal.avg.test1 <- lm(total_dos_9298_kal_p ~ rvdummy + laggedvoteshare 
                    + elf 
                    + lpop + lsqkm + cabinet_9397 + eth-1
                    , data=data_m)
summary(kal.avg.test1)

kik.avg.test1<- lm(total_dos_9298_kik_p ~ rvdummy + laggedvoteshare 
                   + elf 
                   + lpop + lsqkm + cabinet_9397 + eth-1
                   , data=data_m)
summary(kik.avg.test1)

data_m2 <- merge(dat.9298, dist_eth, by = "district_str")
data_m2$eth <- NA
data_m2$eth[data_m$Ethnicity == 0] = "None"
data_m2$eth[data_m$Ethnicity == 1] = "Kal"
data_m2$eth[data_m$Ethnicity == 2] = "Kik"
data_m2$eth[data_m$Ethnicity == 3] = "Both"

kal.test1 <- glm(kalofficer ~ rvdummy + laggedvoteshare 
                 + total_dos
                 + electionyear 
                 + elf 
                 + lpop + lsqkm + cabinet + eth-1
                 , data=data_m2, family = "binomial")
summary(kal.test1)

kik.test1 <- glm(kikofficer ~ rvdummy + laggedvoteshare 
                 + total_dos
                 + electionyear 
                 + elf 
                 + lpop + lsqkm + cabinet + eth-1
                 , data=data_m2, family = "binomial")
summary(kik.test1)

#### Change the definition of alignment ####
newalign <- read.csv("newalign.csv", header = T)
# This dataset is created by identifying ethnicity controlled provinces with ArcGIS
colnames(newalign)[1] <- "prov_str"
test_dat.avg <- merge(newalign, dat.avg1, by = "prov_str")
test_dat.avg$newunalign <- 0
test_dat.avg$newunalign[test_dat.avg$NewAL == "None"] = 1

kal.avg.unaligneddummy <- lm(total_dos_9298_kal_p ~ newunalign + laggedvoteshare
                             + elf 
                             + lpop + lsqkm + cabinet_9397 
                             , data=test_dat.avg)
summary(kal.avg.unaligneddummy)

kik.avg.unaligneddummy <- lm(total_dos_9298_kik_p ~ newunalign + laggedvoteshare 
                             + elf 
                             + lpop + lsqkm + cabinet_9397 
                             , data=test_dat.avg)
summary(kik.avg.unaligneddummy)

test_dat.9298 <- merge(newalign, dat.9298, by = "prov_str")
test_dat.9298$newunalign <- 0
test_dat.9298$newunalign[test_dat.9298$NewAL == "None"] = 1

test.kal.unaligneddummy <- glm(kalofficer ~ newunalign + laggedvoteshare 
                               + total_dos
                               + electionyear 
                               + elf 
                               + lpop + lsqkm + cabinet
                               , data=test_dat.9298, family = "binomial")
summary(test.kal.unaligneddummy)

test.kik.unaligneddummy <- glm(kikofficer ~ newunalign + laggedvoteshare 
                               + total_dos
                               + electionyear 
                               + elf 
                               + lpop + lsqkm + cabinet
                               , data=test_dat.9298, family = "binomial")
summary(test.kik.unaligneddummy)
