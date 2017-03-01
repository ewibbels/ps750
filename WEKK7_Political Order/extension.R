##################### Extension 1 #############

##############################
#######  use fix effect model  

kal.unaligneddummy.fix <- glm(kalofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
                              + total_dos
                              + electionyear 
                              + elf 
                              + lpop + lsqkm + cabinet+factor(division_str)-1,
                              data=dat.9298,family = "binomial")
summary(kal.unaligneddummy.fix)

######################################
####### only first half election year 
dat.avg.1997<- dat.avg[dat.avg$secondhalf == 0,]
kal.unaligneddummy.1997<- glm(kalofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
                              + total_dos
                              + elf 
                              + lpop + lsqkm + cabinet
                              , data=dat.avg.1997, family = "binomial")

summary(kal.unaligneddummy.1997)

############################
####### year 1993-1996 
dat.avg.9396<- dat[dat$year >= 1993 & dat$year < 1997,]

kal.unaligneddummy.9396 <- glm(kalofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
                               + total_dos
                               + elf 
                               + lpop + lsqkm + cabinet + factor(division_str)-1,
                               data=dat.avg.9396, family = "binomial")
summary(kal.unaligneddummy.9396)

####################################
########  fix effect in time series 
kik.unaligneddummy.fix <- glm(kikofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
                              + total_dos
                              + electionyear 
                              + elf 
                              + lpop + lsqkm + cabinet+factor(division_str)-1
                              , data=dat.9298, family ="binomial")
summary(kik.unaligneddummy.fix )

###################################################
######## only first half year at election year 1997 

kik.unaligneddummy.1997 <- glm(kikofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
                               + total_dos
                               + elf 
                               + lpop + lsqkm + cabinet
                               , data=dat.avg.1997, family = "binomial")
summary(kik.unaligneddummy.1997 )

################################
###### 1993-1996
kik.unaligneddummy.9396 <- glm(kikofficer ~ unalignedprovince + rvdummy + laggedvoteshare 
                               + total_dos
                               + elf 
                               + lpop + lsqkm + cabinet+factor(division_str)-1
                               , data=dat.avg.9396, family ="binomial")
summary(kik.unaligneddummy.9396 )

####### ########################
######### extension stagazer 
stargazer(kal.unaligneddummy.fix,kik.unaligneddummy.fix,kal.unaligneddummy.1997,kik.unaligneddummy.1997,kal.unaligneddummy.9396,kik.unaligneddummy.9396,
          title= "Extension", 
          dep.var.labels=c("Kalenjin","Kikuyu","Kalenjin 1997 First-half","Kikuyu 1997 First-half","Kalenjin 93-96","Kikuyu 93-96"),
          covariate.labels = c("UnalignedProvince","RiftValleyProvince","LaggedVoteShare","TotalOfficers",
                               "1997","ELF","lpop","lsqkm","Cabinet","Intercept"),
          keep=c(1:10),
          no.space=TRUE,
          omit.stat=c("adj.rsq","aic","ll","rsq","f","res.dev","bic"),digits=2,align=T)

#######################################
######## Extension 2: 2002 prediction
dat.avg.9802 <- dat[dat$year > 1997 & dat$year <= 2002,]
kal.interaction.2002 <- glm(kalofficer ~ unalignedprovince*moi_1997_vs  + rvdummy 
                            + total_dos
                            + electionyear 
                            + elf 
                            + lpop + lsqkm + cabinet + factor(division_str)-1
                            , data=dat.avg.9802, family ="binomial")

summary(kal.interaction.2002 )

dat.avg.2002 <- dat[dat$year == 2002,]
dat.avg.2002 <- dat.avg.2002[dat.avg.2002$avg_drop_indicator==1,]

kal.avg.interaction.2002 <- lm(total_dos_kal_9202_p ~ unalignedprovince*moi_1997_vs  + rvdummy 
                               + elf 
                               + lpop + lsqkm + cabinet_9802
                               , data=dat.avg.2002)
summary(kal.avg.interaction.2002)


kik.interaction.2002 <- glm(kikofficer ~ unalignedprovince*moi_1997_vs  + rvdummy 
                            + total_dos
                            + electionyear 
                            + elf 
                            + lpop + lsqkm + cabinet + factor(division_str)-1
                            , data=dat.avg.9802, family ="binomial")
summary(kik.interaction.2002 )


kik.avg.interaction.2002 <- lm(total_dos_kik_9202_p ~ unalignedprovince*moi_1997_vs
                               + rvdummy 
                               + elf 
                               + lpop + lsqkm + cabinet_9802
                               , data=dat.avg.2002)
summary(kik.avg.interaction.2002)



######################################
############ stagazer 2002 predication 

stargazer(kal.avg.interaction.2002,kal.interaction.2002, kik.avg.interaction.2002, kik.interaction.2002,
          title= "Extension 2", 
          dep.var.labels=c("Kalenjin Collapsed","Kalenjin Time-series","Kikuyu Collapsed","Kikuyu Time-series"),
          omit =c(12:247),
          covariate.labels = c("UnalignedProvince","LaggedVoteShare","RiftValleyProvince","TotalOfficers",
                               "2002","ELF","lpop","lsqkm","cabinet9802","Cabinet","UnalignedProvince × LaggedVoteShare","Intercept"),
          no.space=TRUE,
          omit.stat=c("adj.rsq","aic","ll","rsq","f","bic"),digits=2,align=T)
