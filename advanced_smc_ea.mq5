//+------------------------------------------------------------------+
//|                                        Advanced_SMC_Gold_EA.mq5 |
//|                   Copyright 2024, Multi-Timeframe Smart Trading |
//|                                       https://www.luxalgo.com/   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Multi-Timeframe Smart Trading"
#property link "https://www.luxalgo.com/"
#property version "4.00"
#property description "Advanced Multi-Timeframe Gold EA with Dynamic Trade Management"
#property description "Scalps minutes, holds positions, analyzes all timeframes"

//--- Input Parameters
input group "═════════ BASIC SETTINGS ═════════"
input int MagicNumber = 20241225;                                                     // EA Magic Number
input string TradeComment = "Advanced-SMC-Gold";                                      // Trade comment
input double DefaultRiskPercent = 0.5;                                                // Default risk per trade

input group "═════════ MULTI-TIMEFRAME TRADING ═════════"
input bool EnableMultiTimeframeAnalysis = true;                                       // Enable advanced multi-timeframe analysis
input bool EnableDynamicTradeManagement = true;                                       // Enable dynamic trade management
input bool EnableOpportunityScanning = true;                                          // Scan all timeframes for opportunities
input int MaxSimultaneousScalps = 8;                                                  // Maximum scalping trades
input int MaxSimultaneousSwings = 4;                                                  // Maximum swing trades
input int MaxSimultaneousPositions = 20;                                              // Total maximum positions

input group "═════════ TIMEFRAME CONFIGURATION ═════════"
input bool TradeM1 = true;                                                            // Trade on M1 (ultra-scalping)
input bool TradeM5 = true;                                                            // Trade on M5 (scalping)
input bool TradeM15 = true;                                                           // Trade on M15 (short-term)
input bool TradeM30 = true;                                                           // Trade on M30 (medium-term)
input bool TradeH1 = true;                                                            // Trade on H1 (swing)
input bool TradeH4 = true;                                                            // Trade on H4 (position)
input bool TradeD1 = true;                                                            // Trade on D1 (long-term)

input group "═════════ DYNAMIC PROFIT MANAGEMENT ═════════"
input bool EnablePartialProfitTaking = true;                                          // Enable partial profit taking
input double QuickProfitThreshold = 30;                                               // Quick profit threshold (pips) - scalp exit
input double PartialClosePercent1 = 25.0;                                             // First partial close %
input double PartialClosePercent2 = 50.0;                                             // Second partial close %
input double PartialClosePercent3 = 75.0;                                             // Third partial close %
input double ProfitLevel1 = 50;                                                       // Profit level 1 (pips)
input double ProfitLevel2 = 150;                                                      // Profit level 2 (pips)
input double ProfitLevel3 = 300;                                                      // Profit level 3 (pips)
input bool EnableTrailingOnProfit = true;                                             // Enable trailing on profit
input double MinProfitForTrailing = 40;                                               // Minimum profit to start trailing

input group "═════════ TIMEFRAME-SPECIFIC RISK ═════════"
input double M1_RiskPercent = 0.05;                                                   // Risk per M1 trade
input double M5_RiskPercent = 0.1;                                                    // Risk per M5 trade
input double M15_RiskPercent = 0.15;                                                  // Risk per M15 trade
input double M30_RiskPercent = 0.2;                                                   // Risk per M30 trade
input double H1_RiskPercent = 0.3;                                                    // Risk per H1 trade
input double H4_RiskPercent = 0.5;                                                    // Risk per H4 trade
input double D1_RiskPercent = 0.8;                                                    // Risk per D1 trade

input group "═════════ INTELLIGENT ENTRY/EXIT ═════════"
input bool EnableMarketStructureSync = true;                                          // Sync all TF market structure
input bool EnableConfluentEntries = true;                                             // Only trade confluent setups
input bool EnableDynamicSL = true;                                                    // Dynamic stop loss based on structure
input bool EnableDynamicTP = true;                                                    // Dynamic take profit based on structure
input int MinConfluenceScore = 2;                                                     // Minimum confluence score (1-10)
input bool EnableCascadingOrders = true;                                              // Enable cascading order entries
input bool EnableInstantProfitCapture = true;                                         // Capture profits instantly when possible

input group "═════════ SCALPING SETTINGS ═════════"
input int ScalpingTargetPips = 15;                                                    // Scalping target (pips)
input int ScalpingStopPips = 25;                                                      // Scalping stop loss (pips)
input int MinProfitToClose = 8;                                                       // Minimum profit to close scalp (pips)
input bool EnableNews避Scalping = true;                                               // Avoid scalping during news
input int MaxScalpTimeMinutes = 15;                                                   // Maximum time to hold scalp (minutes)

//--- Enhanced Global Variables
double PointMultiplier;
int ATR_Handle, RSI_Handle;
datetime LastTradeTime[7]; // For each timeframe
int PositionCountByTimeframe[7];

// Timeframe array for multi-TF analysis
ENUM_TIMEFRAMES TimeframeArray[7] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
bool TimeframeEnabled[7];
double RiskByTimeframe[7];

// Trade management
struct TradeInfo
{
    ulong ticket;
    ENUM_TIMEFRAMES timeframe;
    datetime open_time;
    double open_price;
    double current_profit_pips;
    bool partial1_closed;
    bool partial2_closed;
    bool partial3_closed;
    bool trailing_active;
    ENUM_POSITION_TYPE type;
};

TradeInfo ActiveTrades[50]; // Track up to 50 positions
int ActiveTradeCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("═══════════════════════════════════════════════════");
    Print("    Advanced Multi-Timeframe SMC Gold EA Starting");
    Print("═══════════════════════════════════════════════════");

    //--- Calculate point multiplier for XAUUSD
    PointMultiplier = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
    Print("Point Multiplier: ", PointMultiplier);

    //--- Initialize timeframe settings
    TimeframeEnabled[0] = TradeM1;
    TimeframeEnabled[1] = TradeM5;
    TimeframeEnabled[2] = TradeM15;
    TimeframeEnabled[3] = TradeM30;
    TimeframeEnabled[4] = TradeH1;
    TimeframeEnabled[5] = TradeH4;
    TimeframeEnabled[6] = TradeD1;

    RiskByTimeframe[0] = M1_RiskPercent;
    RiskByTimeframe[1] = M5_RiskPercent;
    RiskByTimeframe[2] = M15_RiskPercent;
    RiskByTimeframe[3] = M30_RiskPercent;
    RiskByTimeframe[4] = H1_RiskPercent;
    RiskByTimeframe[5] = H4_RiskPercent;
    RiskByTimeframe[6] = D1_RiskPercent;

    //--- Create essential indicators
    ATR_Handle = iATR(_Symbol, PERIOD_H1, 14);
    RSI_Handle = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);

    if (ATR_Handle == INVALID_HANDLE || RSI_Handle == INVALID_HANDLE)
    {
        Print("❌ Error creating indicator handles!");
        return INIT_FAILED;
    }

    //--- Initialize arrays
    ArrayInitialize(LastTradeTime, 0);
    ArrayInitialize(PositionCountByTimeframe, 0);
    
    //--- Initialize trade tracking
    for (int i = 0; i < 50; i++)
    {
        ActiveTrades[i].ticket = 0;
    }

    Print("✅ Advanced EA initialized successfully");
    Print("🔥 Multi-Timeframe Analysis: ", (EnableMultiTimeframeAnalysis ? "ENABLED" : "DISABLED"));
    Print("📊 Dynamic Trade Management: ", (EnableDynamicTradeManagement ? "ENABLED" : "DISABLED"));
    Print("🎯 Opportunity Scanning: ", (EnableOpportunityScanning ? "ENABLED" : "DISABLED"));
    Print("⚡ Instant Profit Capture: ", (EnableInstantProfitCapture ? "ENABLED" : "DISABLED"));

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("📴 Advanced EA shutting down. Reason: ", reason);
    
    if (ATR_Handle != INVALID_HANDLE) IndicatorRelease(ATR_Handle);
    if (RSI_Handle != INVALID_HANDLE) IndicatorRelease(RSI_Handle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Update active trades tracking
    UpdateActiveTradesTracking();
    
    //--- Dynamic trade management (highest priority)
    if (EnableDynamicTradeManagement)
    {
        ManageActiveTrades();
    }

    //--- Multi-timeframe opportunity scanning
    if (EnableOpportunityScanning)
    {
        ScanAllTimeframesForOpportunities();
    }
    
    //--- Instant profit capture for scalps
    if (EnableInstantProfitCapture)
    {
        CaptureInstantProfits();
    }
}

//+------------------------------------------------------------------+
//| Update Active Trades Tracking                                    |
//+------------------------------------------------------------------+
void UpdateActiveTradesTracking()
{
    ActiveTradeCount = 0;
    ArrayInitialize(PositionCountByTimeframe, 0);
    
    // Reset all active trades
    for (int i = 0; i < 50; i++)
    {
        ActiveTrades[i].ticket = 0;
    }
    
    // Update from current positions
    for (int i = 0; i < PositionsTotal(); i++)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol == "" || PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
            
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        string comment = PositionGetString(POSITION_COMMENT);
        double profit = PositionGetDouble(POSITION_PROFIT);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double current_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                              SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                              SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        // Calculate profit in pips
        double profit_pips = 0;
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            profit_pips = (current_price - open_price) / PointMultiplier;
        else
            profit_pips = (open_price - current_price) / PointMultiplier;
            
        // Store trade info
        if (ActiveTradeCount < 50)
        {
            ActiveTrades[ActiveTradeCount].ticket = ticket;
            ActiveTrades[ActiveTradeCount].open_price = open_price;
            ActiveTrades[ActiveTradeCount].current_profit_pips = profit_pips;
            ActiveTrades[ActiveTradeCount].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            ActiveTrades[ActiveTradeCount].open_time = (datetime)PositionGetInteger(POSITION_TIME);
            
            // Determine timeframe from comment
            ActiveTrades[ActiveTradeCount].timeframe = GetTimeframeFromComment(comment);
            
            // Update timeframe counters
            int tf_index = GetTimeframeIndex(ActiveTrades[ActiveTradeCount].timeframe);
            if (tf_index >= 0 && tf_index < 7)
                PositionCountByTimeframe[tf_index]++;
                
            ActiveTradeCount++;
        }
    }
}

//+------------------------------------------------------------------+
//| Manage Active Trades                                             |
//+------------------------------------------------------------------+
void ManageActiveTrades()
{
    for (int i = 0; i < ActiveTradeCount; i++)
    {
        if (ActiveTrades[i].ticket == 0) continue;
        
        // Quick profit capture for scalps
        if (IsScalpingTimeframe(ActiveTrades[i].timeframe))
        {
            ManageScalpingTrade(i);
        }
        else
        {
            ManageSwingTrade(i);
        }
    }
}

//+------------------------------------------------------------------+
//| Manage Scalping Trade                                            |
//+------------------------------------------------------------------+
void ManageScalpingTrade(int trade_index)
{
    TradeInfo &trade = ActiveTrades[trade_index];
    
    // Quick exit if profitable
    if (trade.current_profit_pips >= MinProfitToClose)
    {
        // Check if we should close based on time
        datetime current_time = TimeCurrent();
        int minutes_open = (int)((current_time - trade.open_time) / 60);
        
        if (minutes_open >= MaxScalpTimeMinutes || trade.current_profit_pips >= ScalpingTargetPips)
        {
            ClosePosition(trade.ticket, "SCALP-PROFIT");
            Print("💰 SCALP CLOSED: Ticket ", trade.ticket, " | Profit: ", 
                  DoubleToString(trade.current_profit_pips, 1), " pips | Time: ", minutes_open, "min");
            return;
        }
    }
    
    // Instant profit capture for very quick moves
    if (EnableInstantProfitCapture && trade.current_profit_pips >= QuickProfitThreshold)
    {
        ClosePosition(trade.ticket, "INSTANT-PROFIT");
        Print("⚡ INSTANT PROFIT: Ticket ", trade.ticket, " | Profit: ", 
              DoubleToString(trade.current_profit_pips, 1), " pips");
    }
}

//+------------------------------------------------------------------+
//| Manage Swing Trade                                               |
//+------------------------------------------------------------------+
void ManageSwingTrade(int trade_index)
{
    TradeInfo &trade = ActiveTrades[trade_index];
    
    if (!EnablePartialProfitTaking) return;
    
    // Partial profit taking
    if (trade.current_profit_pips >= ProfitLevel1 && !trade.partial1_closed)
    {
        PartialClosePosition(trade.ticket, PartialClosePercent1, "PARTIAL-1");
        trade.partial1_closed = true;
        Print("📊 PARTIAL CLOSE 1: Ticket ", trade.ticket, " | ", PartialClosePercent1, "% at ", 
              DoubleToString(trade.current_profit_pips, 1), " pips");
    }
    
    if (trade.current_profit_pips >= ProfitLevel2 && !trade.partial2_closed)
    {
        PartialClosePosition(trade.ticket, PartialClosePercent2, "PARTIAL-2");
        trade.partial2_closed = true;
        Print("📊 PARTIAL CLOSE 2: Ticket ", trade.ticket, " | ", PartialClosePercent2, "% at ", 
              DoubleToString(trade.current_profit_pips, 1), " pips");
    }
    
    if (trade.current_profit_pips >= ProfitLevel3 && !trade.partial3_closed)
    {
        PartialClosePosition(trade.ticket, PartialClosePercent3, "PARTIAL-3");
        trade.partial3_closed = true;
        Print("📊 PARTIAL CLOSE 3: Ticket ", trade.ticket, " | ", PartialClosePercent3, "% at ", 
              DoubleToString(trade.current_profit_pips, 1), " pips");
    }
    
    // Start trailing
    if (EnableTrailingOnProfit && trade.current_profit_pips >= MinProfitForTrailing && !trade.trailing_active)
    {
        trade.trailing_active = true;
        Print("🔄 TRAILING STARTED: Ticket ", trade.ticket, " at ", 
              DoubleToString(trade.current_profit_pips, 1), " pips profit");
    }
}

//+------------------------------------------------------------------+
//| Scan All Timeframes for Opportunities                           |
//+------------------------------------------------------------------+
void ScanAllTimeframesForOpportunities()
{
    static datetime last_scan = 0;
    if (TimeCurrent() - last_scan < 5) return; // Scan every 5 seconds
    
    for (int tf = 0; tf < 7; tf++)
    {
        if (!TimeframeEnabled[tf]) continue;
        if (PositionCountByTimeframe[tf] >= GetMaxPositionsForTimeframe(TimeframeArray[tf])) continue;
        
        // Analyze this timeframe for opportunities
        AnalyzeTimeframeOpportunity(TimeframeArray[tf], tf);
    }
    
    last_scan = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Analyze Timeframe Opportunity                                    |
//+------------------------------------------------------------------+
void AnalyzeTimeframeOpportunity(ENUM_TIMEFRAMES timeframe, int tf_index)
{
    // Prevent overtrading on same timeframe
    if (TimeCurrent() - LastTradeTime[tf_index] < GetMinTimeBetweenTrades(timeframe))
        return;
    
    // Get market conditions for this timeframe
    double rsi_buffer[];
    if (CopyBuffer(RSI_Handle, 0, 1, 1, rsi_buffer) <= 0) return;
    
    double atr_buffer[];
    if (CopyBuffer(ATR_Handle, 0, 1, 1, atr_buffer) <= 0) return;
    
    double rsi = rsi_buffer[0];
    double atr = atr_buffer[0];
    
    // Get confluence score
    int confluence = CalculateConfluenceScore(timeframe, rsi, atr);
    
    if (confluence < MinConfluenceScore) return;
    
    // Trading logic based on timeframe
    if (IsScalpingTimeframe(timeframe))
    {
        ExecuteScalpingLogic(timeframe, tf_index, rsi, atr, confluence);
    }
    else
    {
        ExecuteSwingLogic(timeframe, tf_index, rsi, atr, confluence);
    }
}

//+------------------------------------------------------------------+
//| Execute Scalping Logic                                           |
//+------------------------------------------------------------------+
void ExecuteScalpingLogic(ENUM_TIMEFRAMES timeframe, int tf_index, double rsi, double atr, int confluence)
{
    MqlTick tick;
    if (!SymbolInfoTick(_Symbol, tick)) return;
    
    // Scalping conditions (aggressive)
    bool buy_signal = (rsi < 45 && rsi > 25) || (confluence >= 4);
    bool sell_signal = (rsi > 55 && rsi < 75) || (confluence >= 4);
    
    if (buy_signal && PositionCountByTimeframe[tf_index] < MaxSimultaneousScalps)
    {
        ExecuteScalpTrade(ORDER_TYPE_BUY, timeframe, tf_index, tick.ask, confluence);
    }
    
    if (sell_signal && PositionCountByTimeframe[tf_index] < MaxSimultaneousScalps)
    {
        ExecuteScalpTrade(ORDER_TYPE_SELL, timeframe, tf_index, tick.bid, confluence);
    }
}

//+------------------------------------------------------------------+
//| Execute Swing Logic                                              |
//+------------------------------------------------------------------+
void ExecuteSwingLogic(ENUM_TIMEFRAMES timeframe, int tf_index, double rsi, double atr, int confluence)
{
    MqlTick tick;
    if (!SymbolInfoTick(_Symbol, tick)) return;
    
    // Swing conditions (more selective)
    bool buy_signal = (rsi < 35) && (confluence >= MinConfluenceScore);
    bool sell_signal = (rsi > 65) && (confluence >= MinConfluenceScore);
    
    if (buy_signal && PositionCountByTimeframe[tf_index] < MaxSimultaneousSwings)
    {
        ExecuteSwingTrade(ORDER_TYPE_BUY, timeframe, tf_index, tick.ask, confluence);
    }
    
    if (sell_signal && PositionCountByTimeframe[tf_index] < MaxSimultaneousSwings)
    {
        ExecuteSwingTrade(ORDER_TYPE_SELL, timeframe, tf_index, tick.bid, confluence);
    }
}

//+------------------------------------------------------------------+
//| Execute Scalp Trade                                              |
//+------------------------------------------------------------------+
void ExecuteScalpTrade(ENUM_ORDER_TYPE type, ENUM_TIMEFRAMES timeframe, int tf_index, double price, int confluence)
{
    double lot_size = CalculateLotSize(RiskByTimeframe[tf_index], ScalpingStopPips);
    double sl, tp;
    
    if (type == ORDER_TYPE_BUY)
    {
        sl = price - (ScalpingStopPips * PointMultiplier);
        tp = price + (ScalpingTargetPips * PointMultiplier);
    }
    else
    {
        sl = price + (ScalpingStopPips * PointMultiplier);
        tp = price - (ScalpingTargetPips * PointMultiplier);
    }
    
    string comment = TradeComment + "-SCALP-" + TimeframeToString(timeframe) + "-C" + IntegerToString(confluence);
    
    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = type;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = MagicNumber;
    request.comment = comment;
    
    if (OrderSend(request, result))
    {
        LastTradeTime[tf_index] = TimeCurrent();
        string direction = (type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
        Print("⚡ SCALP ", direction, " EXECUTED:");
        Print("   📊 TF: ", TimeframeToString(timeframe), " | Confluence: ", confluence);
        Print("   💰 Entry: ", DoubleToString(price, _Digits));
        Print("   🎯 Target: ", ScalpingTargetPips, " pips | Stop: ", ScalpingStopPips, " pips");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2), " | Ticket: ", result.order);
    }
}

//+------------------------------------------------------------------+
//| Execute Swing Trade                                              |
//+------------------------------------------------------------------+
void ExecuteSwingTrade(ENUM_ORDER_TYPE type, ENUM_TIMEFRAMES timeframe, int tf_index, double price, int confluence)
{
    double lot_size = CalculateLotSize(RiskByTimeframe[tf_index], 200); // 200 pip stop for swings
    double sl, tp;
    
    if (type == ORDER_TYPE_BUY)
    {
        sl = price - (200 * PointMultiplier);
        tp = price + (600 * PointMultiplier); // 3:1 R:R
    }
    else
    {
        sl = price + (200 * PointMultiplier);
        tp = price - (600 * PointMultiplier);
    }
    
    string comment = TradeComment + "-SWING-" + TimeframeToString(timeframe) + "-C" + IntegerToString(confluence);
    
    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = type;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.magic = MagicNumber;
    request.comment = comment;
    
    if (OrderSend(request, result))
    {
        LastTradeTime[tf_index] = TimeCurrent();
        string direction = (type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
        Print("📈 SWING ", direction, " EXECUTED:");
        Print("   📊 TF: ", TimeframeToString(timeframe), " | Confluence: ", confluence);
        Print("   💰 Entry: ", DoubleToString(price, _Digits));
        Print("   🎯 Target: 600 pips | Stop: 200 pips");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2), " | Ticket: ", result.order);
    }
}

//+------------------------------------------------------------------+
//| Capture Instant Profits                                          |
//+------------------------------------------------------------------+
void CaptureInstantProfits()
{
    for (int i = 0; i < ActiveTradeCount; i++)
    {
        if (ActiveTrades[i].ticket == 0) continue;
        
        // For scalps, capture quick profits
        if (IsScalpingTimeframe(ActiveTrades[i].timeframe))
        {
            if (ActiveTrades[i].current_profit_pips >= QuickProfitThreshold)
            {
                ClosePosition(ActiveTrades[i].ticket, "QUICK-PROFIT");
                Print("⚡ QUICK PROFIT CAPTURED: ", DoubleToString(ActiveTrades[i].current_profit_pips, 1), " pips");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
bool IsScalpingTimeframe(ENUM_TIMEFRAMES tf)
{
    return (tf == PERIOD_M1 || tf == PERIOD_M5 || tf == PERIOD_M15);
}

int GetTimeframeIndex(ENUM_TIMEFRAMES tf)
{
    for (int i = 0; i < 7; i++)
    {
        if (TimeframeArray[i] == tf) return i;
    }
    return -1;
}

ENUM_TIMEFRAMES GetTimeframeFromComment(string comment)
{
    if (StringFind(comment, "M1") >= 0) return PERIOD_M1;
    if (StringFind(comment, "M5") >= 0) return PERIOD_M5;
    if (StringFind(comment, "M15") >= 0) return PERIOD_M15;
    if (StringFind(comment, "M30") >= 0) return PERIOD_M30;
    if (StringFind(comment, "H1") >= 0) return PERIOD_H1;
    if (StringFind(comment, "H4") >= 0) return PERIOD_H4;
    if (StringFind(comment, "D1") >= 0) return PERIOD_D1;
    return PERIOD_H1; // Default
}

string TimeframeToString(ENUM_TIMEFRAMES tf)
{
    switch (tf)
    {
        case PERIOD_M1: return "M1";
        case PERIOD_M5: return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1: return "H1";
        case PERIOD_H4: return "H4";
        case PERIOD_D1: return "D1";
        default: return "UNKNOWN";
    }
}

int GetMaxPositionsForTimeframe(ENUM_TIMEFRAMES tf)
{
    if (IsScalpingTimeframe(tf)) return MaxSimultaneousScalps;
    return MaxSimultaneousSwings;
}

int GetMinTimeBetweenTrades(ENUM_TIMEFRAMES tf)
{
    switch (tf)
    {
        case PERIOD_M1: return 30;   // 30 seconds
        case PERIOD_M5: return 60;   // 1 minute
        case PERIOD_M15: return 300; // 5 minutes
        case PERIOD_M30: return 600; // 10 minutes
        case PERIOD_H1: return 1800; // 30 minutes
        case PERIOD_H4: return 3600; // 1 hour
        case PERIOD_D1: return 7200; // 2 hours
        default: return 300;
    }
}

int CalculateConfluenceScore(ENUM_TIMEFRAMES tf, double rsi, double atr)
{
    int score = 0;
    
    // RSI confluence
    if (rsi < 30 || rsi > 70) score += 2;
    else if (rsi < 40 || rsi > 60) score += 1;
    
    // ATR confluence (volatility)
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double atr_percent = (atr / current_price) * 100;
    if (atr_percent > 0.3 && atr_percent < 0.8) score += 1;
    
    // Timeframe confluence
    if (IsScalpingTimeframe(tf)) score += 1; // Favor scalping
    
    // Session confluence
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if (dt.hour >= 8 && dt.hour <= 16) score += 1; // London/NY session
    
    return score;
}

double CalculateLotSize(double risk_percent, int stop_pips)
{
    double risk_amount = AccountInfoDouble(ACCOUNT_BALANCE) * risk_percent / 100.0;
    double stop_value = stop_pips * PointMultiplier;
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    
    if (tick_value == 0) tick_value = 0.1; // Default for XAUUSD
    
    double lot_size = risk_amount / (stop_value * tick_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    if (min_lot == 0) min_lot = 0.01;
    if (max_lot == 0) max_lot = 100.0;
    if (lot_step == 0) lot_step = 0.01;
    
    lot_size = MathMax(min_lot, MathMin(max_lot, MathRound(lot_size / lot_step) * lot_step));
    
    return lot_size;
}

bool ClosePosition(ulong ticket, string reason)
{
    if (!PositionSelectByTicket(ticket)) return false;
    
    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.volume = PositionGetDouble(POSITION_VOLUME);
    request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                   SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(request.symbol, SYMBOL_ASK);
    request.position = ticket;
    request.magic = MagicNumber;
    request.comment = reason;
    
    return OrderSend(request, result);
}

bool PartialClosePosition(ulong ticket, double percent, string reason)
{
    if (!PositionSelectByTicket(ticket)) return false;
    
    double current_volume = PositionGetDouble(POSITION_VOLUME);
    double close_volume = current_volume * percent / 100.0;
    
    // Normalize volume
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    close_volume = MathMax(min_lot, MathRound(close_volume / lot_step) * lot_step);
    
    if (close_volume >= current_volume) return ClosePosition(ticket, reason);
    
    MqlTradeRequest request = {0};
    MqlTradeResult result = {0};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.volume = close_volume;
    request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                   SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(request.symbol, SYMBOL_ASK);
    request.position = ticket;
    request.magic = MagicNumber;
    request.comment = reason;
    
    return OrderSend(request, result);
}
