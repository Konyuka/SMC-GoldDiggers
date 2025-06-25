//+------------------------------------------------------------------+
//|                                       SMC_GoldEA_LiveDemo.mq5   |
//|                        Copyright 2024, LuxAlgo & Smart Money Concepts |
//|                                       https://www.luxalgo.com/   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, LuxAlgo & Smart Money Concepts"
#property link "https://www.luxalgo.com/"
#property version "3.10"
#property description "Live Demo Expert Advisor for Gold (XAUUSD) using LuxAlgo Smart Money Concepts"
#property description "Optimized for live demo trading with conservative risk management"

//--- Input Parameters
input group "═════════ STRATEGY SETTINGS ═════════"
input ENUM_TIMEFRAMES BaseTimeframe = PERIOD_H4;                   // Base timeframe (market structure)
input ENUM_TIMEFRAMES ConfirmTimeframe = PERIOD_H1;                // Confirmation timeframe
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_D1;                 // Higher timeframe (bias)
input int MaxOpenTrades = 3;                                       // Maximum open trades (conservative for demo)
input int Slippage = 20;                                           // Slippage in points (higher for live)

input group "═════════ RISK MANAGEMENT ═════════"
input double RiskPerTradePercent = 0.5;                           // Risk per trade (% of balance) - Conservative
input int StopLossPips = 300;                                      // Default SL (30 pips for XAUUSD)
input int TakeProfitPips = 900;                                    // Default TP (90 pips for XAUUSD)
input bool UseAutoRR = true;                                       // Use automatic risk-reward
input double MinRiskReward = 2.5;                                  // Minimum risk:reward ratio
input bool UseTrailingStop = true;                                 // Enable trailing stop
input int TrailingStopPips = 250;                                  // Trailing stop distance
input bool UseBreakeven = true;                                    // Move SL to breakeven
input int BreakevenPips = 200;                                     // Breakeven trigger distance

input group "═════════ SMC INDICATOR SETTINGS ═════════"
input string SMC_Indicator_Name = "LuxAlgo - Smart Money Concepts"; // Indicator name
input int SMC_OB_Lookback = 20;                                     // Order block lookback (bars)
input int SMC_FVG_Lookback = 15;                                    // FVG lookback (bars)
input bool UseOrderBlocks = true;                                   // Trade order blocks
input bool UseFairValueGaps = true;                                 // Trade fair value gaps
input bool UseLiquidityGrabs = true;                                // Trade liquidity grabs
input double MinOBSize = 50;                                        // Minimum order block size (pips) - REDUCED for demo

input group "═════════ TRADING FILTERS ═════════"
input bool UseSessionFilter = true;                                // Enable session filtering
input int LondonStartHour = 7;                                     // London session start (GMT)
input int LondonEndHour = 16;                                      // London session end (GMT)
input int NewYorkStartHour = 13;                                   // New York session start (GMT)
input int NewYorkEndHour = 21;                                     // New York session end (GMT)
input bool UseVolatilityFilter = true;                             // Enable volatility filter
input double MaxATRPercent = 1.2;                                  // Maximum ATR percentage (relaxed for live)
input bool UseSpreadFilter = true;                                 // Enable spread filter
input double MaxSpreadPips = 50;                                   // Maximum spread (pips) - Higher for live

input group "═════════ LIVE DEMO SETTINGS ═════════"
input int MagicNumber = 20241225;                                  // EA Magic Number (Updated)
input string TradeComment = "SMC-Gold-LiveDemo";                   // Trade comment
input bool EnableAlerts = true;                                    // Enable trade alerts
input bool EnablePartialClose = true;                              // Enable partial position closing
input double PartialClosePercent = 50.0;                          // Partial close percentage
input int PartialClosePips = 400;                                 // Partial close trigger (pips)

input group "═════════ SMC SIGNAL STRENGTH ═════════"
input int MinConfluenceLevel = 1;                                 // Minimum confluence level (1-5) - RELAXED for demo
input bool RequireHigherTFConfirmation = false;                   // Require higher timeframe confirmation - DISABLED for demo
input bool UseConservativeEntries = false;                        // Use conservative entry logic - DISABLED for demo
input double SignalValidityHours = 4.0;                          // Signal validity in hours

input group "═════════ MANUAL TESTING (DEMO ONLY) ═════════"
input bool EnableManualTesting = false;                           // Enable manual trade triggers (disabled for live)
input bool TriggerBuyTrade = false;                               // Trigger a BUY trade now
input bool TriggerSellTrade = false;                              // Trigger a SELL trade now
input bool CloseAllTrades = false;                                // Close all open trades
input double ManualLotSize = 0.01;                                // Manual trade lot size

//--- Enhanced Global Variables
// Simplified trading objects
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
    
    bool Buy(double volume, string symbol, double price, double sl, double tp, string comment)
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = symbol;
        request.volume = volume;
        request.type = ORDER_TYPE_BUY;
        request.price = price;
        request.sl = sl;
        request.tp = tp;
        request.deviation = deviation;
        request.magic = magic_number;
        request.comment = comment;
        request.type_filling = filling_type;
        
        return OrderSend(request, result);
    }
    
    bool Sell(double volume, string symbol, double price, double sl, double tp, string comment)
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = symbol;
        request.volume = volume;
        request.type = ORDER_TYPE_SELL;
        request.price = price;
        request.sl = sl;
        request.tp = tp;
        request.deviation = deviation;
        request.magic = magic_number;
        request.comment = comment;
        request.type_filling = filling_type;
        
        return OrderSend(request, result);
    }
    
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

//--- Global Variables
double PointMultiplier;
datetime LastTickTime;
datetime LastTradeTime = 0;
int ATR_Handle = INVALID_HANDLE;
int RSI_Handle = INVALID_HANDLE;
int SMC_Base_Handle = INVALID_HANDLE;
int SMC_Confirm_Handle = INVALID_HANDLE;
int SMC_Higher_Handle = INVALID_HANDLE;
bool SMC_Available = false;

//--- Enhanced SMC Buffer Mapping
enum ENUM_SMC_BUFFERS
{
    BUFFER_BULLISH_BOS = 0,
    BUFFER_BEARISH_BOS = 1,
    BUFFER_BULLISH_CHOCH = 2,
    BUFFER_BEARISH_CHOCH = 3,
    BUFFER_BULLISH_OB_HIGH = 4,
    BUFFER_BULLISH_OB_LOW = 5,
    BUFFER_BEARISH_OB_HIGH = 6,
    BUFFER_BEARISH_OB_LOW = 7,
    BUFFER_BULLISH_FVG_HIGH = 8,
    BUFFER_BULLISH_FVG_LOW = 9,
    BUFFER_BEARISH_FVG_HIGH = 10,
    BUFFER_BEARISH_FVG_LOW = 11,
    BUFFER_EQ_HIGHS = 12,
    BUFFER_EQ_LOWS = 13,
    BUFFER_LIQUIDITY_GRAB_HIGH = 14,
    BUFFER_LIQUIDITY_GRAB_LOW = 15
};

//--- Market Structure Types
enum ENUM_MARKET_BIAS
{
    BIAS_BULLISH,
    BIAS_BEARISH,
    BIAS_NEUTRAL
};

enum ENUM_TRADE_TYPE
{
    TRADE_ORDER_BLOCK,
    TRADE_FAIR_VALUE_GAP,
    TRADE_LIQUIDITY_GRAB,
    TRADE_BOS_BREAKOUT,
    TRADE_CHOCH_REVERSAL,
    TRADE_NONE
};

struct SMarketConditions
{
    double atr_value;
    double atr_percent;
    double rsi_value;
    double current_spread;
    bool is_volatile;
    bool is_trending;
    ENUM_MARKET_BIAS trend_direction;
};

struct SMarketStructure
{
    bool bullish_bos;
    bool bearish_bos;
    bool bullish_choch;
    bool bearish_choch;
    double recent_high;
    double recent_low;
    datetime high_time;
    datetime low_time;
    int structure_strength;
};

struct SOrderBlocks
{
    double bullish_ob_high;
    double bullish_ob_low;
    double bearish_ob_high;
    double bearish_ob_low;
    datetime ob_time;
    bool is_valid;
    double size_pips;
};

struct SFairValueGaps
{
    double bullish_fvg_high;
    double bullish_fvg_low;
    double bearish_fvg_high;
    double bearish_fvg_low;
    datetime fvg_time;
    bool is_valid;
    double size_pips;
};

struct SLiquidityLevels
{
    double equal_highs;
    double equal_lows;
    double swing_highs;
    double swing_lows;
    bool liquidity_grab_high;
    bool liquidity_grab_low;
    datetime grab_time;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("═══════════════════════════════════════");
    Print("🚀 SMC GOLD EA MASTERPIECE v3.10 Starting");
    Print("   🎯 ENHANCED LIVE DEMO VERSION");
    Print("   💎 Advanced SMC Intelligence");
    Print("   🛡️ Robust Position Management");
    Print("═══════════════════════════════════════");

    //--- Validate demo account (optional safety check)
    if (!AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO)
    {
        Print("⚠️ WARNING: This EA is designed for DEMO accounts!");
        Print("   Current account type: ", AccountInfoInteger(ACCOUNT_TRADE_MODE));
    }

    //--- Initialize trading objects
    Trade.SetExpertMagicNumber(MagicNumber);
    Trade.SetDeviationInPoints(Slippage);
    Trade.SetTypeFilling(ORDER_FILLING_FOK);
    Trade.SetAsyncMode(false);

    //--- Calculate point multiplier for XAUUSD
    PointMultiplier = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
    Print("💎 Point Multiplier: ", PointMultiplier);

    //--- Create core indicator handles
    ATR_Handle = iATR(_Symbol, PERIOD_H1, 14);
    RSI_Handle = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
    
    //--- Validate essential indicators
    if (ATR_Handle == INVALID_HANDLE || RSI_Handle == INVALID_HANDLE)
    {
        Print("❌ Error creating essential indicator handles (ATR/RSI)!");
        return INIT_FAILED;
    }

    //--- Create SMC indicator handles for MASTERPIECE trading
    SMC_Base_Handle = iCustom(_Symbol, BaseTimeframe, SMC_Indicator_Name);
    SMC_Confirm_Handle = iCustom(_Symbol, ConfirmTimeframe, SMC_Indicator_Name);
    SMC_Higher_Handle = iCustom(_Symbol, HigherTimeframe, SMC_Indicator_Name);
    
    //--- Check SMC indicator availability (REQUIRED for MASTERPIECE trading)
    SMC_Available = (SMC_Base_Handle != INVALID_HANDLE && 
                     SMC_Confirm_Handle != INVALID_HANDLE && 
                     SMC_Higher_Handle != INVALID_HANDLE);
    
    if (!SMC_Available)
    {
        Print("❌ SMC Indicator not found - please install 'LuxAlgo - Smart Money Concepts'");
        Print("   This MASTERPIECE EA requires the SMC indicator for advanced trading");
        return INIT_FAILED;
    }
    else
    {
        Print("✅ SMC Indicator loaded successfully on all timeframes");
        Print("   📊 Base: ", EnumToString(BaseTimeframe));
        Print("   📊 Confirm: ", EnumToString(ConfirmTimeframe));
        Print("   📊 Higher: ", EnumToString(HigherTimeframe));
    }

    //--- Wait for indicators to initialize
    Print("⏳ Initializing MASTERPIECE SMC intelligence...");
    Sleep(2000); // Wait 2 seconds for live trading

    //--- Test indicator readiness
    if (!AreIndicatorsReady())
    {
        Print("⚠️ Warning: Indicators may not be ready yet. EA will wait during OnTick.");
    }

    //--- Validate symbol
    if (_Symbol != "XAUUSD")
    {
        Print("⚠️ Warning: EA optimized for XAUUSD, current symbol: ", _Symbol);
    }

    //--- Apply Gold-specific settings
    ApplyGoldSpecificSettings();

    Print("✅ MASTERPIECE EA initialized successfully for LIVE DEMO trading");
    Print("� Risk per trade: ", RiskPerTradePercent, "%");
    Print("🎯 Min R:R Ratio: ", MinRiskReward);
    Print("� Max Open Trades: ", MaxOpenTrades);
    Print("⭐ Min Confluence: ", MinConfluenceLevel, "/5");
    Print("🛡️ Conservative Mode: ", UseConservativeEntries ? "ON" : "OFF");
    Print("� MASTERPIECE SMC Trading Ready!");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("📴 EA shutting down. Reason: ", reason);

    //--- Release indicators
    if (SMC_Base_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Base_Handle);
    if (SMC_Confirm_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Confirm_Handle);
    if (SMC_Higher_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Higher_Handle);
    if (ATR_Handle != INVALID_HANDLE)
        IndicatorRelease(ATR_Handle);
    if (RSI_Handle != INVALID_HANDLE)
        IndicatorRelease(RSI_Handle);
}

//+------------------------------------------------------------------+
//| Check if indicators are ready                                    |
//+------------------------------------------------------------------+
bool AreIndicatorsReady()
{
    double test_atr[], test_rsi[];
    ArrayResize(test_atr, 1);
    ArrayResize(test_rsi, 1);
    
    int atr_result = CopyBuffer(ATR_Handle, 0, 0, 1, test_atr);
    int rsi_result = CopyBuffer(RSI_Handle, 0, 0, 1, test_rsi);
    
    bool ready = (atr_result > 0 && test_atr[0] != EMPTY_VALUE && 
                  rsi_result > 0 && test_rsi[0] != EMPTY_VALUE);
    
    if (ready)
    {
        Print("✅ All indicators ready! ATR: ", DoubleToString(test_atr[0], 5), 
              " | RSI: ", DoubleToString(test_rsi[0], 2));
    }
    
    return ready;
}

//+------------------------------------------------------------------+
//| Expert tick function - ENHANCED MASTERPIECE VERSION            |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check if indicators are ready
    static bool indicators_ready = false;
    if (!indicators_ready)
    {
        if (!AreIndicatorsReady())
        {
            static int wait_counter = 0;
            wait_counter++;
            if (wait_counter % 500 == 0) // Every 500 ticks
            {
                Print("⏳ Waiting for indicators... (", wait_counter, " ticks)");
            }
            return;
        }
        indicators_ready = true;
        Print("✅ All indicators ready - Starting MASTERPIECE SMC trading!");
    }

    //--- Check for manual testing (demo only)
    if (EnableManualTesting)
    {
        HandleManualTesting();
    }

    //--- Basic trading environment checks
    if (!IsValidTradingEnvironment())
        return;

    //--- Prevent multiple trades on same tick
    if (TimeCurrent() == LastTickTime)
        return;

    //--- Get market conditions with enhanced monitoring
    SMarketConditions conditions = GetMarketConditions();
    
    //--- Enhanced market monitoring (every 10 ticks)
    static int monitor_counter = 0;
    monitor_counter++;
    if (monitor_counter >= 10)
    {
        monitor_counter = 0;
        PrintMarketStatus(conditions);
    }

    //--- Apply trading filters
    if (!PassesFilters(conditions))
        return;

    //--- Main SMC trading logic with MASTERPIECE enhancements
    CheckForSMCTrades(conditions);

    //--- Enhanced position management
    ManageOpenPositions(conditions);

    LastTickTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Enhanced Market Status Monitor                                  |
//+------------------------------------------------------------------+
void PrintMarketStatus(SMarketConditions &conditions)
{
    static datetime last_status_time = 0;
    
    // Print status every 5 minutes
    if (TimeCurrent() - last_status_time < 300)
        return;
        
    last_status_time = TimeCurrent();
    
    // Get current position count
    int buy_positions = CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY);
    int sell_positions = CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL);
    
    // Get higher timeframe bias
    ENUM_MARKET_BIAS htf_bias = GetHigherTimeframeBias();
    
    // Get market structure
    SMarketStructure base_structure = GetMarketStructure(SMC_Base_Handle);
    
    Print("═══════════════════════════════════════");
    Print("🚀 SMC GOLD EA MASTERPIECE - MARKET STATUS");
    Print("═══════════════════════════════════════");
    Print("📊 Time: ", TimeToString(TimeCurrent()));
    Print("📈 Current Price: ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits));
    Print("📊 Spread: ", DoubleToString(conditions.current_spread, 1), " pips");
    Print("📊 ATR: ", DoubleToString(conditions.atr_value, _Digits), " (", DoubleToString(conditions.atr_percent, 2), "%)");
    Print("📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
    Print("📊 Volatility: ", conditions.is_volatile ? "HIGH" : "NORMAL");
    Print("📊 Trend: ", EnumToString(conditions.trend_direction));
    Print("📊 HTF Bias: ", EnumToString(htf_bias));
    Print("📊 Base Structure - Bull BOS: ", base_structure.bullish_bos ? "YES" : "NO");
    Print("📊 Base Structure - Bear BOS: ", base_structure.bearish_bos ? "YES" : "NO");
    Print("📊 Base Structure - Bull CHoCH: ", base_structure.bullish_choch ? "YES" : "NO");
    Print("📊 Base Structure - Bear CHoCH: ", base_structure.bearish_choch ? "YES" : "NO");
    Print("💼 Open Positions: ", buy_positions + sell_positions, " (", buy_positions, " BUY, ", sell_positions, " SELL)");
    Print("💰 Account Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    Print("💰 Account Equity: $", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    Print("═══════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| SMC Trading Logic for Live Demo - ENHANCED DEBUG VERSION       |
//+------------------------------------------------------------------+
void CheckForSMCTrades(SMarketConditions &conditions)
{
    MqlTick current_tick;
    if (!SymbolInfoTick(_Symbol, current_tick))
        return;

    //--- Prevent too frequent trading
    if (TimeCurrent() - LastTradeTime < 300) // 5 minutes minimum between trades
        return;

    //--- Get market structure analysis with debugging
    ENUM_MARKET_BIAS higher_tf_bias = GetHigherTimeframeBias();
    SMarketStructure base_structure = GetMarketStructure(SMC_Base_Handle);
    SMarketStructure confirm_structure = GetMarketStructure(SMC_Confirm_Handle);

    //--- Get SMC components with debugging
    SOrderBlocks order_blocks = GetOrderBlocks(SMC_Base_Handle);
    SFairValueGaps fvgs = GetFairValueGaps(SMC_Base_Handle);
    SLiquidityLevels liquidity = GetLiquidityLevels(SMC_Higher_Handle);
    
    //--- DEBUG: Print detailed SMC analysis every 30 seconds for troubleshooting
    static datetime last_debug_time = 0;
    if (TimeCurrent() - last_debug_time >= 30) // Every 30 seconds for intensive debugging
    {
        last_debug_time = TimeCurrent();
        Print("🔍 INTENSIVE SMC ANALYSIS DEBUG:");
        Print("   📊 HTF Bias: ", EnumToString(higher_tf_bias));
        Print("   📊 Base - Bull BOS: ", base_structure.bullish_bos ? "YES" : "NO");
        Print("   📊 Base - Bear BOS: ", base_structure.bearish_bos ? "YES" : "NO");
        Print("   📊 Base - Bull CHoCH: ", base_structure.bullish_choch ? "YES" : "NO");
        Print("   📊 Base - Bear CHoCH: ", base_structure.bearish_choch ? "YES" : "NO");
        Print("   📊 Base Structure Strength: ", base_structure.structure_strength);
        Print("   📊 Order Blocks Valid: ", order_blocks.is_valid ? "YES" : "NO");
        
        if (order_blocks.is_valid)
        {
            Print("   📊 Bull OB High: ", DoubleToString(order_blocks.bullish_ob_high, _Digits));
            Print("   📊 Bull OB Low: ", DoubleToString(order_blocks.bullish_ob_low, _Digits));
            Print("   📊 Bear OB High: ", DoubleToString(order_blocks.bearish_ob_high, _Digits));
            Print("   📊 Bear OB Low: ", DoubleToString(order_blocks.bearish_ob_low, _Digits));
            Print("   📊 OB Size: ", DoubleToString(order_blocks.size_pips, 1), " pips");
        }
        else
        {
            Print("   ❌ No valid Order Blocks found");
        }
        
        Print("   📊 FVGs Valid: ", fvgs.is_valid ? "YES" : "NO");
        
        if (fvgs.is_valid)
        {
            Print("   📊 Bull FVG High: ", DoubleToString(fvgs.bullish_fvg_high, _Digits));
            Print("   📊 Bull FVG Low: ", DoubleToString(fvgs.bullish_fvg_low, _Digits));
            Print("   📊 Bear FVG High: ", DoubleToString(fvgs.bearish_fvg_high, _Digits));
            Print("   📊 Bear FVG Low: ", DoubleToString(fvgs.bearish_fvg_low, _Digits));
            Print("   📊 FVG Size: ", DoubleToString(fvgs.size_pips, 1), " pips");
        }
        else
        {
            Print("   ❌ No valid FVGs found");
        }
        
        Print("   📊 Liquidity Grab High: ", liquidity.liquidity_grab_high ? "YES" : "NO");
        Print("   📊 Liquidity Grab Low: ", liquidity.liquidity_grab_low ? "YES" : "NO");
        Print("   📊 Current Price: ", DoubleToString(current_tick.ask, _Digits));
        Print("   📊 Min Confluence Required: ", MinConfluenceLevel);
        Print("   📊 Conservative Entries: ", UseConservativeEntries ? "ENABLED" : "DISABLED");
        Print("   📊 Higher TF Confirmation: ", RequireHigherTFConfirmation ? "REQUIRED" : "NOT REQUIRED");
        Print("   📊 Use Order Blocks: ", UseOrderBlocks ? "YES" : "NO");
        Print("   📊 Use FVGs: ", UseFairValueGaps ? "YES" : "NO");
        Print("   📊 Use Liquidity: ", UseLiquidityGrabs ? "YES" : "NO");
    }

    //--- Check for buy setups with enhanced debugging
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) < MaxOpenTrades)
    {
        ENUM_TRADE_TYPE buy_setup = AnalyzeBuyOpportunity(higher_tf_bias, base_structure,
                                                          confirm_structure, order_blocks,
                                                          fvgs, liquidity, current_tick.ask, conditions);

        if (buy_setup != TRADE_NONE)
        {
            int confluence_score = CalculateConfluenceScore(buy_setup, base_structure, confirm_structure, 
                                                           order_blocks, fvgs, liquidity, true);
            
            Print("🚀 BUY OPPORTUNITY FOUND!");
            Print("   📊 Setup Type: ", EnumToString(buy_setup));
            Print("   ⭐ Confluence Score: ", confluence_score, "/5 (Required: ", MinConfluenceLevel, ")");
            
            if (confluence_score >= MinConfluenceLevel)
            {
                Print("🚀 SMC BUY SIGNAL DETECTED!");
                Print("   📊 Setup: ", EnumToString(buy_setup));
                Print("   ⭐ Confluence Score: ", confluence_score, "/5");
                Print("   📈 Higher TF Bias: ", EnumToString(higher_tf_bias));
                
                ExecuteSMCBuyTrade(current_tick.ask, buy_setup, confluence_score, conditions);
            }
            else
            {
                Print("⚠️ BUY signal confluence too low: ", confluence_score, "/", MinConfluenceLevel);
            }
        }
        else
        {
            // Debug why no buy setup was found
            if (TimeCurrent() - last_debug_time < 5) // Only in recent debug cycle
            {
                Print("🔍 No BUY setup found - Checking reasons:");
                if (higher_tf_bias == BIAS_BEARISH && RequireHigherTFConfirmation)
                    Print("   ❌ HTF Bias is bearish (", EnumToString(higher_tf_bias), ")");
                if (!UseOrderBlocks && !UseFairValueGaps && !UseLiquidityGrabs)
                    Print("   ❌ All SMC methods disabled");
            }
        }
    }

    //--- Check for sell setups with enhanced debugging
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) < MaxOpenTrades)
    {
        ENUM_TRADE_TYPE sell_setup = AnalyzeSellOpportunity(higher_tf_bias, base_structure,
                                                            confirm_structure, order_blocks,
                                                            fvgs, liquidity, current_tick.bid, conditions);

        if (sell_setup != TRADE_NONE)
        {
            int confluence_score = CalculateConfluenceScore(sell_setup, base_structure, confirm_structure, 
                                                           order_blocks, fvgs, liquidity, false);
            
            Print("🚀 SELL OPPORTUNITY FOUND!");
            Print("   📊 Setup Type: ", EnumToString(sell_setup));
            Print("   ⭐ Confluence Score: ", confluence_score, "/5 (Required: ", MinConfluenceLevel, ")");
            
            if (confluence_score >= MinConfluenceLevel)
            {
                Print("🚀 SMC SELL SIGNAL DETECTED!");
                Print("   📊 Setup: ", EnumToString(sell_setup));
                Print("   ⭐ Confluence Score: ", confluence_score, "/5");
                Print("   📉 Higher TF Bias: ", EnumToString(higher_tf_bias));
                
                ExecuteSMCSellTrade(current_tick.bid, sell_setup, confluence_score, conditions);
            }
            else
            {
                Print("⚠️ SELL signal confluence too low: ", confluence_score, "/", MinConfluenceLevel);
            }
        }
        else
        {
            // Debug why no sell setup was found
            if (TimeCurrent() - last_debug_time < 5) // Only in recent debug cycle
            {
                Print("🔍 No SELL setup found - Checking reasons:");
                if (higher_tf_bias == BIAS_BULLISH && RequireHigherTFConfirmation)
                    Print("   ❌ HTF Bias is bullish (", EnumToString(higher_tf_bias), ")");
                if (!UseOrderBlocks && !UseFairValueGaps && !UseLiquidityGrabs)
                    Print("   ❌ All SMC methods disabled");
            }
        }
    }
    
    //--- ENHANCED FALLBACK TRADING MODE: If SMC indicators are working but no valid signals
    if (MinConfluenceLevel <= 2) // More aggressive fallback when confluence is low
    {
        // Check if we have any SMC structure at all
        bool has_smc_structure = (base_structure.bullish_bos || base_structure.bearish_bos || 
                                 base_structure.bullish_choch || base_structure.bearish_choch ||
                                 order_blocks.is_valid || fvgs.is_valid);
        
        if (has_smc_structure)
        {
            CheckForEnhancedBreakoutTrades(conditions, current_tick, base_structure);
        }
        else
        {
            // Basic RSI reversal trading if no SMC structure detected
            CheckForSimpleBreakoutTrades(conditions, current_tick);
        }
    }
}

//+------------------------------------------------------------------+
//| Enhanced Breakout Trading with SMC Context                      |
//+------------------------------------------------------------------+
void CheckForEnhancedBreakoutTrades(SMarketConditions &conditions, MqlTick &tick, SMarketStructure &structure)
{
    static datetime last_enhanced_time = 0;
    
    // Only try enhanced trading every 15 minutes
    if (TimeCurrent() - last_enhanced_time < 900)
        return;
        
    Print("🔄 ENHANCED BREAKOUT ANALYSIS:");
    Print("   📊 Structure Strength: ", structure.structure_strength);
    Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
    Print("   📊 Recent High: ", DoubleToString(structure.recent_high, _Digits));
    Print("   📊 Recent Low: ", DoubleToString(structure.recent_low, _Digits));
    Print("   📊 Current Price: ", DoubleToString(tick.ask, _Digits));
    
    // Enhanced buy conditions with SMC context
    if ((structure.bullish_bos || structure.bullish_choch) && 
        conditions.rsi_value < 60 && 
        structure.recent_low > 0 &&
        tick.ask > structure.recent_low)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
        {
            Print("🔄 ENHANCED BUY: SMC Bullish Structure + RSI (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(true, tick, conditions);
            last_enhanced_time = TimeCurrent();
            return;
        }
    }
    
    // Enhanced sell conditions with SMC context
    if ((structure.bearish_bos || structure.bearish_choch) && 
        conditions.rsi_value > 40 && 
        structure.recent_high > 0 &&
        tick.bid < structure.recent_high)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
        {
            Print("🔄 ENHANCED SELL: SMC Bearish Structure + RSI (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(false, tick, conditions);
            last_enhanced_time = TimeCurrent();
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Fallback Simple Breakout Trading                                |
//+------------------------------------------------------------------+
void CheckForSimpleBreakoutTrades(SMarketConditions &conditions, MqlTick &tick)
{
    static datetime last_fallback_time = 0;
    
    // Only try fallback trading every 20 minutes (more frequent)
    if (TimeCurrent() - last_fallback_time < 1200)
        return;
        
    Print("🔄 BASIC FALLBACK ANALYSIS:");
    Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
    Print("   📊 Trend: ", EnumToString(conditions.trend_direction));
        
    // Check if RSI indicates oversold/overbought with reversal potential (more aggressive)
    if (conditions.rsi_value < 35) // Oversold (relaxed from 30)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
        {
            Print("🔄 FALLBACK BUY: RSI Oversold (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(true, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
    else if (conditions.rsi_value > 65) // Overbought (relaxed from 70)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
        {
            Print("🔄 FALLBACK SELL: RSI Overbought (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(false, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
    // NEW: Add trend following mode for ranging RSI
    else if (conditions.rsi_value > 50 && conditions.rsi_value < 60 && conditions.trend_direction == BIAS_BULLISH)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
        {
            Print("🔄 FALLBACK BUY: Trend Following (RSI: ", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(true, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
    else if (conditions.rsi_value > 40 && conditions.rsi_value < 50 && conditions.trend_direction == BIAS_BEARISH)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
        {
            Print("🔄 FALLBACK SELL: Trend Following (RSI: ", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(false, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
}

//+------------------------------------------------------------------+
//| Execute Fallback Trade                                          |
//+------------------------------------------------------------------+
void ExecuteFallbackTrade(bool is_buy, MqlTick &tick, SMarketConditions &conditions)
{
    double entry_price = is_buy ? tick.ask : tick.bid;
    double lot_size = CalculateLotSize(entry_price, StopLossPips);
    double sl, tp;
    
    if (is_buy)
    {
        sl = entry_price - (StopLossPips * PointMultiplier);
        tp = entry_price + (TakeProfitPips * PointMultiplier);
    }
    else
    {
        sl = entry_price + (StopLossPips * PointMultiplier);
        tp = entry_price - (TakeProfitPips * PointMultiplier);
    }
    
    string comment = TradeComment + "-FALLBACK-RSI";
    
    bool success = false;
    if (is_buy)
        success = Trade.Buy(lot_size, _Symbol, entry_price, sl, tp, comment);
    else
        success = Trade.Sell(lot_size, _Symbol, entry_price, sl, tp, comment);
    
    if (success)
    {
        LastTradeTime = TimeCurrent();
        Print("✅ FALLBACK ", is_buy ? "BUY" : "SELL", " TRADE EXECUTED:");
        Print("   💰 Entry: ", DoubleToString(entry_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits));
        Print("   🎯 TP: ", DoubleToString(tp, _Digits));
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
        Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
        
        if (EnableAlerts)
            Alert("SMC Gold EA: Fallback ", is_buy ? "BUY" : "SELL", " trade executed");
    }
    else
    {
        Print("❌ FALLBACK TRADE FAILED - Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Execute SMC Buy Trade                                            |
//+------------------------------------------------------------------+
void ExecuteSMCBuyTrade(double ask_price, ENUM_TRADE_TYPE setup_type, int confluence_score, SMarketConditions &conditions)
{
    double lot_size = CalculateLotSize(ask_price, StopLossPips);
    double sl = ask_price - (StopLossPips * PointMultiplier);
    double tp = ask_price + (TakeProfitPips * PointMultiplier);
    
    // Adjust SL/TP based on setup type and confluence
    if (setup_type == TRADE_ORDER_BLOCK)
    {
        sl = ask_price - ((StopLossPips * 0.8) * PointMultiplier); // Tighter SL for OB
    }
    else if (setup_type == TRADE_FAIR_VALUE_GAP)
    {
        tp = ask_price + ((TakeProfitPips * 1.2) * PointMultiplier); // Larger TP for FVG
    }
    
    string comment = TradeComment + "-" + EnumToString(setup_type) + "-C" + IntegerToString(confluence_score);
    
    if (Trade.Buy(lot_size, _Symbol, ask_price, sl, tp, comment))
    {
        LastTradeTime = TimeCurrent();
        
        Print("✅ SMC BUY TRADE EXECUTED:");
        Print("   💰 Entry: ", DoubleToString(ask_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " (", DoubleToString((ask_price - sl) / PointMultiplier, 1), " pips)");
        Print("   🎯 TP: ", DoubleToString(tp, _Digits), " (", DoubleToString((tp - ask_price) / PointMultiplier, 1), " pips)");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
        Print("   📊 Setup: ", EnumToString(setup_type));
        Print("   ⭐ Confluence: ", confluence_score, "/5");
        
        if (EnableAlerts)
        {
            Alert("SMC Gold EA: BUY trade executed - ", EnumToString(setup_type), " - Confluence: ", confluence_score);
        }
    }
    else
    {
        int error = GetLastError();
        Print("❌ SMC BUY TRADE FAILED:");
        Print("   🚨 Error: ", error, " - ", ErrorDescription(error));
        Print("   💰 Price: ", DoubleToString(ask_price, _Digits));
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
    }
}

//+------------------------------------------------------------------+
//| Execute SMC Sell Trade                                           |
//+------------------------------------------------------------------+
void ExecuteSMCSellTrade(double bid_price, ENUM_TRADE_TYPE setup_type, int confluence_score, SMarketConditions &conditions)
{
    double lot_size = CalculateLotSize(bid_price, StopLossPips);
    double sl = bid_price + (StopLossPips * PointMultiplier);
    double tp = bid_price - (TakeProfitPips * PointMultiplier);
    
    // Adjust SL/TP based on setup type and confluence
    if (setup_type == TRADE_ORDER_BLOCK)
    {
        sl = bid_price + ((StopLossPips * 0.8) * PointMultiplier); // Tighter SL for OB
    }
    else if (setup_type == TRADE_FAIR_VALUE_GAP)
    {
        tp = bid_price - ((TakeProfitPips * 1.2) * PointMultiplier); // Larger TP for FVG
    }
    
    string comment = TradeComment + "-" + EnumToString(setup_type) + "-C" + IntegerToString(confluence_score);
    
    if (Trade.Sell(lot_size, _Symbol, bid_price, sl, tp, comment))
    {
        LastTradeTime = TimeCurrent();
        
        Print("✅ SMC SELL TRADE EXECUTED:");
        Print("   💰 Entry: ", DoubleToString(bid_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " (", DoubleToString((sl - bid_price) / PointMultiplier, 1), " pips)");
        Print("   🎯 TP: ", DoubleToString(tp, _Digits), " (", DoubleToString((bid_price - tp) / PointMultiplier, 1), " pips)");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
        Print("   📊 Setup: ", EnumToString(setup_type));
        Print("   ⭐ Confluence: ", confluence_score, "/5");
        
        if (EnableAlerts)
        {
            Alert("SMC Gold EA: SELL trade executed - ", EnumToString(setup_type), " - Confluence: ", confluence_score);
        }
    }
    else
    {
        int error = GetLastError();
        Print("❌ SMC SELL TRADE FAILED:");
        Print("   🚨 Error: ", error, " - ", ErrorDescription(error));
        Print("   💰 Price: ", DoubleToString(bid_price, _Digits));
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
    }
}

//+------------------------------------------------------------------+
//| Calculate Confluence Score                                       |
//+------------------------------------------------------------------+
int CalculateConfluenceScore(ENUM_TRADE_TYPE setup_type, SMarketStructure &base, SMarketStructure &confirm,
                            SOrderBlocks &ob, SFairValueGaps &fvg, SLiquidityLevels &liq, bool is_buy)
{
    int score = 0;
    
    //--- Base structure confirmation
    if (is_buy && (base.bullish_bos || base.bullish_choch)) score++;
    if (!is_buy && (base.bearish_bos || base.bearish_choch)) score++;
    
    //--- Confirmation timeframe alignment
    if (is_buy && (confirm.bullish_bos || confirm.bullish_choch)) score++;
    if (!is_buy && (confirm.bearish_bos || confirm.bearish_choch)) score++;
    
    //--- Order block validation
    if (setup_type == TRADE_ORDER_BLOCK && ob.is_valid && ob.size_pips > MinOBSize) score++;
    
    //--- Fair Value Gap validation
    if (setup_type == TRADE_FAIR_VALUE_GAP && fvg.is_valid && fvg.size_pips > 50) score++;
    
    //--- Liquidity grab confirmation
    if (is_buy && liq.liquidity_grab_low) score++;
    if (!is_buy && liq.liquidity_grab_high) score++;
    
    return MathMin(score, 5); // Max score of 5
}

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+

// Calculate lot size based on risk percentage
double CalculateLotSize(double entry_price, int stop_loss_pips)
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPerTradePercent / 100.0);
    double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (stop_loss_pips * pip_value);
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lot_size = MathMax(lot_size, min_lot);
    lot_size = MathMin(lot_size, max_lot);
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    return lot_size;
}

// Count positions by magic number and type
int CountPositionsByMagic(int magic, ENUM_POSITION_TYPE pos_type)
{
    int count = 0;
    for (int i = 0; i < PositionsTotal(); i++)
    {
        if (PositionGetSymbol(i) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == magic &&
            PositionGetInteger(POSITION_TYPE) == pos_type)
            count++;
    }
    return count;
}

// Calculate profit in pips
double CalculateProfitPips(ulong ticket)
{
    if (!PositionSelectByTicket(ticket))
        return 0;
        
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double profit_points = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                          (current_price - open_price) :
                          (open_price - current_price);
    
    return profit_points / PointMultiplier;
}

// Enhanced trading environment validation
bool IsValidTradingEnvironment()
{
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        static datetime last_terminal_error = 0;
        if (TimeCurrent() - last_terminal_error > 300) // Every 5 minutes
        {
            Print("❌ Terminal trading not allowed");
            last_terminal_error = TimeCurrent();
        }
        return false;
    }

    if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        static datetime last_mql_error = 0;
        if (TimeCurrent() - last_mql_error > 300)
        {
            Print("❌ MQL trading not allowed");
            last_mql_error = TimeCurrent();
        }
        return false;
    }

    if (!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
    {
        static datetime last_symbol_error = 0;
        if (TimeCurrent() - last_symbol_error > 300)
        {
            Print("❌ Trading disabled for ", _Symbol);
            last_symbol_error = TimeCurrent();
        }
        return false;
    }

    return true;
}

// Get market conditions
SMarketConditions GetMarketConditions()
{
    SMarketConditions conditions;

    // Get ATR
    double atr_buffer[];
    if (CopyBuffer(ATR_Handle, 0, 0, 1, atr_buffer) > 0)
    {
        conditions.atr_value = atr_buffer[0];
        double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        conditions.atr_percent = (conditions.atr_value / current_price) * 100;
        conditions.is_volatile = conditions.atr_percent > MaxATRPercent;
    }

    // Get RSI
    double rsi_buffer[];
    if (CopyBuffer(RSI_Handle, 0, 0, 1, rsi_buffer) > 0)
    {
        conditions.rsi_value = rsi_buffer[0];
    }

    // Get spread
    conditions.current_spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                                SymbolInfoDouble(_Symbol, SYMBOL_BID)) / PointMultiplier;

    // Determine trend
    conditions.is_trending = conditions.rsi_value > 70 || conditions.rsi_value < 30;
    if (conditions.rsi_value > 50)
        conditions.trend_direction = BIAS_BULLISH;
    else if (conditions.rsi_value < 50)
        conditions.trend_direction = BIAS_BEARISH;
    else
        conditions.trend_direction = BIAS_NEUTRAL;

    return conditions;
}

// Trading filters
bool PassesFilters(SMarketConditions &conditions)
{
    // Session filter
    if (UseSessionFilter && !IsValidTradingSession())
        return false;

    // Volatility filter
    if (UseVolatilityFilter && conditions.is_volatile)
        return false;

    // Spread filter
    if (UseSpreadFilter && conditions.current_spread > MaxSpreadPips)
        return false;

    return true;
}

// Trading session validation
bool IsValidTradingSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;

    bool london_session = (hour >= LondonStartHour && hour < LondonEndHour);
    bool newyork_session = (hour >= NewYorkStartHour && hour < NewYorkEndHour);

    return london_session || newyork_session;
}

// Apply Gold-specific settings
void ApplyGoldSpecificSettings()
{
    Print("🥇 Applying XAUUSD-specific settings...");
    // Add any Gold-specific configurations here
}

// Enhanced manual testing handler (for demo only)
void HandleManualTesting()
{
    static bool buy_triggered = false;
    static bool sell_triggered = false;
    static bool close_triggered = false;
    
    if (TriggerBuyTrade && !buy_triggered)
    {
        buy_triggered = true;
        Print("🧪 Manual BUY trigger activated");
        
        // Execute manual buy trade
        MqlTick current_tick;
        if (SymbolInfoTick(_Symbol, current_tick))
        {
            double lot_size = ManualLotSize;
            double sl = current_tick.ask - (StopLossPips * PointMultiplier);
            double tp = current_tick.ask + (TakeProfitPips * PointMultiplier);
            
            string comment = TradeComment + "-MANUAL-BUY";
            
            if (Trade.Buy(lot_size, _Symbol, current_tick.ask, sl, tp, comment))
            {
                Print("✅ Manual BUY trade executed:");
                Print("   💰 Entry: ", DoubleToString(current_tick.ask, _Digits));
                Print("   🛑 SL: ", DoubleToString(sl, _Digits));
                Print("   🎯 TP: ", DoubleToString(tp, _Digits));
                Print("   📈 Lot: ", DoubleToString(lot_size, 2));
                
                if (EnableAlerts)
                    Alert("SMC Gold EA: Manual BUY trade executed");
            }
            else
            {
                Print("❌ Manual BUY trade failed - Error: ", GetLastError());
            }
        }
    }
    
    if (TriggerSellTrade && !sell_triggered)
    {
        sell_triggered = true;
        Print("🧪 Manual SELL trigger activated");
        
        // Execute manual sell trade
        MqlTick current_tick;
        if (SymbolInfoTick(_Symbol, current_tick))
        {
            double lot_size = ManualLotSize;
            double sl = current_tick.bid + (StopLossPips * PointMultiplier);
            double tp = current_tick.bid - (TakeProfitPips * PointMultiplier);
            
            string comment = TradeComment + "-MANUAL-SELL";
            
            if (Trade.Sell(lot_size, _Symbol, current_tick.bid, sl, tp, comment))
            {
                Print("✅ Manual SELL trade executed:");
                Print("   💰 Entry: ", DoubleToString(current_tick.bid, _Digits));
                Print("   🛑 SL: ", DoubleToString(sl, _Digits));
                Print("   🎯 TP: ", DoubleToString(tp, _Digits));
                Print("   📈 Lot: ", DoubleToString(lot_size, 2));
                
                if (EnableAlerts)
                    Alert("SMC Gold EA: Manual SELL trade executed");
            }
            else
            {
                Print("❌ Manual SELL trade failed - Error: ", GetLastError());
            }
        }
    }
    
    if (CloseAllTrades && !close_triggered)
    {
        close_triggered = true;
        Print("🧪 Manual close all triggered");
        
        int closed_count = 0;
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            if (symbol == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                if (Trade.PositionClose(ticket))
                {
                    closed_count++;
                    Print("✅ Manually closed position #", ticket);
                }
                else
                {
                    Print("❌ Failed to close position #", ticket, " - Error: ", GetLastError());
                }
            }
        }
        
        Print("🧪 Manual close all completed - ", closed_count, " positions closed");
        
        if (EnableAlerts && closed_count > 0)
            Alert("SMC Gold EA: Manually closed ", closed_count, " positions");
    }
    
    // Reset triggers
    if (!TriggerBuyTrade) buy_triggered = false;
    if (!TriggerSellTrade) sell_triggered = false;
    if (!CloseAllTrades) close_triggered = false;
}

//+------------------------------------------------------------------+
//| ADVANCED SMC ANALYSIS FUNCTIONS - MASTERPIECE IMPLEMENTATION   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get Higher Timeframe Market Bias                                |
//+------------------------------------------------------------------+
ENUM_MARKET_BIAS GetHigherTimeframeBias()
{
    if (SMC_Higher_Handle == INVALID_HANDLE)
        return BIAS_NEUTRAL;
    
    double bos_bull[], bos_bear[], choch_bull[], choch_bear[];
    ArrayResize(bos_bull, SMC_OB_Lookback);
    ArrayResize(bos_bear, SMC_OB_Lookback);
    ArrayResize(choch_bull, SMC_OB_Lookback);
    ArrayResize(choch_bear, SMC_OB_Lookback);
    
    // Get recent structure breaks
    int bull_bos = CopyBuffer(SMC_Higher_Handle, BUFFER_BULLISH_BOS, 0, SMC_OB_Lookback, bos_bull);
    int bear_bos = CopyBuffer(SMC_Higher_Handle, BUFFER_BEARISH_BOS, 0, SMC_OB_Lookback, bos_bear);
    int bull_choch = CopyBuffer(SMC_Higher_Handle, BUFFER_BULLISH_CHOCH, 0, SMC_OB_Lookback, choch_bull);
    int bear_choch = CopyBuffer(SMC_Higher_Handle, BUFFER_BEARISH_CHOCH, 0, SMC_OB_Lookback, choch_bear);
    
    if (bull_bos <= 0 || bear_bos <= 0 || bull_choch <= 0 || bear_choch <= 0)
        return BIAS_NEUTRAL;
    
    int bullish_signals = 0, bearish_signals = 0;
    datetime last_bull_time = 0, last_bear_time = 0;
    
    // Count recent signals and find most recent
    for (int i = 0; i < SMC_OB_Lookback; i++)
    {
        if (bos_bull[i] != EMPTY_VALUE && bos_bull[i] != 0)
        {
            bullish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bull_time) last_bull_time = signal_time;
        }
        if (bos_bear[i] != EMPTY_VALUE && bos_bear[i] != 0)
        {
            bearish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bear_time) last_bear_time = signal_time;
        }
        if (choch_bull[i] != EMPTY_VALUE && choch_bull[i] != 0)
        {
            bullish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bull_time) last_bull_time = signal_time;
        }
        if (choch_bear[i] != EMPTY_VALUE && choch_bear[i] != 0)
        {
            bearish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bear_time) last_bear_time = signal_time;
        }
    }
    
    // Determine bias based on most recent signal and signal strength
    if (last_bull_time > last_bear_time && bullish_signals >= bearish_signals)
        return BIAS_BULLISH;
    else if (last_bear_time > last_bull_time && bearish_signals >= bullish_signals)
        return BIAS_BEARISH;
    else
        return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Advanced Market Structure Analysis                              |
//+------------------------------------------------------------------+
SMarketStructure GetMarketStructure(int handle)
{
    SMarketStructure structure;
    ZeroMemory(structure);
    
    if (handle == INVALID_HANDLE)
        return structure;
    
    double bos_bull[], bos_bear[], choch_bull[], choch_bear[];
    ArrayResize(bos_bull, 5);
    ArrayResize(bos_bear, 5);
    ArrayResize(choch_bull, 5);
    ArrayResize(choch_bear, 5);
    
    // Get recent structure data
    int bull_bos = CopyBuffer(handle, BUFFER_BULLISH_BOS, 0, 5, bos_bull);
    int bear_bos = CopyBuffer(handle, BUFFER_BEARISH_BOS, 0, 5, bos_bear);
    int bull_choch = CopyBuffer(handle, BUFFER_BULLISH_CHOCH, 0, 5, choch_bull);
    int bear_choch = CopyBuffer(handle, BUFFER_BEARISH_CHOCH, 0, 5, choch_bear);
    
    if (bull_bos <= 0 || bear_bos <= 0 || bull_choch <= 0 || bear_choch <= 0)
        return structure;
    
    // Check for recent structure breaks (last 3 bars)
    for (int i = 0; i < 3; i++)
    {
        if (bos_bull[i] != EMPTY_VALUE && bos_bull[i] != 0)
        {
            structure.bullish_bos = true;
            structure.structure_strength++;
        }
        if (bos_bear[i] != EMPTY_VALUE && bos_bear[i] != 0)
        {
            structure.bearish_bos = true;
            structure.structure_strength++;
        }
        if (choch_bull[i] != EMPTY_VALUE && choch_bull[i] != 0)
        {
            structure.bullish_choch = true;
            structure.structure_strength++;
        }
        if (choch_bear[i] != EMPTY_VALUE && choch_bear[i] != 0)
        {
            structure.bearish_choch = true;
            structure.structure_strength++;
        }
    }
    
    // Get recent high/low levels
    double high[], low[];
    ArrayResize(high, 10);
    ArrayResize(low, 10);
    
    ENUM_TIMEFRAMES timeframe = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                               (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
    
    if (CopyHigh(_Symbol, timeframe, 0, 10, high) > 0 && CopyLow(_Symbol, timeframe, 0, 10, low) > 0)
    {
        int max_index = ArrayMaximum(high, 0, 5);
        int min_index = ArrayMinimum(low, 0, 5);
        
        if (max_index >= 0) 
        {
            structure.recent_high = high[max_index];
            structure.high_time = iTime(_Symbol, timeframe, max_index);
        }
        if (min_index >= 0)
        {
            structure.recent_low = low[min_index];
            structure.low_time = iTime(_Symbol, timeframe, min_index);
        }
    }
    
    return structure;
}

//+------------------------------------------------------------------+
//| Advanced Order Block Detection                                  |
//+------------------------------------------------------------------+
SOrderBlocks GetOrderBlocks(int handle)
{
    SOrderBlocks blocks;
    ZeroMemory(blocks);
    
    if (handle == INVALID_HANDLE)
        return blocks;
    
    double bull_ob_high[], bull_ob_low[], bear_ob_high[], bear_ob_low[];
    ArrayResize(bull_ob_high, SMC_OB_Lookback);
    ArrayResize(bull_ob_low, SMC_OB_Lookback);
    ArrayResize(bear_ob_high, SMC_OB_Lookback);
    ArrayResize(bear_ob_low, SMC_OB_Lookback);
    
    // Get order block data
    int bull_high = CopyBuffer(handle, BUFFER_BULLISH_OB_HIGH, 0, SMC_OB_Lookback, bull_ob_high);
    int bull_low = CopyBuffer(handle, BUFFER_BULLISH_OB_LOW, 0, SMC_OB_Lookback, bull_ob_low);
    int bear_high = CopyBuffer(handle, BUFFER_BEARISH_OB_HIGH, 0, SMC_OB_Lookback, bear_ob_high);
    int bear_low = CopyBuffer(handle, BUFFER_BEARISH_OB_LOW, 0, SMC_OB_Lookback, bear_ob_low);
    
    if (bull_high <= 0 || bull_low <= 0 || bear_high <= 0 || bear_low <= 0)
        return blocks;
    
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double best_bull_distance = DBL_MAX;
    double best_bear_distance = DBL_MAX;
    
    // Find the nearest valid order blocks
    for (int i = 0; i < SMC_OB_Lookback; i++)
    {
        // Check bullish order blocks
        if (bull_ob_high[i] != EMPTY_VALUE && bull_ob_low[i] != EMPTY_VALUE && 
            bull_ob_high[i] != 0 && bull_ob_low[i] != 0)
        {
            double ob_size = (bull_ob_high[i] - bull_ob_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bull_ob_low[i]);
            
            if (ob_size >= MinOBSize && distance < best_bull_distance)
            {
                blocks.bullish_ob_high = bull_ob_high[i];
                blocks.bullish_ob_low = bull_ob_low[i];
                blocks.size_pips = ob_size;
                blocks.is_valid = true;
                best_bull_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                blocks.ob_time = iTime(_Symbol, tf, i);
            }
        }
        
        // Check bearish order blocks
        if (bear_ob_high[i] != EMPTY_VALUE && bear_ob_low[i] != EMPTY_VALUE &&
            bear_ob_high[i] != 0 && bear_ob_low[i] != 0)
        {
            double ob_size = (bear_ob_high[i] - bear_ob_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bear_ob_high[i]);
            
            if (ob_size >= MinOBSize && distance < best_bear_distance)
            {
                blocks.bearish_ob_high = bear_ob_high[i];
                blocks.bearish_ob_low = bear_ob_low[i];
                blocks.size_pips = ob_size;
                blocks.is_valid = true;
                best_bear_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                blocks.ob_time = iTime(_Symbol, tf, i);
            }
        }
    }
    
    return blocks;
}

//+------------------------------------------------------------------+
//| Advanced Fair Value Gap Detection                               |
//+------------------------------------------------------------------+
SFairValueGaps GetFairValueGaps(int handle)
{
    SFairValueGaps gaps;
    ZeroMemory(gaps);
    
    if (handle == INVALID_HANDLE)
        return gaps;
    
    double bull_fvg_high[], bull_fvg_low[], bear_fvg_high[], bear_fvg_low[];
    ArrayResize(bull_fvg_high, SMC_FVG_Lookback);
    ArrayResize(bull_fvg_low, SMC_FVG_Lookback);
    ArrayResize(bear_fvg_high, SMC_FVG_Lookback);
    ArrayResize(bear_fvg_low, SMC_FVG_Lookback);
    
    // Get FVG data
    int bull_high = CopyBuffer(handle, BUFFER_BULLISH_FVG_HIGH, 0, SMC_FVG_Lookback, bull_fvg_high);
    int bull_low = CopyBuffer(handle, BUFFER_BULLISH_FVG_LOW, 0, SMC_FVG_Lookback, bull_fvg_low);
    int bear_high = CopyBuffer(handle, BUFFER_BEARISH_FVG_HIGH, 0, SMC_FVG_Lookback, bear_fvg_high);
    int bear_low = CopyBuffer(handle, BUFFER_BEARISH_FVG_LOW, 0, SMC_FVG_Lookback, bear_fvg_low);
    
    if (bull_high <= 0 || bull_low <= 0 || bear_high <= 0 || bear_low <= 0)
        return gaps;
    
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double best_bull_distance = DBL_MAX;
    double best_bear_distance = DBL_MAX;
    
    // Find the nearest valid FVGs
    for (int i = 0; i < SMC_FVG_Lookback; i++)
    {
        // Check bullish FVGs
        if (bull_fvg_high[i] != EMPTY_VALUE && bull_fvg_low[i] != EMPTY_VALUE &&
            bull_fvg_high[i] != 0 && bull_fvg_low[i] != 0)
        {
            double fvg_size = (bull_fvg_high[i] - bull_fvg_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bull_fvg_low[i]);
            
            if (fvg_size >= 50 && distance < best_bull_distance) // Minimum 5 pip FVG
            {
                gaps.bullish_fvg_high = bull_fvg_high[i];
                gaps.bullish_fvg_low = bull_fvg_low[i];
                gaps.size_pips = fvg_size;
                gaps.is_valid = true;
                best_bull_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                gaps.fvg_time = iTime(_Symbol, tf, i);
            }
        }
        
        // Check bearish FVGs
        if (bear_fvg_high[i] != EMPTY_VALUE && bear_fvg_low[i] != EMPTY_VALUE &&
            bear_fvg_high[i] != 0 && bear_fvg_low[i] != 0)
        {
            double fvg_size = (bear_fvg_high[i] - bear_fvg_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bear_fvg_high[i]);
            
            if (fvg_size >= 50 && distance < best_bear_distance)
            {
                gaps.bearish_fvg_high = bear_fvg_high[i];
                gaps.bearish_fvg_low = bear_fvg_low[i];
                gaps.size_pips = fvg_size;
                gaps.is_valid = true;
                best_bear_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                gaps.fvg_time = iTime(_Symbol, tf, i);
            }
        }
    }
    
    return gaps;
}

//+------------------------------------------------------------------+
//| Advanced Liquidity Level Analysis                               |
//+------------------------------------------------------------------+
SLiquidityLevels GetLiquidityLevels(int handle)
{
    SLiquidityLevels levels;
    ZeroMemory(levels);
    
    if (handle == INVALID_HANDLE)
        return levels;
    
    double eq_highs[], eq_lows[], liq_grab_high[], liq_grab_low[];
    ArrayResize(eq_highs, 10);
    ArrayResize(eq_lows, 10);
    ArrayResize(liq_grab_high, 10);
    ArrayResize(liq_grab_low, 10);
    
    // Get liquidity data
    int eq_high_count = CopyBuffer(handle, BUFFER_EQ_HIGHS, 0, 10, eq_highs);
    int eq_low_count = CopyBuffer(handle, BUFFER_EQ_LOWS, 0, 10, eq_lows);
    int grab_high_count = CopyBuffer(handle, BUFFER_LIQUIDITY_GRAB_HIGH, 0, 10, liq_grab_high);
    int grab_low_count = CopyBuffer(handle, BUFFER_LIQUIDITY_GRAB_LOW, 0, 10, liq_grab_low);
    
    if (eq_high_count <= 0 || eq_low_count <= 0 || grab_high_count <= 0 || grab_low_count <= 0)
        return levels;
    
    // Find recent equal highs and lows
    for (int i = 0; i < 5; i++) // Check last 5 bars
    {
        if (eq_highs[i] != EMPTY_VALUE && eq_highs[i] != 0)
        {
            levels.equal_highs = eq_highs[i];
        }
        if (eq_lows[i] != EMPTY_VALUE && eq_lows[i] != 0)
        {
            levels.equal_lows = eq_lows[i];
        }
    }
    
    // Check for recent liquidity grabs (last 3 bars)
    for (int i = 0; i < 3; i++)
    {
        if (liq_grab_high[i] != EMPTY_VALUE && liq_grab_high[i] != 0)
        {
            levels.liquidity_grab_high = true;
            ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                               (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
            levels.grab_time = iTime(_Symbol, tf, i);
        }
        if (liq_grab_low[i] != EMPTY_VALUE && liq_grab_low[i] != 0)
        {
            levels.liquidity_grab_low = true;
            ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                               (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
            levels.grab_time = iTime(_Symbol, tf, i);
        }
    }
    
    // Calculate swing highs and lows
    double high[], low[];
    ArrayResize(high, 20);
    ArrayResize(low, 20);
    
    ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                       (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
    
    if (CopyHigh(_Symbol, tf, 0, 20, high) > 0 && CopyLow(_Symbol, tf, 0, 20, low) > 0)
    {
        // Find recent swing high
        for (int i = 1; i < 19; i++)
        {
            if (high[i] > high[i-1] && high[i] > high[i+1])
            {
                levels.swing_highs = high[i];
                break;
            }
        }
        
        // Find recent swing low
        for (int i = 1; i < 19; i++)
        {
            if (low[i] < low[i-1] && low[i] < low[i+1])
            {
                levels.swing_lows = low[i];
                break;
            }
        }
    }
    
    return levels;
}

//+------------------------------------------------------------------+
//| Advanced Buy Opportunity Analysis                               |
//+------------------------------------------------------------------+
ENUM_TRADE_TYPE AnalyzeBuyOpportunity(ENUM_MARKET_BIAS bias, SMarketStructure &base, SMarketStructure &confirm,
                                     SOrderBlocks &ob, SFairValueGaps &fvg, SLiquidityLevels &liq,
                                     double price, SMarketConditions &conditions)
{
    // Require bullish or neutral higher timeframe bias
    if (bias == BIAS_BEARISH && RequireHigherTFConfirmation)
        return TRADE_NONE;
    
    double tolerance_pips = 100; // 10 pip tolerance for XAUUSD
    double tolerance = tolerance_pips * PointMultiplier;
    
    // 1. ORDER BLOCK ANALYSIS - Highest Priority
    if (UseOrderBlocks && ob.is_valid && ob.bullish_ob_high > 0 && ob.bullish_ob_low > 0)
    {
        // Check if price is near bullish order block
        if (price >= (ob.bullish_ob_low - tolerance) && price <= (ob.bullish_ob_high + tolerance))
        {
            // Additional confirmation: check for structure alignment
            if ((base.bullish_bos || base.bullish_choch) || !UseConservativeEntries)
            {
                Print("🔍 BUY Order Block Signal Detected:");
                Print("   📊 OB High: ", DoubleToString(ob.bullish_ob_high, _Digits));
                Print("   📊 OB Low: ", DoubleToString(ob.bullish_ob_low, _Digits));
                Print("   📊 Current Price: ", DoubleToString(price, _Digits));
                Print("   📊 OB Size: ", DoubleToString(ob.size_pips, 1), " pips");
                
                return TRADE_ORDER_BLOCK;
            }
        }
    }
    
    // 2. FAIR VALUE GAP ANALYSIS
    if (UseFairValueGaps && fvg.is_valid && fvg.bullish_fvg_high > 0 && fvg.bullish_fvg_low > 0)
    {
        // Check if price is in bullish FVG
        if (price >= fvg.bullish_fvg_low && price <= fvg.bullish_fvg_high)
        {
            // Check for momentum alignment
            if (conditions.rsi_value < 70 && (base.bullish_bos || !UseConservativeEntries))
            {
                Print("🔍 BUY Fair Value Gap Signal Detected:");
                Print("   📊 FVG High: ", DoubleToString(fvg.bullish_fvg_high, _Digits));
                Print("   📊 FVG Low: ", DoubleToString(fvg.bullish_fvg_low, _Digits));
                Print("   📊 Current Price: ", DoubleToString(price, _Digits));
                Print("   📊 FVG Size: ", DoubleToString(fvg.size_pips, 1), " pips");
                
                return TRADE_FAIR_VALUE_GAP;
            }
        }
    }
    
    // 3. LIQUIDITY GRAB ANALYSIS
    if (UseLiquidityGrabs && liq.liquidity_grab_low)
    {
        // After liquidity grab below, look for reversal
        if (TimeCurrent() - liq.grab_time < 3600) // Within 1 hour
        {
            // Check if we have supporting structure
            if (base.bullish_choch || confirm.bullish_choch)
            {
                Print("🔍 BUY Liquidity Grab Signal Detected:");
                Print("   📊 Grab Time: ", TimeToString(liq.grab_time));
                Print("   📊 Structure Support: ", base.bullish_choch ? "Base CHoCH" : "Confirm CHoCH");
                
                return TRADE_LIQUIDITY_GRAB;
            }
        }
    }
    
    // 4. BREAK OF STRUCTURE (BOS) ANALYSIS
    if (base.bullish_bos && base.structure_strength >= 1)
    {
        // Price should be above recent lows for continuation
        if (price > base.recent_low)
        {
            Print("🔍 BUY Break of Structure Signal Detected:");
            Print("   📊 Structure Strength: ", base.structure_strength);
            Print("   📊 Recent Low: ", DoubleToString(base.recent_low, _Digits));
            
            return TRADE_BOS_BREAKOUT;
        }
    }
    
    // 5. CHANGE OF CHARACTER (CHoCH) REVERSAL
    if (base.bullish_choch && conditions.rsi_value < 50)
    {
        // Look for reversal after CHoCH
        if (confirm.bullish_choch || !RequireHigherTFConfirmation)
        {
            Print("🔍 BUY Change of Character Signal Detected:");
            Print("   📊 Base CHoCH: ", base.bullish_choch);
            Print("   📊 Confirm CHoCH: ", confirm.bullish_choch);
            Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
            
            return TRADE_CHOCH_REVERSAL;
        }
    }
    
    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| Advanced Sell Opportunity Analysis                              |
//+------------------------------------------------------------------+
ENUM_TRADE_TYPE AnalyzeSellOpportunity(ENUM_MARKET_BIAS bias, SMarketStructure &base, SMarketStructure &confirm,
                                      SOrderBlocks &ob, SFairValueGaps &fvg, SLiquidityLevels &liq,
                                      double price, SMarketConditions &conditions)
{
    // Require bearish or neutral higher timeframe bias
    if (bias == BIAS_BULLISH && RequireHigherTFConfirmation)
        return TRADE_NONE;
    
    double tolerance_pips = 100; // 10 pip tolerance for XAUUSD
    double tolerance = tolerance_pips * PointMultiplier;
    
    // 1. ORDER BLOCK ANALYSIS - Highest Priority
    if (UseOrderBlocks && ob.is_valid && ob.bearish_ob_high > 0 && ob.bearish_ob_low > 0)
    {
        // Check if price is near bearish order block
        if (price >= (ob.bearish_ob_low - tolerance) && price <= (ob.bearish_ob_high + tolerance))
        {
            // Additional confirmation: check for structure alignment
            if ((base.bearish_bos || base.bearish_choch) || !UseConservativeEntries)
            {
                Print("🔍 SELL Order Block Signal Detected:");
                Print("   📊 OB High: ", DoubleToString(ob.bearish_ob_high, _Digits));
                Print("   📊 OB Low: ", DoubleToString(ob.bearish_ob_low, _Digits));
                Print("   📊 Current Price: ", DoubleToString(price, _Digits));
                Print("   📊 OB Size: ", DoubleToString(ob.size_pips, 1), " pips");
                
                return TRADE_ORDER_BLOCK;
            }
        }
    }
    
    // 2. FAIR VALUE GAP ANALYSIS
    if (UseFairValueGaps && fvg.is_valid && fvg.bearish_fvg_high > 0 && fvg.bearish_fvg_low > 0)
    {
        // Check if price is in bearish FVG
        if (price >= fvg.bearish_fvg_low && price <= fvg.bearish_fvg_high)
        {
            // Check for momentum alignment
            if (conditions.rsi_value > 30 && (base.bearish_bos || !UseConservativeEntries))
            {
                Print("🔍 SELL Fair Value Gap Signal Detected:");
                Print("   📊 FVG High: ", DoubleToString(fvg.bearish_fvg_high, _Digits));
                Print("   📊 FVG Low: ", DoubleToString(fvg.bearish_fvg_low, _Digits));
                Print("   📊 Current Price: ", DoubleToString(price, _Digits));
                Print("   📊 FVG Size: ", DoubleToString(fvg.size_pips, 1), " pips");
                
                return TRADE_FAIR_VALUE_GAP;
            }
        }
    }
    
    // 3. LIQUIDITY GRAB ANALYSIS
    if (UseLiquidityGrabs && liq.liquidity_grab_high)
    {
        // After liquidity grab above, look for reversal
        if (TimeCurrent() - liq.grab_time < 3600) // Within 1 hour
        {
            // Check if we have supporting structure
            if (base.bearish_choch || confirm.bearish_choch)
            {
                Print("🔍 SELL Liquidity Grab Signal Detected:");
                Print("   📊 Grab Time: ", TimeToString(liq.grab_time));
                Print("   📊 Structure Support: ", base.bearish_choch ? "Base CHoCH" : "Confirm CHoCH");
                
                return TRADE_LIQUIDITY_GRAB;
            }
        }
    }
    
    // 4. BREAK OF STRUCTURE (BOS) ANALYSIS
    if (base.bearish_bos && base.structure_strength >= 1)
    {
        // Price should be below recent highs for continuation
        if (price < base.recent_high)
        {
            Print("🔍 SELL Break of Structure Signal Detected:");
            Print("   📊 Structure Strength: ", base.structure_strength);
            Print("   📊 Recent High: ", DoubleToString(base.recent_high, _Digits));
            
            return TRADE_BOS_BREAKOUT;
        }
    }
    
    // 5. CHANGE OF CHARACTER (CHoCH) REVERSAL
    if (base.bearish_choch && conditions.rsi_value > 50)
    {
        // Look for reversal after CHoCH
        if (confirm.bearish_choch || !RequireHigherTFConfirmation)
        {
            Print("🔍 SELL Change of Character Signal Detected:");
            Print("   📊 Base CHoCH: ", base.bearish_choch);
            Print("   📊 Confirm CHoCH: ", confirm.bearish_choch);
            Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
            
            return TRADE_CHOCH_REVERSAL;
        }
    }
    
    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| ADVANCED POSITION MANAGEMENT - MASTERPIECE IMPLEMENTATION      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Advanced Breakeven Management                                   |
//+------------------------------------------------------------------+
void MoveToBreakeven(ulong ticket)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    // Calculate breakeven level with small buffer
    double be_buffer = 20 * PointMultiplier; // 2 pip buffer for XAUUSD
    double new_sl = 0;
    
    if (pos_type == POSITION_TYPE_BUY)
    {
        new_sl = open_price + be_buffer;
        
        // Only move if new SL is better than current
        if (current_sl == 0 || new_sl > current_sl)
        {
            if (Trade.PositionModify(ticket, new_sl, current_tp))
            {
                Print("✅ BREAKEVEN MOVED - BUY Position #", ticket);
                Print("   📊 Old SL: ", DoubleToString(current_sl, _Digits));
                Print("   📊 New SL: ", DoubleToString(new_sl, _Digits), " (BE + 2 pips)");
                Print("   📊 Open: ", DoubleToString(open_price, _Digits));
                
                if (EnableAlerts)
                {
                    Alert("SMC Gold EA: Breakeven moved for BUY #", ticket);
                }
            }
            else
            {
                Print("❌ Failed to move breakeven for position #", ticket, " - Error: ", GetLastError());
            }
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        new_sl = open_price - be_buffer;
        
        // Only move if new SL is better than current
        if (current_sl == 0 || new_sl < current_sl)
        {
            if (Trade.PositionModify(ticket, new_sl, current_tp))
            {
                Print("✅ BREAKEVEN MOVED - SELL Position #", ticket);
                Print("   📊 Old SL: ", DoubleToString(current_sl, _Digits));
                Print("   📊 New SL: ", DoubleToString(new_sl, _Digits), " (BE - 2 pips)");
                Print("   📊 Open: ", DoubleToString(open_price, _Digits));
                
                if (EnableAlerts)
                {
                    Alert("SMC Gold EA: Breakeven moved for SELL #", ticket);
                }
            }
            else
            {
                Print("❌ Failed to move breakeven for position #", ticket, " - Error: ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Advanced Trailing Stop Management                               |
//+------------------------------------------------------------------+
void UpdateTrailingStop(ulong ticket, double profit_pips)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    double current_price = (pos_type == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    // Dynamic trailing distance based on profit
    double trailing_distance = TrailingStopPips;
    
    // Tighten trailing stop as profit increases
    if (profit_pips > 500) // 50+ pips profit
        trailing_distance = TrailingStopPips * 0.6; // Tighter trailing
    else if (profit_pips > 300) // 30+ pips profit
        trailing_distance = TrailingStopPips * 0.8;
    
    double trail_distance = trailing_distance * PointMultiplier;
    double new_sl = 0;
    bool should_update = false;
    
    if (pos_type == POSITION_TYPE_BUY)
    {
        new_sl = current_price - trail_distance;
        
        // Only trail if new SL is better than current
        if (current_sl == 0 || new_sl > current_sl)
        {
            should_update = true;
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        new_sl = current_price + trail_distance;
        
        // Only trail if new SL is better than current
        if (current_sl == 0 || new_sl < current_sl)
        {
            should_update = true;
        }
    }
    
    if (should_update)
    {
        if (Trade.PositionModify(ticket, new_sl, current_tp))
        {
            Print("✅ TRAILING STOP UPDATED - ", EnumToString(pos_type), " Position #", ticket);
            Print("   📊 Profit: ", DoubleToString(profit_pips, 1), " pips");
            Print("   📊 Old SL: ", DoubleToString(current_sl, _Digits));
            Print("   📊 New SL: ", DoubleToString(new_sl, _Digits));
            Print("   📊 Trail Distance: ", DoubleToString(trailing_distance, 1), " pips");
            Print("   📊 Current Price: ", DoubleToString(current_price, _Digits));
        }
        else
        {
            Print("❌ Failed to update trailing stop for position #", ticket, " - Error: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Advanced Partial Close Management                               |
//+------------------------------------------------------------------+
void PartialClosePosition(ulong ticket)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double current_volume = PositionGetDouble(POSITION_VOLUME);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    // Check if position hasn't been partially closed already
    string comment = PositionGetString(POSITION_COMMENT);
    if (StringFind(comment, "PARTIAL") >= 0)
        return; // Already partially closed
    
    // Calculate partial close volume
    double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    double partial_volume = current_volume * (PartialClosePercent / 100.0);
    
    // Normalize partial volume
    partial_volume = NormalizeDouble(partial_volume / lot_step, 0) * lot_step;
    partial_volume = MathMax(partial_volume, min_lot);
    
    // Ensure we don't close more than we have
    if (partial_volume >= current_volume)
        partial_volume = current_volume - min_lot;
    
    if (partial_volume >= min_lot)
    {
        if (Trade.PositionClosePartial(ticket, partial_volume))
        {
            double profit_pips = CalculateProfitPips(ticket);
            
            Print("✅ PARTIAL CLOSE EXECUTED - ", EnumToString(pos_type), " Position #", ticket);
            Print("   📊 Closed Volume: ", DoubleToString(partial_volume, 2));
            Print("   📊 Remaining Volume: ", DoubleToString(current_volume - partial_volume, 2));
            Print("   📊 Profit at Close: ", DoubleToString(profit_pips, 1), " pips");
            Print("   📊 Partial %: ", DoubleToString(PartialClosePercent, 1), "%");
            
            // Move remaining position to breakeven for risk-free trading
            Sleep(1000); // Wait for partial close to process
            if (PositionSelectByTicket(ticket))
            {
                MoveToBreakeven(ticket);
            }
            
            if (EnableAlerts)
            {
                Alert("SMC Gold EA: Partial close executed for ", EnumToString(pos_type), " #", ticket, 
                      " - ", DoubleToString(PartialClosePercent, 0), "% closed");
            }
        }
        else
        {
            Print("❌ Failed to partially close position #", ticket, " - Error: ", GetLastError());
        }
    }
    else
    {
        Print("⚠️ Cannot partially close position #", ticket, " - Volume too small");
    }
}

//+------------------------------------------------------------------+
//| Enhanced Position Management with SMC Logic                     |
//+------------------------------------------------------------------+
void ManageOpenPositions(SMarketConditions &conditions)
{
    static datetime last_management_time = 0;
    
    // Don't manage too frequently
    if (TimeCurrent() - last_management_time < 30) // Every 30 seconds
        return;
        
    last_management_time = TimeCurrent();
    
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
            
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        double profit_pips = CalculateProfitPips(ticket);
        double profit_money = PositionGetDouble(POSITION_PROFIT);
        ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
        int position_age_minutes = (int)((TimeCurrent() - open_time) / 60);
        
        // Get current market structure for exit signals
        SMarketStructure current_structure = GetMarketStructure(SMC_Base_Handle);
        
        // Emergency exit on opposing structure signals
        bool emergency_exit = false;
        if (pos_type == POSITION_TYPE_BUY && current_structure.bearish_bos && profit_pips < 100)
        {
            emergency_exit = true;
            Print("🚨 EMERGENCY EXIT: BUY position facing bearish BOS");
        }
        else if (pos_type == POSITION_TYPE_SELL && current_structure.bullish_bos && profit_pips < 100)
        {
            emergency_exit = true;
            Print("🚨 EMERGENCY EXIT: SELL position facing bullish BOS");
        }
        
        if (emergency_exit)
        {
            if (Trade.PositionClose(ticket))
            {
                Print("✅ Emergency close executed for position #", ticket);
                continue;
            }
        }
        
        // Regular position management
        static bool breakeven_moved[];
        static bool partial_closed[];
        ArrayResize(breakeven_moved, PositionsTotal(), PositionsTotal());
        ArrayResize(partial_closed, PositionsTotal(), PositionsTotal());
        
        // Breakeven management
        if (UseBreakeven && profit_pips >= BreakevenPips)
        {
            if (i < ArraySize(breakeven_moved) && !breakeven_moved[i])
            {
                MoveToBreakeven(ticket);
                breakeven_moved[i] = true;
            }
        }
        
        // Trailing stop management
        if (UseTrailingStop && profit_pips >= TrailingStopPips)
        {
            UpdateTrailingStop(ticket, profit_pips);
        }
        
        // Partial close management
        if (EnablePartialClose && profit_pips >= PartialClosePips)
        {
            if (i < ArraySize(partial_closed) && !partial_closed[i])
            {
                PartialClosePosition(ticket);
                partial_closed[i] = true;
            }
        }
        
        // Time-based management for losing positions
        if (position_age_minutes > 240 && profit_pips < -100) // 4 hours old and losing 10+ pips
        {
            Print("⚠️ Position #", ticket, " is old and losing. Age: ", position_age_minutes, " min, Profit: ", DoubleToString(profit_pips, 1), " pips");
            
            // Consider closing if market structure has changed significantly
            if ((pos_type == POSITION_TYPE_BUY && current_structure.bearish_choch) ||
                (pos_type == POSITION_TYPE_SELL && current_structure.bullish_choch))
            {
                Print("📊 Market structure changed - considering position close");
                
                if (Trade.PositionClose(ticket))
                {
                    Print("✅ Closed old losing position #", ticket, " due to structure change");
                }
            }
        }
        
        // Advanced profit management for large wins
        if (profit_pips > 1000) // 100+ pip profit
        {
            Print("🎯 Large profit detected: ", DoubleToString(profit_pips, 1), " pips on position #", ticket);
            
            // Close 25% more if not already done
            string comment = PositionGetString(POSITION_COMMENT);
            if (StringFind(comment, "LARGE_PROFIT") < 0)
            {
                double current_volume = PositionGetDouble(POSITION_VOLUME);
                double additional_close = current_volume * 0.25;
                
                if (additional_close >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
                {
                    if (Trade.PositionClosePartial(ticket, additional_close))
                    {
                        Print("✅ Additional 25% closed due to large profit");
                    }
                }
            }
        }
    }
}

// Error description function
string ErrorDescription(int error_code)
{
    switch(error_code)
    {
        case 10004: return "Requote";
        case 10006: return "Request rejected";
        case 10007: return "Request canceled by trader";
        case 10008: return "Order placed";
        case 10009: return "Request completed";
        case 10010: return "Only part of the request was completed";
        case 10011: return "Request processing error";
        case 10012: return "Request canceled by timeout";
        case 10013: return "Invalid request";
        case 10014: return "Invalid volume in the request";
        case 10015: return "Invalid price in the request";
        case 10016: return "Invalid stops in the request";
        case 10017: return "Trade is disabled";
        case 10018: return "Market is closed";
        case 10019: return "Not enough money";
        case 10020: return "Prices changed";
        case 10021: return "No quotes";
        case 10022: return "Invalid expiration date";
        case 10023: return "Order state changed";
        case 10024: return "Too frequent requests";
        case 10025: return "No changes in request";
        case 10026: return "Autotrading disabled by server";
        case 10027: return "Autotrading disabled by client terminal";
        case 10028: return "Request locked for processing";
        case 10029: return "Order or position frozen";
        case 10030: return "Invalid order filling type";
        case 10031: return "No connection with the trade server";
        case 10032: return "Operation is allowed only for live accounts";
        case 10033: return "Exceeded limit of pending orders";
        case 10034: return "Exceeded limit of orders/positions";
        case 10035: return "Incorrect or prohibited order type";
        case 10036: return "Position with the specified POSITION_IDENTIFIER already closed";
        default: return "Unknown error " + IntegerToString(error_code);
    }
}
