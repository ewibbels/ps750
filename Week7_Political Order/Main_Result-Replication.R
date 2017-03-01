#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
##########				Packages/Functions			   ##########
#################################################################
#################################################################
#################################################################
#################################################################
install.packages("texreg")

library(texreg)
library(foreign)
library(maptools)
library(sandwich)
library(survival)
library(lme4)
library(arm)
library(lmtest)
library(stargazer)

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
#################################################################
#################################################################
#################################################################
#################################################################
##########				Getting Data Ready			   ##########
#################################################################
#################################################################
#################################################################
#################################################################
dat <- read.table("Shuffle_replication_data.tab",sep="\t",header=TRUE,fill=T)
dat.avg <- dat[dat$year == 1997,]
dat.avg <- dat.avg[dat.avg$avg_drop_indicator==1,]
dat.9298 <- dat[dat$year < 1998,]
#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
##########		Summary Stats for Table 1			   ##########
#################################################################
#################################################################
#################################################################
#################################################################
###Raw Numbers
sum(dat.9298$misalignedprovince) #441 
sum(dat.9298$kalofficer[dat.9298$misalignedprovince==1]) #41
sum(dat.9298$kikofficer[dat.9298$misalignedprovince==1]) #113
sum(dat.9298$luhyaofficer[dat.9298$misalignedprovince==1]) #37
sum(dat.9298$luoofficer[dat.9298$misalignedprovince==1]) #48
sum(dat.9298$mijiofficer[dat.9298$misalignedprovince==1]) #30

sum(dat.9298$alignedprovince)  #1428
sum(dat.9298$kalofficer[dat.9298$alignedprovince ==1]) #278
sum(dat.9298$kikofficer[dat.9298$alignedprovince ==1]) #145
sum(dat.9298$luhyaofficer[dat.9298$alignedprovince ==1]) #127
sum(dat.9298$luoofficer[dat.9298$alignedprovince ==1]) #146
sum(dat.9298$mijiofficer[dat.9298$alignedprovince ==1]) #136

sum(dat.9298$unalignedprovince)  #1689
sum(dat.9298$kalofficer[dat.9298$unalignedprovince ==1]) #362
sum(dat.9298$kikofficer[dat.9298$unalignedprovince ==1]) #247
sum(dat.9298$luhyaofficer[dat.9298$unalignedprovince ==1]) #202
sum(dat.9298$luoofficer[dat.9298$unalignedprovince ==1]) #207
sum(dat.9298$mijiofficer[dat.9298$unalignedprovince ==1]) #130

sum(dat.9298$kalofficer)  #681
sum(dat.9298$kikofficer)  #505
sum(dat.9298$luhyaofficer)  #366
sum(dat.9298$luoofficer)  #401
sum(dat.9298$mijiofficer)  #288
dim(dat.9298) #3558

###Percentages
sum(dat.9298$kalofficer[dat.9298$misalignedprovince==1])/sum(dat.9298$misalignedprovince)
sum(dat.9298$kikofficer[dat.9298$misalignedprovince==1])/sum(dat.9298$misalignedprovince)
sum(dat.9298$luhyaofficer[dat.9298$misalignedprovince==1])/sum(dat.9298$misalignedprovince)
sum(dat.9298$luoofficer[dat.9298$misalignedprovince==1])/sum(dat.9298$misalignedprovince)
sum(dat.9298$mijiofficer[dat.9298$misalignedprovince==1])/sum(dat.9298$misalignedprovince)

sum(dat.9298$kalofficer[dat.9298$alignedprovince ==1])/sum(dat.9298$alignedprovince)
sum(dat.9298$kikofficer[dat.9298$alignedprovince ==1])/sum(dat.9298$alignedprovince)
sum(dat.9298$luhyaofficer[dat.9298$alignedprovince ==1])/sum(dat.9298$alignedprovince)
sum(dat.9298$luoofficer[dat.9298$alignedprovince ==1])/sum(dat.9298$alignedprovince)
sum(dat.9298$mijiofficer[dat.9298$alignedprovince ==1])/sum(dat.9298$alignedprovince)

sum(dat.9298$kalofficer[dat.9298$unalignedprovince ==1])/sum(dat.9298$unalignedprovince)
sum(dat.9298$kikofficer[dat.9298$unalignedprovince ==1])/sum(dat.9298$unalignedprovince)
sum(dat.9298$luhyaofficer[dat.9298$unalignedprovince ==1])/sum(dat.9298$unalignedprovince)
sum(dat.9298$luoofficer[dat.9298$unalignedprovince ==1])/sum(dat.9298$unalignedprovince)
sum(dat.9298$mijiofficer[dat.9298$unalignedprovince ==1])/sum(dat.9298$unalignedprovince)


#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
##########				Main Models	-- H1			   ##########
#################################################################
#################################################################
#################################################################
#################################################################
kal.unaligneddummy <- glm(kalofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kal.unaligneddummy )
cl.kal.unaligneddummy  <- cl(dat.9298, kal.unaligneddummy , factor(dat.9298$district_str))
cl.kal.unaligneddummy 

kal.avg.unaligneddummy <- lm(total_dos_9298_kal_p ~ unalignedprovince + rvdummy + laggedvoteshare 
			+ elf 
   			+ lpop + lsqkm + cabinet_9397 
			, data=dat.avg)
summary(kal.avg.unaligneddummy)
cl.kal.avg.unaligneddummy <- cl(dat.avg, kal.avg.unaligneddummy, dat.avg$district_str)
cl.kal.avg.unaligneddummy


kik.unaligneddummy <- glm(kikofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kik.unaligneddummy )
cl.kik.unaligneddummy  <- cl(dat.9298, kik.unaligneddummy , factor(dat.9298$district_str))
cl.kik.unaligneddummy 

kik.avg.unaligneddummy <- lm(total_dos_9298_kik_p ~ unalignedprovince + rvdummy + laggedvoteshare 
			+ elf 
   			+ lpop + lsqkm + cabinet_9397 
			, data=dat.avg)
summary(kik.avg.unaligneddummy)
cl.kik.avg.unaligneddummy <- cl(dat.avg, kik.avg.unaligneddummy, dat.avg$district_str)
cl.kik.avg.unaligneddummy


texreg(list(kal.avg.unaligneddummy, kal.unaligneddummy, kik.avg.unaligneddummy, kik.unaligneddummy),
	override.se=list(cl.kal.avg.unaligneddummy[,2],
						cl.kal.unaligneddummy[,2],
						cl.kik.avg.unaligneddummy[,2],
						cl.kik.unaligneddummy[,2]
						),

	override.pval=list(cl.kal.avg.unaligneddummy[,4],
						cl.kal.unaligneddummy[,4],
						cl.kik.avg.unaligneddummy[,4],
						cl.kik.unaligneddummy[,4]
						),
	stars = c(0.001, 0.01, 0.05))

############# replication Stagazer
stargazer(kal.avg.unaligneddummy, kal.unaligneddummy, kik.avg.unaligneddummy, kik.unaligneddummy,
          title= "TABLE 3 DO Ethnicity on Division Characteristics", 
          dep.var.labels=c("Kalenjin Collapsed","Kalenjin Time-series","Kikuyu Collapsed","Kikuyu Time-series"),
          covariate.labels = c("UnalignedProvince","RiftValleyProvince","LaggedVoteShare","TotalOfficers",
                               "1997","ELF","lpop","lsqkm","Cabinet9397","Cabinet","Intercept"),
          no.space=TRUE,
          omit.stat=c("adj.rsq","aic","ll","rsq","f","res.dev"),digits=2,align=T)

#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
##########				Main Models	-- H2			   ##########
#################################################################
#################################################################
#################################################################
#################################################################
kal.interaction <- glm(kalofficer ~ unalignedprovince * laggedvoteshare  + rvdummy 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kal.interaction )
cl.kal.interaction  <- cl(dat.9298, kal.interaction , dat.9298$district_str)
cl.kal.interaction 


kal.avg.interaction <- lm(total_dos_9298_kal_p ~ unalignedprovince * laggedvoteshare  + rvdummy 
			+ elf 
   			+ lpop + lsqkm + cabinet_9397
			, data=dat.avg)
summary(kal.avg.interaction)
cl.kal.avg.interaction <- cl(dat.avg, kal.avg.interaction, dat.avg$district_str)
cl.kal.avg.interaction


kik.interaction <- glm(kikofficer ~ unalignedprovince * laggedvoteshare  + rvdummy 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kik.interaction )
cl.kik.interaction  <- cl(dat.9298, kik.interaction , dat.9298$district_str)
cl.kik.interaction 


kik.avg.interaction <- lm(total_dos_9298_kik_p ~ unalignedprovince * laggedvoteshare  + rvdummy 
			+ elf 
   			+ lpop + lsqkm + cabinet_9397
			, data=dat.avg)
summary(kik.avg.interaction)
cl.kik.avg.interaction <- cl(dat.avg, kik.avg.interaction, dat.avg$district_str)
cl.kik.avg.interaction


texreg(list(kal.avg.interaction, kal.interaction,kik.avg.interaction, kik.interaction), 
	override.se=list(cl.kal.avg.interaction[,2],
						cl.kal.interaction[,2],						
						cl.kik.avg.interaction[,2],
						cl.kik.interaction[,2]
						),

	override.pval=list(cl.kal.avg.interaction[,4],
						cl.kal.interaction[,4],						
						cl.kik.avg.interaction[,4],
						cl.kik.interaction[,4]
						),
	stars = c(0.001, 0.01, 0.05))

############ replication stagazer
stargazer(kal.avg.interaction, kal.interaction, kik.avg.interaction, kik.interaction,
          title= "DO Ethnicity on Division Characteristics(Interaction)", 
          dep.var.labels=c("Kalenjin Collapsed","Kalenjin Time-series","Kikuyu Collapsed","Kikuyu Time-series"),
          covariate.labels = c("UnalignedProvince","LaggedVoteShare","RiftValleyProvince","TotalOfficers",
                               "1997","ELF","lpop","lsqkm","Cabinet9397","Cabinet","UnalignedProvince × LaggedVoteShare","Intercept"),
          no.space=TRUE,
          omit.stat=c("adj.rsq","aic","ll","rsq","f","res.dev"),digits=2,align=T)


#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
##########				GRAPHING H1					   ##########
#################################################################
#################################################################
#################################################################
#################################################################
kal.unaligneddummy <- glm(kalofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kal.unaligneddummy )
cl.kal.unaligneddummy  <- cl(dat.9298, kal.unaligneddummy , factor(dat.9298$district_str))
cl.kal.unaligneddummy 

m1 <- kal.unaligneddummy	
dat.w1 <- dat.9298
fm <- m1
cluster <- factor(dat.9298 $district_str)

           require(sandwich, quietly = TRUE)
           require(lmtest, quietly = TRUE)
           M <- length(unique(cluster))
           N <- length(cluster)
           K <- fm$rank
           dfc <- (M/(M-1))*((N-1)/(N-K))
           uj  <- apply(estfun(fm),2, function(x) tapply(x, cluster, sum));
           vcovCL <- dfc*sandwich(fm, meat=crossprod(uj)/N)
           coeftest(fm, vcovCL) 

model <- m1
kal.outcomes <- matrix(data=NA, ncol=1, nrow=3) ##1 model, 3 quanties == mean, uper/lower bound
set.seed(02138)
N <- 1000
betas <- mvrnorm(n=1000,mu=summary(kal.unaligneddummy)$coefficients[,1], vcovCL)
dim(betas)


xt.w1.kal  <- cbind(1, 1, 
		0,
		dat.w1$laggedvoteshare,
		dat.w1$total_dos,
		dat.w1$electionyear,
		dat.w1$elf,
		dat.w1$lpop, dat.w1$lsqkm,
		dat.w1$cabinet
		)

xc.w1.kal <- cbind(1, 0,
		0,
		dat.w1$laggedvoteshare,
		dat.w1$total_dos,
		dat.w1$electionyear,
		dat.w1$elf,
		dat.w1$lpop, dat.w1$lsqkm,
		dat.w1$cabinet

		)
tprob<-apply((1/(1+exp(-(as.matrix(xt.w1.kal))%*% t(betas)))),1,as.vector)
tprobA <- apply(tprob,1,mean)

cprob<-apply((1/(1+exp(-(as.matrix(xc.w1.kal))%*% t(betas)))),1,as.vector)
cprobA <- apply(cprob,1,mean)

diffprob<-tprobA-cprobA

kal.outcomes[1,1]<- mean(diffprob)
kal.outcomes[2,1]<- quantile(diffprob,.025)
kal.outcomes[3,1]<- quantile(diffprob,.975)
kal.outcomes

kik.unaligneddummy <- glm(kikofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kik.unaligneddummy )
cl.kik.unaligneddummy  <- cl(dat.9298, kik.unaligneddummy , factor(dat.9298$district_str))
cl.kik.unaligneddummy 


m1 <- kik.unaligneddummy	
dat.w1 <- dat.9298
fm <- m1
cluster <- factor(dat.9298 $district_str)

           require(sandwich, quietly = TRUE)
           require(lmtest, quietly = TRUE)
           M <- length(unique(cluster))
           N <- length(cluster)
           K <- fm$rank
           dfc <- (M/(M-1))*((N-1)/(N-K))
           uj  <- apply(estfun(fm),2, function(x) tapply(x, cluster, sum));
           vcovCL <- dfc*sandwich(fm, meat=crossprod(uj)/N)
           coeftest(fm, vcovCL) 

model <- m1
kik.outcomes <- matrix(data=NA, ncol=1, nrow=3) ##1 model, 3 quanties == mean, uper/lower bound
set.seed(02138)
N <- 1000
betas <- mvrnorm(n=1000,mu=summary(kik.unaligneddummy)$coefficients[,1], vcovCL)
dim(betas)


xt.w1.kik  <- cbind(1, 1, 
		0,
		dat.w1$laggedvoteshare,
		dat.w1$total_dos,
		dat.w1$electionyear,
		dat.w1$elf,
		dat.w1$lpop, dat.w1$lsqkm,
		dat.w1$cabinet
		)

xc.w1.kik <- cbind(1, 0,
		0,
		dat.w1$laggedvoteshare,
		dat.w1$total_dos,
		dat.w1$electionyear,
		dat.w1$elf,
		dat.w1$lpop, dat.w1$lsqkm,
		dat.w1$cabinet

		)
tprob<-apply((1/(1+exp(-(as.matrix(xt.w1.kik))%*% t(betas)))),1,as.vector)
tprobA <- apply(tprob,1,mean)

cprob<-apply((1/(1+exp(-(as.matrix(xc.w1.kik))%*% t(betas)))),1,as.vector)
cprobA <- apply(cprob,1,mean)

diffprob<-tprobA-cprobA

kik.outcomes[1,1]<- mean(diffprob)
kik.outcomes[2,1]<- quantile(diffprob,.025)
kik.outcomes[3,1]<- quantile(diffprob,.975)
kik.outcomes


pdf(file = "H1_Plot.pdf", height = 4, width = 6)
plot(kal.outcomes[1,1], .4, xlim = c(-.2,.2), ylim = c(0, .5), pch = 16, yaxt='n', main = "Difference in Likelihood of Posting to
Unaligned v. Other Provinces", ylab = "Officer Ethnicity", cex = 1, xlab = "Difference in Likelihood of Posting to Unaligned v. Other Provinces")
axis(2, at=c(.1, .38),labels=c("Kikuyu", "Kalenjin"))
segments(kal.outcomes[2,1], .4, kal.outcomes[3,1], .4, lwd=3)
points(kik.outcomes[1,1], .08, pch = 16, cex = 1)
segments(kik.outcomes[2,1], .08, kik.outcomes[3,1], .08, lwd=3)
abline(v = 0)
dev.off()

#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
##########				GRAPHING H2					   ##########
#################################################################
#################################################################
#################################################################
#################################################################
kal.interaction <- glm(kalofficer ~ unalignedprovince * laggedvoteshare  + rvdummy 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kal.interaction )
cl.kal.interaction  <- cl(dat.9298, kal.interaction , dat.9298$district_str)
cl.kal.interaction 


m1 <- kal.interaction	
dat.m1 <- dat.9298
fm <- m1
cluster <- factor(dat.9298$district_str)
model <- m1
set.seed(02138)
N <- 1000
           require(sandwich, quietly = TRUE)
           require(lmtest, quietly = TRUE)
           M <- length(unique(cluster))
           N <- length(cluster)
           K <- fm$rank
           dfc <- (M/(M-1))*((N-1)/(N-K))
           uj  <- apply(estfun(fm),2, function(x) tapply(x, cluster, sum));
           vcovCL <- dfc*sandwich(fm, meat=crossprod(uj)/N)
           coeftest(fm, vcovCL) 
           
vs <- seq(quantile(dat.9298$laggedvoteshare, .125), quantile(dat.9298$laggedvoteshare, .875),by=.01)
vs.all.kal <-matrix(data=NA,ncol=length(vs),nrow=4)
vs.all.kik <-matrix(data=NA,ncol=length(vs),nrow=4)
betas <- mvrnorm(n=1000,mu=summary(m1)$coefficients[,1], vcovCL)

for(j in 1:length(vs)){
	if(nrow(dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]) > 0) {
######PRVSWING == 1 (xt), PRVSWING == 0	(xc)
xt.m1 <- cbind(1, 1, dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$laggedvoteshare, 
			0,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$total_dos,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$electionyear, 
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$elf,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$lpop,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$lsqkm,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$cabinet,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$laggedvoteshare)
xc.m1 <- cbind(1, 0, dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$laggedvoteshare, 
			0,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$total_dos,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$electionyear, 
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$elf,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$lpop,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$lsqkm,
			dat.m1[dat.m1$laggedvoteshare>vs[j] & dat.m1$laggedvoteshare<vs[j]+.01,]$cabinet,
			0)

tprob1<-apply((1/(1+exp(-(as.matrix(xt.m1))%*% t(betas)))),1,as.vector)
cprob1<-apply((1/(1+exp(-(as.matrix(xc.m1))%*% t(betas)))),1,as.vector)
tprobA <- apply(tprob1,1,mean)
cprobA <- apply(cprob1,1,mean)
diffprob1<-tprobA-cprobA
vs.all.kal[,j] <- c(vs[j],mean(diffprob1),quantile(diffprob1,.025),quantile(diffprob1,.975))

	}
}


kik.interaction <- glm(kikofficer ~ unalignedprovince * laggedvoteshare  + rvdummy 
			+ total_dos
			+ electionyear 
			+ elf 
   			+ lpop + lsqkm + cabinet
			, data=dat.9298, family = "binomial")
summary(kik.interaction )
cl.kik.interaction  <- cl(dat.9298, kik.interaction , dat.9298$district_str)
cl.kik.interaction 

m3 <- kik.interaction		
dat.m3 <- dat.9298
fm <- m3
cluster <- factor(dat.9298 $district_str)

model <- kik.interaction
set.seed(02138)
N <- 1000
           require(sandwich, quietly = TRUE)
           require(lmtest, quietly = TRUE)
           M <- length(unique(cluster))
           N <- length(cluster)
           K <- fm$rank
           dfc <- (M/(M-1))*((N-1)/(N-K))
           uj  <- apply(estfun(fm),2, function(x) tapply(x, cluster, sum));
           vcovCL <- dfc*sandwich(fm, meat=crossprod(uj)/N)
           coeftest(fm, vcovCL) 

betas <- mvrnorm(n=1000,mu=summary(m3)$coefficients[,1], vcovCL)

for(j in 1:length(vs)){
	if(nrow(dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]) > 0) {
######PRVSWING == 1 (xt), PRVSWING == 0	(xc)
xt.m3 <- cbind(1, 1, dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$laggedvoteshare, 
			0,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$total_dos,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$electionyear, 
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$elf,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$lpop,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$lsqkm,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$cabinet,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$laggedvoteshare)
xc.m3 <- cbind(1, 0, dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$laggedvoteshare, 
			0,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$total_dos,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$electionyear, 
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$elf,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$lpop,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$lsqkm,
			dat.m3[dat.m3$laggedvoteshare>vs[j] & dat.m3$laggedvoteshare<vs[j]+.01,]$cabinet,
			0)

tprob1<-apply((1/(1+exp(-(as.matrix(xt.m3))%*% t(betas)))),1,as.vector)
cprob1<-apply((1/(1+exp(-(as.matrix(xc.m3))%*% t(betas)))),1,as.vector)
tprobA <- apply(tprob1,1,mean)
cprobA <- apply(cprob1,1,mean)
diffprob1<-tprobA-cprobA
vs.all.kik[,j] <- c(vs[j],mean(diffprob1),quantile(diffprob1,.025),quantile(diffprob1,.975))

	}
}

a <- vs.all.kal
b <- vs.all.kik

x <- ifelse(dat.9298$laggedvoteshare < .02, .02, dat.9298$laggedvoteshare)
x <- ifelse(dat.9298$laggedvoteshare > .88, -dat.9298$laggedvoteshare, x)


pdf(file = "Main.pdf", height = 6, width = 6)
plot(vs.all.kal[1,],vs.all.kal[2,], ylab = "Difference in Postings, Unaligned v. Other Provinces", xlab = "Lagged Vote Share, Division Level", ylim = c(-.22,.25), xlim = c(.02,.89), pch = 16, cex = .6, col = "red4" , main = "Difference in Postings, 
Unaligned v. Other Provinces by Vote Share")
	segments(vs.all.kal[1,], vs.all.kal[3,], vs.all.kal[1,],vs.all.kal[4,], col="red4")
	points(vs.all.kik[1,] + .005, vs.all.kik[2,], pch = 16, cex = .6, col = "cornflowerblue")
	segments(vs.all.kik[1,]+ .005, vs.all.kik[3,], vs.all.kik[1,]+ .005,vs.all.kik[4,], col="cornflowerblue")
abline(h=0)
#rug(dat.9298$laggedvoteshare*100)
rug(x)
legnames <- c("Kalenjin Officer", "Kikuyu Officer")
legend("topright", legnames, fill = c("red4", "cornflowerblue"), bty = "n")
dev.off()









