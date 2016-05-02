start_t <- Sys.time()

library(quantstrat)
library(doMC)

stock.str <- "AAPL" # what are we trying it on

#MA parameters for MACD
fastMA <- 12
slowMA <- 26
signalMA <- 9
maType <- "EMA"
.FastMA <- (1:20)
.SlowMA <- (30:80)

currency("USD")
stock(stock.str, currency = "USD", multiplier = 1)

start_date <- "2006-12-31"
initEq <- 1000000
portfolio.st <- "macd"
account.st <- "macd"

rm.strat(portfolio.st)
rm.strat(account.st)

initPortf(portfolio.st, symbols = stock.str)
initAcct(account.st, portfolios = portfolio.st)
initOrders(portfolio = portfolio.st)

strat.st <- portfolio.st
# define the strategy
strategy(strat.st, store = TRUE)

#one indicator
add.indicator(strat.st,
              name = "MACD",
              arguments = list(x = quote(Cl(mktdata)),
                               nFast = fastMA,
                               nSlow = slowMA),
              label = "_")

#two signals
add.signal(strat.st,
           name = "sigThreshold",
           arguments = list(column = "signal._",
                            relationship = "gt",
                            threshold = 0,
                            cross = TRUE),
           label = "signal.gt.zero")

add.signal(strat.st,
           name = "sigThreshold",
           arguments = list(column = "signal._",
                            relationship = "lt",
                            threshold = 0,
                            cross = TRUE),
           label = "signal.lt.zero")

# add rules

# entry
add.rule(strat.st,
         name = "ruleSignal",
         arguments = list(sigcol = "signal.gt.zero",
                          sigval = TRUE,
                          orderqty = 100,
                          ordertype = "market",
                          orderside = "long",
                          threshold = NULL),
         type = "enter",
         label = "enter",
         storefun = FALSE)

# exit
add.rule(strat.st,
         name = "ruleSignal",
         arguments = list(sigcol = "signal.lt.zero",
                          sigval = TRUE,
                          orderqty = "all",
                          ordertype = "market",
                          orderside = "long",
                          threshold = NULL,
                          orderset = "exit2"),
         type = "exit",
         label = "exit")

### MA paramset

add.distribution(strat.st,
                 paramset.label = "MA",
                 component.type = "indicator",
                 component.label = "_", #this is the label given to the indicator in the strat
                 variable = list(n = .FastMA),
                 label = "nFAST")

add.distribution(strat.st,
                 paramset.label = "MA",
                 component.type = "indicator",
                 component.label = "_", #this is the label given to the indicator in the strat
                 variable = list(n = .SlowMA),
                 label = "nSLOW")

add.distribution.constraint(strat.st,
                            paramset.label = "MA",
                            distribution.label.1 = "nFAST",
                            distribution.label.2 = "nSLOW",
                            operator = "<",
                            label = "MA")

if( Sys.info()['sysname'] == "Windows") {
    library(doParallel)
    registerDoParallel(cores = parallel::detectCores())
} else {
    library(doMC)
    registerDoMC(cores = parallel::detectCores())
}

getSymbols(stock.str, from = start_date, to = "2014-06-01")

results <- apply.paramset(strat.st,
                          paramset.label = "MA",
                          portfolio.st = portfolio.st,
                          account.st = account.st,
                          nsamples = 0,
                          verbose = TRUE)

updatePortf(Portfolio = portfolio.st,Dates = paste("::",as.Date(Sys.time()),sep = ""))

end_t <- Sys.time()
print(end_t-start_t)
