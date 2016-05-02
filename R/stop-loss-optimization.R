library(quantstrat)
library(doMC)
registerDoMC(cores = parallel::detectCores())

portfolio.st <- "Port.Luxor.Stop.Loss.Opt"
account.st <- "Acct.Luxor.Stop.Loss.Opt"
strategy.st <- "Strat.Luxor.Stop.Loss.Opt"
init_date <- "2007-12-31"
start_date <- "2008-01-01"
end_date <- "2009-12-31"
init_equity <- 1e4 # $10,000
adjustment <- TRUE

.fast <- 10
.slow <- 30
.FastSMA <- (1:30)
.SlowSMA <- (20:80)
.threshold <- 0.0005
.orderqty <- 1000
.txnfees <- -10
.stoploss <- 0.003
.StopLoss <- seq(0.05, 0.6, length.out = 48)/100
.nsamples = 10

source("R/symbols.R")
source("R/functions.R")

Sys.setenv(TZ = "UTC")

currency('USD')

symbols <- basic_symbols()

getSymbols(Symbols = symbols,
           src = "yahoo",
           index.class = "POSIXct",
           from = start_date,
           to = end_date,
           adjust = adjustment)

stock(symbols, currency = "USD", multiplier = 1)

rm.strat(portfolio.st)
rm.strat(account.st)

initPortf(name = portfolio.st,
          symbols = symbols,
          initDate = init_date)

initAcct(name = account.st,
         portfolios = portfolio.st,
         initDate = init_date)

initOrders(portfolio = portfolio.st,
           initDate = init_date)

strategy(strategy.st, store = TRUE)

add.indicator(strategy.st,
              name = "SMA",
              arguments = list(x = quote(Cl(mktdata)[,1]),
                               n = .fast),
              label = "nFast")

add.indicator(strategy.st,
              name = "SMA",
              arguments = list(x = quote(Cl(mktdata)[,1]),
                               n = .slow),
              label = "nSlow")

add.signal(strategy.st,
           name = "sigCrossover",
           arguments = list(columns = c("nFast", "nSlow"),
                            relationship = "gte"),
           label = "long"
)
add.signal(strategy.st,
           name = "sigCrossover",
           arguments = list(columns = c("nFast", "nSlow"),
                            relationship = "lt"),
           label = "short")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "long" ,
                          sigval = TRUE,
                          replace = FALSE,
                          orderside = "long" ,
                          ordertype = "stoplimit",
                          prefer = "High",
                          threshold = .threshold,
                          TxnFees = .txnfees,
                          orderqty = +.orderqty,
                          osFUN = osMaxPos,
                          orderset = "ocolong"),
         type = "enter",
         label = "EnterLONG")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "short",
                          sigval = TRUE,
                          replace = FALSE,
                          orderside = "short",
                          ordertype = "stoplimit",
                          prefer = "Low",
                          threshold = .threshold,
                          TxnFees = .txnfees,
                          orderqty = -.orderqty,
                          osFUN = osMaxPos,
                          orderset = "ocoshort"),
         type = "enter",
         label = "EnterSHORT")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "short",
                          sigval = TRUE,
                          replace = TRUE,
                          orderside = "long" ,
                          ordertype = "market",
                          TxnFees = .txnfees,
                          orderqty = "all",
                          orderset = "ocolong"),
         type = "exit",
         label = "Exit2SHORT")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "long",
                          sigval = TRUE,
                          replace = TRUE,
                          orderside = "short",
                          ordertype = "market",
                          TxnFees = .txnfees,
                          orderqty = "all",
                          orderset = "ocoshort"),
         type = "exit",
         label = "Exit2LONG")

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "long" ,
                          sigval = TRUE,
                          replace = FALSE,
                          orderside = "long",
                          ordertype = "stoplimit",
                          tmult = TRUE,
                          threshold = quote(.stoploss),
                          TxnFees = .txnfees,
                          orderqty = "all",
                          orderset = "ocolong"),
         type = "chain",
         parent = "EnterLONG",
         label = "StopLossLONG",
         enabled = FALSE)

add.rule(strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "short",
                          sigval = TRUE,
                          replace = FALSE,
                          orderside = "short",
                          ordertype = "stoplimit",
                          tmult = TRUE,
                          threshold = quote(.stoploss),
                          TxnFees = .txnfees,
                          orderqty = "all",
                          orderset = "ocoshort"),
         type = "chain",
         parent = "EnterSHORT",
         label = "StopLossSHORT",
         enabled = FALSE)

for(symbol in symbols){
    addPosLimit(portfolio = portfolio.st,
                symbol = symbol,
                timestamp = init_date,
                maxpos = .orderqty)
}

add.distribution(strategy.st,
                 paramset.label = "StopLoss",
                 component.type = "chain",
                 component.label = "StopLossLONG",
                 variable = list(threshold = .StopLoss),
                 label = "StopLossLONG")

add.distribution(strategy.st,
                 paramset.label = "StopLoss",
                 component.type = "chain",
                 component.label = "StopLossSHORT",
                 variable = list(threshold = .StopLoss),
                 label = "StopLossSHORT")

add.distribution.constraint(strategy.st,
                            paramset.label = "StopLoss",
                            distribution.label.1 = "StopLossLONG",
                            distribution.label.2 = "StopLossSHORT",
                            operator = "==",
                            label = "StopLoss")

enable.rule(strategy.st, "chain", "StopLoss")

if( Sys.info()['sysname'] == "Windows") {
    library(doParallel)
    registerDoParallel(cores = parallel::detectCores())
} else {
    library(doMC)
    registerDoMC(cores = parallel::detectCores())
}

cwd <- getwd()
setwd("./_data/")
results_file <- paste("results", strategy.st, "RData", sep = ".")
if( file.exists(results_file) ) {
    load(results_file)
} else {
    results <- apply.paramset(strategy.st,
                              paramset.label = "StopLoss",
                              portfolio.st = portfolio.st,
                              account.st = account.st,
                              nsamples = .nsamples,
                              verbose = TRUE)
    updatePortf(portfolio.st)
    updateAcct(account.st)
    updateEndEq(account.st)

    if(checkBlotterUpdate(portfolio.st, account.st, verbose = TRUE)) {
        save(list = "results", file = results_file)
        save.strategy(strategy.st)
    }
}
setwd(cwd)
