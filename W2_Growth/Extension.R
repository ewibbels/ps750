################################
### ORIGINAL DATA
################################

library(foreign)

data=read.dta("gjv.dta")

summary(data)



################################
### EXTENSION DATA 1
################################

data_ext=read.csv("Extension_Data.csv")

summary(data_ext)

data_ext$country=data_ext$ï..Country.Name
data_ext$year=data_ext$Time

data_ext$deaths=data_ext$Battle.related.deaths..number.of.people...VC.BTL.DETH.
data_ext$net_aid=data_ext$Net.official.aid.received..constant.2013.US....DT.ODA.OATL.KD.
data_ext$FDI=data_ext$Foreign.direct.investment..net.inflows....of.GDP...BX.KLT.DINV.WD.GD.ZS.
data_ext$milexp=data_ext$Military.expenditure....of.GDP...MS.MIL.XPND.GD.ZS.
data_ext$agc_land=data_ext$Agricultural.land..sq..km...AG.LND.AGRI.K2.

data_ext$deaths[data_ext$deaths==".."]=NA
data_ext$net_aid[data_ext$net_aid==".."]=NA
data_ext$FDI[data_ext$FDI==".."]=NA
data_ext$milexp[data_ext$milexp==".."]=NA
data_ext$agc_land[data_ext$agc_land==".."]=NA

keep_var=c("country","year","deaths","net_aid","FDI","milexp","agc_land")

data_ext=data_ext[,keep_var]

summary(final)



################################
### MERGE DATA FRAMES
################################

final=merge(data,data_ext, by=c("country","year"), all.x=T)

summary(final)

write.csv(final,"final.csv")



################################
### EXTENSION DATA 2
################################

data_ext2=read.csv("Extension_Data_2.csv")

summary(data_ext2)

data_ext2$year=data_ext2$ï..Time

data_ext2$food_price=data_ext2$Agr..Food..2010.100..real.2010...KIFOOD.
data_ext2$grain_price=data_ext2$Agr..Food..Grains..2010.100..real.2010...KIGRAINS.
data_ext2$raw_price=data_ext2$Agr..Raw.materials..2010.100..real.2010...KIRAW_MATERIAL.

keep_var2=c("year","food_price","grain_orice","raw_price")

data_ext2=data_ext2[,keep_var2]



################################
### MERGE DATA FRAMES, AGAIN
################################

final2=merge(data,data_ext2, by=c("year"), all.x=T)

summary(final2)

write.csv(final2,"final2.csv")



################################
### EXTENSION TABLE 3
################################

data2=read.csv("final2.csv")

data2$urbrate=as.numeric(data2$urbrate)

################################
### FIRST REGRESSION EXTENSION 1
################################

lm6ext1=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + food_price + factor(year) + factor(country), weights=pop, data=data2)
summary(lm6ext1)

lm6ext1.vcovCL=cluster.vcov(lm6ext1, data2$country)
coeftest(lm6ext1, lm6ext1.vcovCL)
coeftest(lm6ext1, vcov=vcovHC(lm6ext1,type="HC0",cluster="country"))


################################
### SECOND REGRESSION EXTENSION 1
################################

lm7ext1=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + food_price + factor(year) + factor(year)*factor(continent) + factor(country), weights=pop, data=data2)
summary(lm7ext1)

lm7ext1.vcovCL=cluster.vcov(lm7ext1, data2$country)
coeftest(lm7ext1, lm7ext1.vcovCL)
coeftest(lm7ext1, vcov=vcovHC(lm7ext1,type="HC0",cluster="country"))


################################
### FIRST REGRESSION EXTENSION 2
################################

lm6ext2=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + grain_price + factor(year) + factor(country), weights=pop, data=data2)
summary(lm6ext2)

lm6ext2.vcovCL=cluster.vcov(lm6ext2, data2$country)
coeftest(lm6ext2, lm6ext2.vcovCL)
coeftest(lm6ext2, vcov=vcovHC(lm6ext2,type="HC0",cluster="country"))


################################
### SECOND REGRESSION EXTENSION 2
################################

lm7ext2=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + grain_price + factor(year) + factor(year)*factor(continent) + factor(country), weights=pop, data=data2)
summary(lm7ext2)

lm7ext2.vcovCL=cluster.vcov(lm7ext2, data2$country)
coeftest(lm7ext2, lm7ext2.vcovCL)
coeftest(lm7ext2, vcov=vcovHC(lm7ext2,type="HC0",cluster="country"))
