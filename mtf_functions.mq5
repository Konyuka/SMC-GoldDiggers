//+------------------------------------------------------------------+
//| Multi-Timeframe Trading Functions - Additional Implementation    |
//+------------------------------------------------------------------+

//--- Process dynamic trade management for all active trades
void ProcessDynamicTradeManagement()
{
    for (int i = 0; i < ActiveTradeCount; i++)
    {
        if (ActiveTrades[i].ticket == 0)
            continue;
            
        double profit_pips = ActiveTrades[i].current_profit_pips;
        
        // Quick profit capture for scalping
        if (profit_pips >= QuickProfitThreshold && !ActiveTrades[i].partial1_closed)
        {
            ClosePartialPosition(ActiveTrades[i].ticket, PartialClosePercent1);
            ActiveTrades[i].partial1_closed = true;
            Print("💰 Quick profit captured: ", profit_pips, " pips on ticket ", ActiveTrades[i].ticket);
        }
        
        // First partial close
        if (profit_pips >= ProfitLevel1 && !ActiveTrades[i].partial1_closed)
        {
            ClosePartialPosition(ActiveTrades[i].ticket, PartialClosePercent1);
            ActiveTrades[i].partial1_closed = true;
            Print("🎯 Partial close 1: ", ProfitLevel1, " pips reached on ticket ", ActiveTrades[i].ticket);
        }
        
        // Second partial close
        if (profit_pips >= ProfitLevel2 && !ActiveTrades[i].partial2_closed)
        {
            ClosePartialPosition(ActiveTrades[i].ticket, PartialClosePercent2);
            ActiveTrades[i].partial2_closed = true;
            Print("🎯 Partial close 2: ", ProfitLevel2, " pips reached on ticket ", ActiveTrades[i].ticket);
        }
        
        // Third partial close
        if (profit_pips >= ProfitLevel3 && !ActiveTrades[i].partial3_closed)
        {
            ClosePartialPosition(ActiveTrades[i].ticket, PartialClosePercent3);
            ActiveTrades[i].partial3_closed = true;
            Print("🎯 Partial close 3: ", ProfitLevel3, " pips reached on ticket ", ActiveTrades[i].ticket);
        }
        
        // Enable trailing stop
        if (EnableTrailingOnProfit && profit_pips >= MinProfitForTrailing && !ActiveTrades[i].trailing_active)
        {
            ActiveTrades[i].trailing_active = true;
            Print("🔄 Trailing activated on ticket ", ActiveTrades[i].ticket, " at ", profit_pips, " pips");
        }
    }
}

//--- Close partial position
void ClosePartialPosition(ulong ticket, double percent)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double current_volume = PositionGetDouble(POSITION_VOLUME);
    double close_volume = current_volume * percent / 100.0;
    
    // Normalize volume
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if (min_lot == 0) min_lot = 0.01;
    if (lot_step == 0) lot_step = 0.01;
    
    close_volume = MathMax(min_lot, MathRound(close_volume / lot_step) * lot_step);
    
    if (close_volume >= min_lot && close_volume < current_volume)
    {
        Trade.PositionClosePartial(ticket, close_volume);
    }
}

//--- Scan all timeframes for trading opportunities
void ScanMultiTimeframeOpportunities()
{
    static datetime last_scan = 0;
    
    // Scan every 30 seconds to avoid overload
    if (TimeCurrent() - last_scan < 30)
        return;
        
    last_scan = TimeCurrent();
    OpportunityCount = 0;
    
    // Scan each enabled timeframe
    for (int tf = 0; tf < 7; tf++)
    {
        if (!TimeframeEnabled[tf])
            continue;
            
        ENUM_TIMEFRAMES timeframe = TimeframeArray[tf];
        
        // Check if we can trade this timeframe (position limits)
        int current_positions = CountPositionsByTimeframe(tf);
        int max_positions = (tf <= 2) ? MaxSimultaneousScalps : MaxSimultaneousSwings; // M1, M5, M15 are scalping
        
        if (current_positions >= max_positions)
            continue;
            
        // Analyze opportunity on this timeframe
        TradingOpportunity opportunity = AnalyzeTimeframeOpportunity(timeframe, tf);
        
        if (opportunity.confluence_score >= MinConfluenceScore)
        {
            if (OpportunityCount < 50)
            {
                CurrentOpportunities[OpportunityCount] = opportunity;
                OpportunityCount++;
                
                Print("🔍 Opportunity found on ", EnumToString(timeframe), 
                      " - Score: ", opportunity.confluence_score,
                      " - Direction: ", (opportunity.direction == POSITION_TYPE_BUY) ? "BUY" : "SELL");
            }
        }
    }
}

//--- Count positions by timeframe
int CountPositionsByTimeframe(int timeframe_index)
{
    int count = 0;
    for (int i = 0; i < ActiveTradeCount; i++)
    {
        if (ActiveTrades[i].timeframe_index == timeframe_index)
            count++;
    }
    return count;
}

//--- Analyze opportunity on specific timeframe
TradingOpportunity AnalyzeTimeframeOpportunity(ENUM_TIMEFRAMES timeframe, int tf_index)
{
    TradingOpportunity opportunity;
    ZeroMemory(opportunity);
    
    opportunity.timeframe = timeframe;
    opportunity.signal_time = TimeCurrent();
    opportunity.is_scalping = (tf_index <= 2); // M1, M5, M15
    opportunity.is_swing = (tf_index >= 4);    // H1, H4, D1
    
    // Get market data for this timeframe
    double rsi_data[];
    double atr_data[];
    
    int rsi_handle = iRSI(_Symbol, timeframe, 14, PRICE_CLOSE);
    int atr_handle = iATR(_Symbol, timeframe, 14);
    
    if (CopyBuffer(rsi_handle, 0, 1, 1, rsi_data) > 0 && 
        CopyBuffer(atr_handle, 0, 1, 1, atr_data) > 0)
    {
        double rsi = rsi_data[0];
        double atr = atr_data[0];
        
        // Calculate confluence score
        int score = 0;
        
        // RSI signals
        if (rsi < 30) { score += 3; opportunity.direction = POSITION_TYPE_BUY; }
        if (rsi > 70) { score += 3; opportunity.direction = POSITION_TYPE_SELL; }
        if (rsi < 25 || rsi > 75) score += 2; // Strong oversold/overbought
        
        // Volatility check
        double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double atr_percent = (atr / current_price) * 100;
        if (atr_percent > 0.3 && atr_percent < 1.0) score += 1; // Good volatility
        
        // Time-based scoring (kill zones)
        int hour = TimeHour(TimeCurrent());
        if ((hour >= 7 && hour <= 10) || (hour >= 13 && hour <= 16)) score += 1; // London/NY kill zones
        
        // Timeframe specific scoring
        if (opportunity.is_scalping && rsi != 50) score += 1; // Any momentum for scalping
        if (opportunity.is_swing && (rsi < 35 || rsi > 65)) score += 2; // Stronger signals for swing
        
        opportunity.confluence_score = score;
        
        // Set prices
        if (opportunity.direction == POSITION_TYPE_BUY)
        {
            opportunity.entry_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            opportunity.sl_price = opportunity.entry_price - (atr * 2);
            opportunity.tp_price = opportunity.entry_price + (atr * (opportunity.is_scalping ? 1.5 : 4));
        }
        else if (opportunity.direction == POSITION_TYPE_SELL)
        {
            opportunity.entry_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            opportunity.sl_price = opportunity.entry_price + (atr * 2);
            opportunity.tp_price = opportunity.entry_price - (atr * (opportunity.is_scalping ? 1.5 : 4));
        }
        
        opportunity.signal_source = "Multi-TF RSI+ATR";
    }
    
    // Clean up handles
    if (rsi_handle != INVALID_HANDLE) IndicatorRelease(rsi_handle);
    if (atr_handle != INVALID_HANDLE) IndicatorRelease(atr_handle);
    
    return opportunity;
}

//--- Execute the best opportunities found
void ExecuteBestOpportunities()
{
    if (OpportunityCount == 0)
        return;
        
    // Sort opportunities by confluence score
    for (int i = 0; i < OpportunityCount - 1; i++)
    {
        for (int j = i + 1; j < OpportunityCount; j++)
        {
            if (CurrentOpportunities[j].confluence_score > CurrentOpportunities[i].confluence_score)
            {
                TradingOpportunity temp = CurrentOpportunities[i];
                CurrentOpportunities[i] = CurrentOpportunities[j];
                CurrentOpportunities[j] = temp;
            }
        }
    }
    
    // Execute top opportunities (limit to avoid overtrading)
    int trades_executed = 0;
    int max_trades_per_scan = 2;
    
    for (int i = 0; i < OpportunityCount && trades_executed < max_trades_per_scan; i++)
    {
        TradingOpportunity opp = CurrentOpportunities[i];
        
        if (opp.confluence_score >= MinConfluenceScore)
        {
            // Check total position limits
            if (PositionsTotal() >= MaxSimultaneousPositions)
                break;
                
            // Get timeframe index
            int tf_index = -1;
            for (int j = 0; j < 7; j++)
            {
                if (TimeframeArray[j] == opp.timeframe)
                {
                    tf_index = j;
                    break;
                }
            }
            
            if (tf_index >= 0)
            {
                bool success = ExecuteMultiTimeframeOrder(opp, tf_index);
                if (success)
                {
                    trades_executed++;
                    LastTradeTime[tf_index] = TimeCurrent();
                }
            }
        }
    }
}

//--- Execute order based on multi-timeframe opportunity
bool ExecuteMultiTimeframeOrder(TradingOpportunity &opportunity, int tf_index)
{
    // Calculate position size based on timeframe risk
    double risk_percent = RiskByTimeframe[tf_index];
    double sl_pips = MathAbs(opportunity.entry_price - opportunity.sl_price) / PointMultiplier;
    
    double risk_amount = AccountInfoDouble(ACCOUNT_BALANCE) * risk_percent / 100.0;
    double sl_value = sl_pips * PointMultiplier;
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tick_value == 0) tick_value = 0.1;
    
    double lot_size = risk_amount / (sl_value * tick_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    if (min_lot == 0) min_lot = 0.01;
    if (max_lot == 0) max_lot = 100.0;
    if (lot_step == 0) lot_step = 0.01;
    
    lot_size = MathMax(min_lot, MathMin(max_lot, MathRound(lot_size / lot_step) * lot_step));
    
    // Create trade comment
    string comment = TradeComment + "-" + EnumToString(opportunity.timeframe) + "-Score" + IntegerToString(opportunity.confluence_score);
    
    bool success = false;
    
    if (opportunity.direction == POSITION_TYPE_BUY)
    {
        success = Trade.Buy(lot_size, _Symbol, opportunity.entry_price, opportunity.sl_price, opportunity.tp_price, comment);
        if (success)
        {
            Print("✅ Multi-TF BUY executed: ", EnumToString(opportunity.timeframe), 
                  " | Lots: ", lot_size, " | Score: ", opportunity.confluence_score,
                  " | Entry: ", opportunity.entry_price, " | SL: ", opportunity.sl_price, " | TP: ", opportunity.tp_price);
        }
    }
    else if (opportunity.direction == POSITION_TYPE_SELL)
    {
        success = Trade.Sell(lot_size, _Symbol, opportunity.entry_price, opportunity.sl_price, opportunity.tp_price, comment);
        if (success)
        {
            Print("✅ Multi-TF SELL executed: ", EnumToString(opportunity.timeframe), 
                  " | Lots: ", lot_size, " | Score: ", opportunity.confluence_score,
                  " | Entry: ", opportunity.entry_price, " | SL: ", opportunity.sl_price, " | TP: ", opportunity.tp_price);
        }
    }
    
    return success;
}
