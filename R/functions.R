library(quantstrat)

#' Basic Symbols
#'
#' IWM, QQQ, SPY and TLT for basic analysis
#'
#' @return a list of basic stock symbols
#' @export
#'
basic_symbols <- function() {
    symbols <- c(
        "IWM", # iShares Russell 2000 Index ETF
        "QQQ", # PowerShares QQQ TRust, Series 1 ETF
        "SPY", # SPDR S&P 500 ETF Trust
        "TLT" # iShares Barclays 20+ Yr Treas. Bond ETF
    )
}

#' Enhanced Symbols
#'
#' Includes SPDR ETFs
#'
#' @return a list of enhanced stock symbols
#' @export
#'
enhanced_symbols <- function() {
    symbols <- c(
        "IWM", # iShares Russell 2000 Index ETF
        "QQQ", # PowerShares QQQ TRust, Series 1 ETF
        "SPY", # SPDR S&P 500 ETF Trust
        "TLT", # iShares Barclays 20+ Yr Treas. Bond ETF
        "XLB", # Materials Select Sector SPDR ETF
        "XLE", # Energy Select Sector SPDR ETF
        "XLF", # Financial Select Sector SPDR ETF
        "XLI", # Industrials Select Sector SPDR ETF
        "XLK", # Technology  Select Sector SPDR ETF
        "XLP", # Consumer Staples  Select Sector SPDR ETF
        "XLU", # Utilities  Select Sector SPDR ETF
        "XLV", # Health Care  Select Sector SPDR ETF
        "XLY" # Consumer Discretionary  Select Sector SPDR ETF
    )
}

#' Global Symbols
#'
#' @return a list of global stock symbols
#' @export
#'
global_symbols <- function() {
    symbols <- c(
        "EFA", # iShares EAFE
        "EPP", # iShares Pacific Ex Japan
        "EWA", # iShares Australia
        "EWC", # iShares Canada
        "EWG", # iShares Germany
        "EWH", # iShares Hong Kong
        "EWJ", # iShares Japan
        "EWS", # iShares Singapore
        "EWT", # iShares Taiwan
        "EWU", # iShares UK
        "EWY", # iShares South Korea
        "EWZ", # iShares Brazil
        "EZU", # iShares MSCI EMU ETF
        "IGE", # iShares North American Natural Resources
        "IWM", # iShares Russell 2000 Index ETF
        "IYR", # iShares U.S. Real Estate
        "IYZ", # iShares U.S. Telecom
        "LQD", # iShares Investment Grade Corporate Bonds
        "QQQ", # PowerShares QQQ TRust, Series 1 ETF
        "SHY", # iShares 42372 year TBonds
        "SPY", # SPDR S&P 500 ETF Trust
        "TLT", # iShares Barclays 20+ Yr Treas. Bond ETF
        "XLB", # Materials Select Sector SPDR ETF
        "XLE", # Energy Select Sector SPDR ETF
        "XLF", # Financial Select Sector SPDR ETF
        "XLI", # Industrials Select Sector SPDR ETF
        "XLK", # Technology  Select Sector SPDR ETF
        "XLP", # Consumer Staples  Select Sector SPDR ETF
        "XLU", # Utilities  Select Sector SPDR ETF
        "XLV", # Health Care  Select Sector SPDR ETF
        "XLY" # Consumer Discretionary  Select Sector SPDR ETF
    )
}

#' Download symbols OHLCV
#'
#' Symbol OHLCV datasets are downloaded from \code{source} and saved as an rda
#'      file into the data directory. Existing data is overwritten.
#'
#' @param sym symbol to download
#' @param from_date Start date
#' @param to_date End date
#' @param source "yahoo"
#' @param adjustment adjust prices
#' @param warnings set warnings
#' @param auto.assign auto assign
#'
#' See quantmod::getSymbols for details on most of the parameters.
#'
#' @import data.table
#'
#' @export
#'
#' @examples
dl_symbols_ohlcv <- function(sym = NULL, from_date = "1900-01-01",
                             to_date = Sys.Date(), source = "yahoo",
                             adjustment = TRUE, warnings = FALSE,
                             auto.assign = FALSE) {

    if(is.null(sym)) stop("No symbol provided.")

    x <- data.table::as.data.table(
        quantmod::getSymbols(
            Symbols = sym,
            from = from_date,
            to = to_date, src = source,
            index.class = c("POSIXt",
                            "POSIXct"),
            adjust = adjustment,
            warnings = warnings,
            auto.assign = FALSE))

    names(x) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adj")

    assign(sym, x)
    do.call("save", list(sym,
                         file = paste0("data/", sym, ".rda", collapse = NULL)))
}


to_xts <- function(data){
    data.xts <- xts(data[,-1], order.by = as.POSIXct(data$Date))
    data.xts
}

pv <- list(
    source = "yahoo",
    account_equity = 10000,
    transaction_fees = -50,
    init_date = as.POSIXct(Sys.Date()),
    start_date = "1900-01-01",
    end_date = "2015-12-31",
    adjust = TRUE
)

currency('USD')
Sys.setenv(TZ = "UTC")
initEq <- pv$accountEquity

symbols <- basic_symbols()

getSymbols(symbols, src = pv$source, index.class = c("POSIXt", "POSIXct"),
           from = pv$start_date, to = pv$end_date, adjust = pv$adjust)

for(symbol in symbols) {
    stock(symbol, currency = "USD", multiplier = 1)
    x <- get(symbol)
    # x <- to.monthly(x, indexAt = "endof", drop.time = FALSE)
    indexFormat(x) <- "%Y-%m-%d"
    colnames(x) <- gsub("x", symbol, colnames(x))
    assign(symbol, x)
    # Set pv$init_date to one day prior to earliest date in all of symbols
    if(pv$init_date > min(index(x))) pv$init_date = min(index(x)) - 86400
}

