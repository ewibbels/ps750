###################
#### Extension ####
###################
rm(list = ls())
setwd("C:/DUKE/2017spring/poli-econ development/replication project 2/replication task2")

#### Table 4 ####
d.table4 <- read.csv("table4.csv")
## Negotiation -- Payment ##
m1 <- lm(lnpayment ~ zpostbargain + factor(postdirmonth)-1, data = d.table4)

m2 <- lm(lnpayment ~ zpostbargain + truckage + truckage2 + zincludedCbesibekas +
           zincludedCconstruction + zincludedCfood + zincludedCagprod + 
           zincludedCmanufac + ztruckovertons + lnsal + factor(postdirmonth)-1,
         data = d.table4)
summary(m2)

## Negotiation power of truck drivers ##
m3 <- lm(zpostbargain ~ zdriverage + zdriveredyears + zdriverspeaksaceh + 
           zdriveryearsexp + zdrivertrips + lnsal + factor(postdirmonth)-1, 
         data = d.table4)
summary(m3)

m4 <- lm(zpostbargain ~ zpostgun + zpostnumppl + 
           zdriverage + zdriveredyears + zdriverspeaksaceh + 
           zdriveryearsexp + zdrivertrips + lnsal + factor(postdirmonth)-1, 
         data = d.table4)
summary(m4)

