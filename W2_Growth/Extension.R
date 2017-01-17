################################
### ORIGINAL DATA
################################

library(foreign)

data=read.dta("gjv.dta")

summary(data)



################################
### EXTENSION DATA
################################

data_ext=read.csv("Extension_Data.csv")

summary(data_ext)

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