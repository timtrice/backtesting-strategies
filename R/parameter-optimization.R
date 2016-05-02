library(quantstrat)

source("R/symbols.R")
source("R/functions.R")

portfolio.st <- "Port.Luxor.MA.Opt"
account.st <- "Acct.Luxor.MA.Opt"
strategy.st <- "Strat.Luxor.MA.Opt"
init_date <- "2007-12-31"
start_date <- "2008-01-01"
end_date <- "2009-12-31"
adjustment <- TRUE
init_equity <- 1e4 # $10,000
.fast <- 10
.slow <- 30
# .fastSMA <- (1:30)
# .slowSMA <- (20:80)
.fastSMA <- (1:30)
.slowSMA <- (20:80)
.threshold <- 0.0005
.txnfees <- -10
.orderqty <- 100
.nsamples <- 5

Sys.setenv(TZ = "UTC")

currency('USD')

symbols <- basic_symbols()

getSymbols(Symbols = symbols,
           src = "yahoo",
           index.class = "POSIXct",
           from = start_date,
           to = end_date,
           adjust = adjustment)

stock(symbols,
      currency = "USD",
      multiplier = 1)

rm.strat(portfolio.st)
rm.strat(account.st)

initPortf(name = portfolio.st,
          symbols = symbols,
          initDate = init_date)

initAcct(name = account.st,
         portfolios = portfolio.st,
         initDate = init_date,
         initEq = init_equity)

initOrders(portfolio = portfolio.st,
           symbols = symbols,
           initDate = init_date)

strategy(strategy.st, store = TRUE)

add.indicator(strategy = strategy.st,
              name = "SMA",
              arguments = list(x = quote(Cl(mktdata)[,1]),
                               n = .fast),
              label = "nFast")

add.indicator(strategy = strategy.st,
              name = "SMA",
              arguments = list(x = quote(Cl(mktdata)[,1]),
                               n = .slow),
              label = "nSlow")

add.signal(strategy = strategy.st,
           name="sigCrossover",
           arguments = list(columns = c("nFast", "nSlow"),
                            relationship = "gte"),
           label = "long")

add.signal(strategy = strategy.st,
           name="sigCrossover",
           arguments = list(columns = c("nFast", "nSlow"),
                            relationship = "lt"),
           label = "short")

add.rule(strategy = strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "long",
                          sigval = TRUE,
                          orderqty = .orderqty,
                          ordertype = "stoplimit",
                          orderside = "long",
                          threshold = -.threshold,
                          prefer = "High",
                          TxnFees = .txnfees,
                          replace = FALSE),
         type = "enter",
         label = "EnterLONG")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "short",
                          sigval = TRUE,
                          orderqty = -.orderqty,
                          ordertype = "stoplimit",
                          threshold = -.threshold,
                          orderside = "short",
                          replace = FALSE,
                          TxnFees = .txnfees,
                          prefer = "Low"),
         type = "enter",
         label = "EnterSHORT")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "short",
                          sigval = TRUE,
                          orderside = "long",
                          ordertype = "market",
                          orderqty = "all",
                          TxnFees = .txnfees,
                          replace = TRUE),
         type = "exit",
         label = "Exit2SHORT")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "long",
                          sigval = TRUE,
                          orderside = "short",
                          ordertype = "market",
                          orderqty = "all",
                          TxnFees = .txnfees,
                          replace = TRUE),
         type = "exit",
         label = "Exit2LONG")

add.distribution(strategy.st,
                 paramset.label = "SMA",
                 component.type = "indicator",
                 component.label = "nFast",
                 variable = list(n = .fastSMA),
                 label = "nFAST")

add.distribution(strategy.st,
                 paramset.label = "SMA",
                 component.type = "indicator",
                 component.label = "nSlow",
                 variable = list(n = .slowSMA),
                 label = "nSLOW")

add.distribution.constraint(strategy.st,
                            paramset.label = "SMA",
                            distribution.label.1 = "nFAST",
                            distribution.label.2 = "nSLOW",
                            operator = "<",
                            label = "SMA.Constraint")

library(parallel)

if( Sys.info()['sysname'] == "Windows") {
    library(doParallel)
    registerDoParallel(cores = detectCores())
} else {
    library(doMC)
    registerDoMC(cores = detectCores())
}

cwd <- getwd()
setwd("./_data/")
results_file <- paste("results", strategy.st, "RData", sep = ".")
if( file.exists(results_file) ) {
    load(results_file)
} else {
    results <- apply.paramset(strategy.st,
                              paramset.label = "SMA",
                              portfolio.st = portfolio.st,
                              account.st = account.st,
                              nsamples = .nsamples)
    updatePortf(portfolio.st)
    updateAcct(account.st)
    updateEndEq(account.st)
    if(checkBlotterUpdate(portfolio.st, account.st, verbose = TRUE)) {
        save(list = "results", file = results_file)
        save.strategy(strategy.st)
    }
}
setwd(cwd)
