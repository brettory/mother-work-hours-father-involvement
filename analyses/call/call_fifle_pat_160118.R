# father involvement in time flexible tasks, random slope of maternal employment, 
# With cross-level interaction of paternity leave


# if running directly from file and not sourcing:
# setwd("~/Dropbox/Fatherinvolv_jmf_s1/revise fatherinvol - Sociological Science/data")
# pacman::p_load(mcmcplots,mvtnorm,R2jags,rjags,coda,foreign,plyr,mice,Hmisc) 
# load("data/ggs.mf_011216.RData")


# load data
X <- subset(ggs.resp, select=c(country, fifle, hrwkMom.c, pat.c,
                               maleage.c, maleedu.c, femedu.c, numkid, 
                               anyunder4, female))
X <- X[order(X$country),]

# transform countries to integers
X$country2 <- mapvalues(X$country, from=c("Australia", "Austria", "Belgium", "Bulgaria", 
                                          "CzechRepublic", "Estonia", "France", "Georgia", 
                                          "Germany", "Hungary", "Italy", "Lithuania",  
                                          "Netherlands", "Norway", "Poland", "Romania",
                                          "Russia"),
                        to=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17))
X$country <- as.integer(X$country2)

# country 1 missing
#X <- X[!(X$country==1),]
#X$country <- mapvalues(X$country, from = c(2,3,4,5,6,7,8,9,10,11,12,13,14,15,16),
#                       to=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14, 15))

# remove cases missing country
X <- X[!is.na(X$country),]

# analysis won't run with missings on dependent variable, so impute with MICE
test <- mice(X, m=2 ) # this didn't work. try with complete cases
Y <- test$data # this is actually unimputed data... but for some reason it works with this data but not with X. Why?
# Y <- X

# sample size
J <- length(unique(Y$country)) # number of countries
N <- length(Y$fifle) # number of people

# amount of iterations and burn-in period
itt <- 10000
bi <- 1000





### input files JAGS ###
data <- list(ficon = Y$fifle, country = Y$country, hrwkMom = Y$hrwkMom.c, 
             mac = Y$pat.c, age = Y$maleage.c, edu = Y$maleedu.c, 
             femedu = Y$femedu.c, numkids = Y$numkid, under4 = Y$anyunder4, 
             female = Y$female, J = J, N = N)


inits1 <- list(tau.a = 1, tau.b = 1, tau.b1 = 1, tau.alpha = 1, 
               beta2 = 0, beta3 = 0, beta4 = 0, beta5 = 0, beta6 = 0,
               beta7 = 0, 
               gb0 = 1, gb1 = 1, 
               gamma0 = 0, gamma1 = 0)
inits2 <- list(tau.a = .1, tau.b = .1, tau.b1 = .1, tau.alpha = .1, 
               beta2 = 1, beta3 = 1, beta4 = 1, beta5 = 1, beta6 = 1,
               beta7 = 1, 
               gb0= 0, gb1 = 0,
               gamma0 = 1, gamma1 = 1)

inits <- list(inits1, inits2)

load.module("dic")

fifle_pat <- jags(data, inits, model.file = "analyses/model/model_mac_300615.R",
                  parameters  = c("alpha", 
                                  "beta1", "beta2", "beta3", "beta4", "beta5", 
                                  "beta6", "beta7",
                                  "gb0", "gb1",
                                  "gamma0", "gamma1",
                                  "sigma.b", "sigma.b1", "sigma.alpha"), 
                  n.chains = 2, n.iter = itt, n.burnin = bi, n.thin = 10)

save(fifle_pat, file="analyses/results/fifle_pat_160118.RData")
# load("analyses/results/fifle_pat_160118.RData")

# visual diagnoses
fifle_pat_mcmc <- as.mcmc(fifle_pat)
sum <- summary(fifle_pat_mcmc)
# traceplot(eqlsmi)
mcmcplot(fifle_pat_mcmc)


# maternal employment on father involvement
countries <- c("Australia", "Austria", "Belgium", "Bulgaria", "CzechRepublic", 
               "Estonia", "France", "Georgia", "Germany", "Hungary", "Italy", 
               "Lithuania", "Netherlands", "Norway", "Poland", "Romania", "Russia")
caterplot(fifle_pat_mcmc, parms = "beta1") # credible intervals plot


meansb1 <- as.data.frame(sum$statistics[c(18:34), 1])
# simple quantiles
# quants <- sum$quantiles[c(35:68), c(1,5)]
# colnames(quants) <- c("lower", "upper")
# HPD quantiles
quants12 <- HPDinterval(fifle_pat_mcmc)
quants1 <- quants12[[1]]
quants2 <- quants12[[2]]
quantsdf <- data.frame(quants1,quants2)
quantslower <- data.frame(rowMeans(quantsdf[,c(1,3)]))
quantsupper <- data.frame(rowMeans(quantsdf[c(2,4)]))
quants <- cbind.data.frame(quantslower,quantsupper)
quants$lower <- quants$rowMeans.quantsdf...c.1..3...
quants$rowMeans.quantsdf...c.1..3... <- NA
quants$upper <- quants$rowMeans.quantsdf.c.2..4...
quants$rowMeans.quantsdf.c.2..4... <- NA
quants <- quants[,c(3:4)]
quantsb1 <- quants[c(18:34),c(1,2)]


plot.datb1 <- as.data.frame(cbind(meansb1, quantsb1))
plot.datb1$means <- plot.datb1$`sum$statistics[c(18:34), 1]`
plot.datb1$`sum$statistics[c(18:34), 1]` <- NA
plot.datb1 <- plot.datb1[,c(2:4)]
# using data labels from dataset
plot.datb1$countries <- countries
# BETA1 ordering the values by size of effect
plot.datb1o <- plot.datb1[order(plot.datb1$means, decreasing=TRUE),]
plot.datb1o$countries <- reorder(plot.datb1o$countries, plot.datb1o$means)


rg <- diff(range(c(plot.datb1o$upper, plot.datb1o$lower)))

# graph beta1
png("analyses/results/graph_fifle_pat_b1_160118.png")
dotplot(countries ~ means, data=plot.datb1o ,scales=list(y=list(cex=.85)), xlim=c(min(plot.datb1o$lower)-.1*rg, max(plot.datb1o$upper)+.1*rg), xlab="effect", panel=function(x,y, subscripts){
  panel.abline(h = as.numeric(y), col = "gray80", lty = 10, v = 0)
  panel.segments(plot.datb1o$lower[subscripts], y, plot.datb1o$upper[subscripts], y, lty=1, col="gray40")
  panel.points(x,y, pch=16, col="black")})
dev.off()


# mean of beta1
mean(plot.datb1$means)
range(plot.datb1$means)
lower <- mean(plot.datb1$means) - 1.96*sd(plot.datb1$means)
upper <- mean(plot.datb1$means) + 1.96*sd(plot.datb1$means)
lower; upper

# table of results
coefficients <- (sum$statistics[c(18:40,42:48), 1])
quantiles <- (quants[c(18:40,42:48),c(1,2)])
analysisresults.fifle_pat <- as.data.frame(cbind(coefficients, quantiles))
analysisresults.fifle_pat$var <- c("hrwkMom.Austrlia", "hrwkMom.Austria", "hrwkMom.Belgium", "hrwkMom.Bulgaria", 
                                   "hrwkMom.CZ", "hrwkMom.Estonia", "hrwkMom.France", "hrwkMom.Georgia", 
                                   "hrwkMom.Germany", "hrwkMom.Hungary", "hrwkMom.Italy", 
                                   "hrwkMom.Lithuania", "hrwkMom.Netherlands", "hrwkMom.Norway", 
                                   "hrwkMom.Poland", "hrwkMom.Romania", "hrwkMom.Russia",
                                   "mom edu", "dad age", "dad edu", "number of kids", 
                                   "any kids under 4", "gender of respondent", 
                                   "intercept.country", "pat", "intercept beta1", 
                                   "hrwkMom * pat", "level2 var",
                                   "beta1 var", "level1 var")

save(analysisresults.fifle_pat, file="analyses/results/analysisresults.fifle_pat_160118.RData")
load("analyses/results/analysisresults.fifle_pat_160118.RData")
View(analysisresults.fifle_pat)

