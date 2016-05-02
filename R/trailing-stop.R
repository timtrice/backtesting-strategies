library(quantstrat)

source("R/symbols.R")
source("R/functions.R")

portfolio.st <- "Port.MACD.TS"
account.st <- "Acct.MACD.TS"
strategy.st <- "Strat.MACD.TS"
init_date <- "2007-12-31"
start_date <- "2008-01-01"
end_date <- "2009-12-31"
init_equity <- 1e5 # $100,000
trade_size <- init_equity/3 # Using 3 symbols
adjustment <- TRUE
trailingStopPercent <- 0.07

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
              name = "MACD",
              arguments = list(x = quote(Cl(mktdata))),
              label = "osc")

add.signal(strategy = strategy.st,
           name="sigThreshold",
           arguments = list(column ="signal.osc",
                            relationshipo = "gt",
                            threshold = 0,
                            cross = TRUE),
           label = "signal.gt.zero")

add.signal(strategy = strategy.st,
           name="sigThreshold",
           arguments = list(column = "signal.osc",
                            relationship = "lt",
                            threshold = 0,
                            cross = TRUE),
           label = "signal.lt.zero")

add.rule(strategy = strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "signal.gt.zero",
                          sigval = TRUE,
                          orderqty = 100,
                          orderside = "long",
                          ordertype = "market",
                          osFUN = "osFixedDollar",
                          orderset = "ocolong"),
         type = "enter",
         label = "LE")

add.rule(strategy = strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "signal.lt.zero",
                          sigval = TRUE,
                          replace = TRUE,
                          orderside = "long",
                          ordertype = "market",
                          orderqty = "all",
                          orderset = "ocolong"),
         type = "exit",
         label = "LX")

add.rule(strategy = strategy.st,
         name = "ruleSignal",
         arguments = list(sigcol = "signal.gt.zero",
                          sigval = TRUE,
                          replace = FALSE,
                          orderside = "long",
                          ordertype = "stoptrailing",
                          tmult = TRUE,
                          threshold = quote(trailingStopPercent),
                          orderqty = "all",
                          orderset = "ocolong"),
         type = "chain",
         parent = "LE",
         label = "StopTrailingLong",
         enabled = FALSE)

enable.rule(strategy.st, type = "chain", label = "StopTrailingLong")

cwd <- getwd()
setwd("./_data/")
results_file <- paste("results", strategy.st, "RData", sep = ".")
if( file.exists(results_file) ) {
    load(results_file)
} else {
    results <- applyStrategy(strategy.st, portfolios = portfolio.st)
    updatePortf(portfolio.st)
    updateAcct(account.st)
    updateEndEq(account.st)
    if(checkBlotterUpdate(portfolio.st, account.st, verbose = TRUE)) {
        save(list = "results", file = results_file)
        save.strategy(strategy.st)
    }
}
setwd(cwd)
