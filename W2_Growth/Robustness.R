################################
### ROBUSTNESS CHECKS
################################



################################
### ORIGINAL DATA
################################

library(foreign)

data=read.dta("gjv.dta")

summary(data)



################################
### REPLICATION OF INITIAL REGRESSIONS (TABLE 1)
################################

data_2010=data[data$year==2010,]
summary(data_2010)

lm1 = lm(urbrate ~ mfgserv_gdp2010 + nrx2_mean, weights=pop, data=data_2010)
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

library(sandwich)
library(lmtest)

coeftest(lm1, vcov = vcovHC(lm1, "HC0"))
coeftest(lm2, vcov = vcovHC(lm2, "HC0"))
coeftest(lm3, vcov = vcovHC(lm3, "HC0"))  
coeftest(lm4, vcov = vcovHC(lm4, "HC0"))  
coeftest(lm5, vcov = vcovHC(lm5, "HC0"))



################################
### BOOTSTRAPPING
################################

library(boot)

boot.function=function(formula, data, indices){
  d=data[indices,]
  fit =lm(formula, data=d)
  return(coef(fit))
}

results1=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm1)
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



################################
### REPLICATION OF PANEL REGRESSIONS (TABLE 3)
################################

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
### BOOTSTRAPPING
################################

results6=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm6)
results6
plot(results6, index=2)

results7=boot(data=data_2010, statistic=boot.function, R=1000, formula=lm7)
results7
plot(results7, index=2)
