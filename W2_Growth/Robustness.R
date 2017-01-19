################################
### ROBUSTNESS CHECKS
################################



################################
### ORIGINAL DATA
################################

library(foreign) # Load foreign package to read dta (stata) files

data=read.dta("gjv.dta") # Read main replication dataset

summary(data) # Check out the summary statistics



################################
### REPLICATION OF INITIAL REGRESSIONS (TABLE 1)
################################

# We replicate table 1 in R
# Here we begin with the OLS regressions, later use robust standard errors

data_2010=data[data$year==2010,] # Only use year 2010 data for cross-sectional analysis
summary(data_2010)

lm1 = lm(urbrate ~ mfgserv_gdp2010 + nrx2_mean, weights=pop, data=data_2010) # Main regression, note: weighted by population
summary(lm1)

lm2 = lm(urbrate ~ mfgserv_gdp2010 + nrx2_mean + factor(continent), weights=pop, data=data_2010)
summary(lm2)

lm3 = lm(urbrate ~ mfgserv_gdp2010 + nrx2_mean + factor(continent) + primacy2010 + threshold_level + factor(type) + smallisland + area + r2density + popgrowthrate + pop + auto + conflict + landlocked + drought, weights=pop, data=data_2010)
summary(lm3)

lm4 = lm(urbrate ~ mfgserv_gdp2010 + nrx2_mean + nrx1960 + urbrate1960 + factor(continent) + primacy2010 + threshold_level + factor(type) + smallisland + area + r2density + popgrowthrate + pop + auto + conflict + landlocked + drought, weights=pop, data=data_2010)
summary(lm4)

lm5 = lm(urbrate ~ mfgserv_gdp2010 + nrx2_mean + nrx1960 + urbrate1960 + factor(region) + primacy2010 + threshold_level + factor(type) + smallisland + area + r2density + popgrowthrate + pop + auto + conflict + landlocked + drought, weights=pop, data=data_2010)
summary(lm5)



################################
### ROBUST STANDARD ERRORS
################################

# We need the following packages to estimate robust standard errors

library(sandwich)
library(lmtest)

coeftest(lm1, vcov = vcovHC(lm1, "HC0")) # Robust standard errors for all regressions
coeftest(lm2, vcov = vcovHC(lm2, "HC0"))
coeftest(lm3, vcov = vcovHC(lm3, "HC0"))  
coeftest(lm4, vcov = vcovHC(lm4, "HC0"))  
coeftest(lm5, vcov = vcovHC(lm5, "HC0"))

# Please note that we have included replications for
# all tables/all regressions (including descriptions) as stata do file



################################
### BOOTSTRAPPING
################################

# We need the boot package for the boostrapping procedure

library(boot)

# We create a boot function, which is the foundation for the boostrapping procedure

boot.function=function(formula, data, indices){
  d=data[indices,]
  fit=lm(formula, data=d)
  return(coef(fit))
}

# We estimate 1000 regressions based on samples of the data, then inspect the distribution of the coefficient of interest

results1=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm1) # Bootstrap based on our dataset
results1
plot(results1, index=2)

results2=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm2)
results2
plot(results2, index=2)

results3=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm3)
results3
plot(results3, index=2)

results4=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm4)
results4
plot(results4, index=2)

results5=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm5)
results5
plot(results5, index=2)

# Please note that we did not include robust standard errors here, so the bootstrap procedure is imperfect



################################
### REPLICATION OF PANEL REGRESSIONS (TABLE 3)
################################

# Here we use bootstrapping to look at the robustness of the panel regressions (table 3)
# Again, the imperfection here is that we have not applied robust standard errors (greater complexity)

library(multiwayvcov)
library(lmtest)
library(sandwich)



################################
### FIRST REGRESSION
################################

lm6=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + factor(year) + factor(country), weights=pop, data=data)
summary(lm6)

lm6.vcovCL=cluster.vcov(lm6, data$country)
coeftest(lm6, lm6.vcovCL)
coeftest(lm6, vcov=vcovHC(lm6,type="HC0",cluster="country"))



################################
### SECOND REGRESSION
################################

lm7=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + factor(year) + factor(year)*factor(continent) + factor(country), weights=pop, data=data)
summary(lm7)

lm7.vcovCL=cluster.vcov(lm7, data$country)
coeftest(lm7, lm7.vcovCL)
coeftest(lm7, vcov=vcovHC(lm7,type="HC0",cluster="country"))



################################
### SIMPLE BOOTSTRAPPING
################################

# Note that this does not account for clustered standard errors
# But we have included a function below that does

results6=boot(data=data, statistic=boot.function, R=1000, formula=lm6)
results6
plot(results6, index=2)

results7=boot(data=data, statistic=boot.function, R=1000, formula=lm7)
results7
plot(results7, index=2)



################################
### BOOTSTRAPPING WITH CLUSTERED STANDARD ERRORS
################################

# Below is a bootstrapping function that accounts for clusters
# This function is superior in terms of estimating the correct standard errors
# Function from here: https://www.r-bloggers.com/the-cluster-bootstrap/

clusbootreg <- function(formula, data, cluster, reps=1000){
  reg1 <- lm(formula, data)
  clusters <- names(table(cluster))
  sterrs <- matrix(NA, nrow=reps, ncol=length(coef(reg1)))
  for(i in 1:reps){
    index <- sample(1:length(clusters), length(clusters), replace=TRUE)
    aa <- clusters[index]
    bb <- table(aa)
    bootdat <- NULL
    for(j in 1:max(bb)){
      cc <- data[cluster %in% names(bb[bb %in% j]),]
      for(k in 1:j){
        bootdat <- rbind(bootdat, cc)
      }
    }
    sterrs[i,] <- coef(lm(formula, bootdat))
  }
  val <- cbind(coef(reg1),apply(sterrs,2,sd))
  colnames(val) <- c("Estimate","Std. Error")
  return(val)
}



################################
### APPLY TO THE ABOVE REGRESSIONS
################################

clusbootreg(lm6, data=data, cluster=data$country)
clusbootreg(lm7, data=data, cluster=data$country)

# The results show that the original estimates are very close to the bootstrapped results
