checkBlotterUpdate <- function(port.st, account.st, verbose = TRUE)
{
    ok <- TRUE
    p <- getPortfolio(port.st)
    a <- getAccount(account.st)
    syms <- names(p$symbols)
    port.tot <- sum(sapply(syms,FUN = function(x) eval(parse(
        text=paste("sum(p$symbols",x,"posPL.USD$Net.Trading.PL)",sep="$")))))
    port.sum.tot <- sum(p$summary$Net.Trading.PL)
    if( !isTRUE(all.equal(port.tot,port.sum.tot)) ) {
        ok <- FALSE
        if( verbose )
            print("portfolio P&L doesn't match sum of symbols P&L")
    }
    initEq <- as.numeric(first(a$summary$End.Eq))
    endEq <- as.numeric(last(a$summary$End.Eq))
    if( !isTRUE(all.equal(port.tot,endEq-initEq)) ) {
        ok <- FALSE
        if( verbose )
            print("portfolio P&L doesn't match account P&L")
    }
    if( sum(duplicated(index(p$summary))) ) {
        ok <- FALSE
        if( verbose )
            print("duplicate timestamps in portfolio summary")
    }
    if( sum(duplicated(index(a$summary))) ) {
        ok <- FALSE
        if( verbose )
            print("duplicate timestamps in account summary")
    }
    return(ok)
}
