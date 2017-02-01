###replication for the adverse effect of sunshine
#load the package
setwd("/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Updated Replication Files")
library(foreign)
library(stargazer)
library(interplot)
library(plm)
library(arm)
library(lmtest)
library(car)
library(multiwayvcov)
library(ggplot2)
library(ri)
#load the data
sunshine <- read.dta("/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Original Replication Files/electionresults_replication_public2.dta")

###histogram###
ggplot(data=sunshine, aes(internet_users100)) + geom_histogram()+
  geom_vline(xintercept = 1.51)+
  xlab("Internet subscribers per 100 citizens")+
  ylab("Number of observation")
ggsave(file="/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Updated Replication Files/distribution1.pdf")

###interaction effect plot
#subset the data
sunshine <- subset(sunshine, sunshine$session==6 & sunshine$politburo==0)
###question###
#run the model
m1 <- lm(dquestion_count ~ t2 * internet_users100 + centralnominated + fulltime + retirement +  city+ ln_gdpcap + ln_pop +transfer + south +unweighted , data=sunshine )
m1_cov<-cluster.vcov(question,sunshine$pci_id)
se1    <- sqrt(diag(m1_cov))
#draw the graph
interplot(m = m1, var1 = "t2", var2 ="internet_users100", hist = TRUE)+
  aes(color = "pink") + theme(legend.position="none") +  # geom_line(color = "pink") + 
  geom_hline(yintercept = 0, linetype = "dashed")+
    theme_bw()+  theme(legend.title=element_blank())
ggsave(file="/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Updated Replication Files/question.pdf")

###criticize###
#run the model
criticize <- lm(dcriticize_total_per ~ t2 * internet_users100 + centralnominated + fulltime + retirement +  city+ ln_gdpcap + ln_pop +transfer + south +unweighted , data=sunshine )
#draw the graph
interplot(m = criticize, var1 = "t2", var2 ="internet_users100", hist = TRUE)+
  aes(color = "pink") + theme(legend.position="none") +  # geom_line(color = "pink") + 
  geom_hline(yintercept = 0, linetype = "dashed")+
  theme_bw()+  theme(legend.title=element_blank())
ggsave(file="/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Updated Replication Files/criticize.pdf")


