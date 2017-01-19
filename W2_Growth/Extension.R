################################
### ORIGINAL DATA
################################

library(foreign) # Loading the foreign library to read dta (stata) files

data=read.dta("gjv.dta") # Load the main dataset provided by the authors

summary(data) # Checking out summary statistics of the dataset



################################
### EXTENSION DATA 1
################################

# We use World Bank Data (WDI) to improve the empirical analysis
# For example, instead of using a binary measure for military conflicts
# We use battle deaths as a more nuanced measurement for the intensity of conflicts
# We also add multiple control variables that could drive urbanization
# Foreign aid inflows, FDI, military expenditures
# We had some plans for agricultural land but didn't pursue them

data_ext=read.csv("Extension_Data.csv") # Read the csv file

summary(data_ext) # Summary statistics

data_ext$country=data_ext$ï..Country.Name # Recode the variable names to match the replication dataset
data_ext$year=data_ext$Time # Recode time variable name to "year"

data_ext$deaths=data_ext$Battle.related.deaths..number.of.people...VC.BTL.DETH. # Recode battle deaths
data_ext$net_aid=data_ext$Net.official.aid.received..constant.2013.US....DT.ODA.OATL.KD. # Recode net aid inflows
data_ext$FDI=data_ext$Foreign.direct.investment..net.inflows....of.GDP...BX.KLT.DINV.WD.GD.ZS. # Recode FDI
data_ext$milexp=data_ext$Military.expenditure....of.GDP...MS.MIL.XPND.GD.ZS. # Recode military expenditures (% of GDP)
data_ext$agc_land=data_ext$Agricultural.land..sq..km...AG.LND.AGRI.K2. # Recode agricultural land

data_ext$deaths[data_ext$deaths==".."]=NA # Recode NA value entry for all variables
data_ext$net_aid[data_ext$net_aid==".."]=NA
data_ext$FDI[data_ext$FDI==".."]=NA
data_ext$milexp[data_ext$milexp==".."]=NA
data_ext$agc_land[data_ext$agc_land==".."]=NA

keep_var=c("country","year","deaths","net_aid","FDI","milexp","agc_land") # Define vector with relevant variables

data_ext=data_ext[,keep_var] # Keep only the relevant (new) variables

summary(final) # Summary of final dataset



################################
### MERGE DATA FRAMES
################################

final=merge(data,data_ext, by=c("country","year"), all.x=T) # Merge replication dataset with extension dataset

summary(final) # Summary statistics

write.csv(final,"final.csv") # Write as csv file



################################
### EXTENSION DATA 2
################################

# In the second extension we use World Bank data, too
# In this case the Global Economic Monitor (GEM) Commodities data
# This dataset allows us to test the impact of world market price movements in agricultural products
# We believe that lower world market prices in agriculture should also drive urbanization

data_ext2=read.csv("Extension_Data_2.csv") # Read the csv file

summary(data_ext2) # Summary statistics

data_ext2$year=data_ext2$ï..Time # Recode time variable

data_ext2$food_price=data_ext2$Agr..Food..2010.100..real.2010...KIFOOD. # Recode food variable name
data_ext2$grain_price=data_ext2$Agr..Food..Grains..2010.100..real.2010...KIGRAINS. # Recode grain variable name
data_ext2$raw_price=data_ext2$Agr..Raw.materials..2010.100..real.2010...KIRAW_MATERIAL. # Recode food raw material variable name

keep_var2=c("year","food_price","grain_orice","raw_price") # Define relevant variables

data_ext2=data_ext2[,keep_var2] # Keep only relevant variables



################################
### MERGE DATA FRAMES, AGAIN
################################

final2=merge(data,data_ext2, by=c("year"), all.x=T) # Merge datasets (replication + extension 2) by year

summary(final2) # Summary statistics

write.csv(final2,"final2.csv") # Write csv file



################################
### EXTENSION TABLE 3
################################

data2=read.csv("final2.csv") # Read csv file



################################
### FIRST REGRESSION EXTENSION 1
################################

# We replicate the panel data analysis with food prices added
# This allows us to estimate the influence of agricultural products
# We find a negative impact of food and grain prices on urbanization (as expected)

lm6ext1=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + food_price + factor(year) + factor(country), weights=pop, data=data2) 
summary(lm6ext1)

# We need the following packages to estimate regressions with clustered standard errors

library(lmtest)
library(sandwich)
library(multiwayvcov)

lm6ext1.vcovCL=cluster.vcov(lm6ext1, data2$country) # Create the updated variance covariance matrix for clustered standard errors
coeftest(lm6ext1, lm6ext1.vcovCL) # Use the package lmtest to test with clustered standard errors
coeftest(lm6ext1, vcov=vcovHC(lm6ext1,type="HC0",cluster="country")) # Alternative robust clustered standard errors



################################
### SECOND REGRESSION EXTENSION 1
################################

# We do the same for the second regression in table 3

lm7ext1=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + food_price + factor(year) + factor(year)*factor(continent) + factor(country), weights=pop, data=data2)
summary(lm7ext1)

lm7ext1.vcovCL=cluster.vcov(lm7ext1, data2$country)
coeftest(lm7ext1, lm7ext1.vcovCL)
coeftest(lm7ext1, vcov=vcovHC(lm7ext1,type="HC0",cluster="country"))


################################
### FIRST REGRESSION EXTENSION 2
################################

# Now we check grain prices instead of food prices

lm6ext2=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + grain_price + factor(year) + factor(country), weights=pop, data=data2)
summary(lm6ext2)

lm6ext2.vcovCL=cluster.vcov(lm6ext2, data2$country)
coeftest(lm6ext2, lm6ext2.vcovCL)
coeftest(lm6ext2, vcov=vcovHC(lm6ext2,type="HC0",cluster="country"))


################################
### SECOND REGRESSION EXTENSION 2
################################

# Next we do the same thing for the second regression, too

lm7ext2=lm(urbrate ~ nrx_previous + mfg_previous + mfgserv_gdp2010t + grain_price + factor(year) + factor(year)*factor(continent) + factor(country), weights=pop, data=data2)
summary(lm7ext2)

lm7ext2.vcovCL=cluster.vcov(lm7ext2, data2$country)
coeftest(lm7ext2, lm7ext2.vcovCL)
coeftest(lm7ext2, vcov=vcovHC(lm7ext2,type="HC0",cluster="country"))



################################
# NOTE: all further and additional extensions can be found in the stata do file provided (we only did part of the work in R)
################################


