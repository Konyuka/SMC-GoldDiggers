//+------------------------------------------------------------------+
//|                                          SMC_GoldEA_Test.mq5 |
//|                        Test compilation of key fixes            |
//+------------------------------------------------------------------+
#property copyright "Test"
#property version   "1.00"

// Test the core fixes
struct CTrade_Simple
{
    ulong magic_number;
    uint deviation;
    ENUM_ORDER_TYPE_FILLING filling_type;
    bool async_mode;
    
    void SetExpertMagicNumber(ulong magic) { magic_number = magic; }
    void SetDeviationInPoints(uint dev) { deviation = dev; }
    void SetTypeFilling(ENUM_ORDER_TYPE_FILLING fill) { filling_type = fill; }
    void SetAsyncMode(bool async) { async_mode = async; }
    
    bool PositionClose(ulong ticket)
    {
        if (!PositionSelectByTicket(ticket))
            return false;
            
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.volume = PositionGetDouble(POSITION_VOLUME);
        request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                       SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                       SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        request.deviation = deviation;
        request.magic = magic_number;
        request.position = ticket;
        
        return OrderSend(request, result);
    }
    
    bool PositionModify(ulong ticket, double sl, double tp)
    {
        if (!PositionSelectByTicket(ticket))
            return false;
            
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_SLTP;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.sl = sl;
        request.tp = tp;
        request.position = ticket;
        
        return OrderSend(request, result);
    }
    
    bool PositionClosePartial(ulong ticket, double volume)
    {
        if (!PositionSelectByTicket(ticket))
            return false;
            
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.volume = volume;
        request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                       SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                       SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        request.deviation = deviation;
        request.magic = magic_number;
        request.position = ticket;
        
        return OrderSend(request, result);
    }
};

CTrade_Simple Trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Test EA initialized");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Test EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Test code with proper semicolon
    string comment = "test";
    
    if (true)
    {
        Print("Test successful");
    }
}
