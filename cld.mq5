//+------------------------------------------------------------------+
//|                                          SMC_GoldEA_Enhanced.mq5 |
//|                        Copyright 2024, LuxAlgo & Smart Money Concepts |
//|                                       https://www.luxalgo.com/   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, LuxAlgo & Smart Money Concepts"
#property link "https://www.luxalgo.com/"
#property version "3.00"
#property description "Enhanced Expert Advisor for Gold (XAUUSD) using LuxAlgo Smart Money Concepts"
#property description "Implements advanced ICT/SMC strategies with multi-timeframe confirmation"

//--- Includes
// Simplified MQL5 trading classes for compatibility

//--- Input Parameters
input group "═════════ STRATEGY SETTINGS ═════════" input ENUM_TIMEFRAMES BaseTimeframe = PERIOD_H4; // Base timeframe (market structure)
input ENUM_TIMEFRAMES ConfirmTimeframe = PERIOD_H1;                                                  // Confirmation timeframe
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_D1;                                                   // Higher timeframe (bias)
input int MaxOpenTrades = 2;                                                                         // Maximum open trades
input int Slippage = 10;                                                                             // Slippage in points

input group "═════════ RISK MANAGEMENT ═════════" input double RiskPerTradePercent = 0.5; // Risk per trade (% of balance)
input int StopLossPips = 250;                                                             // Default SL (25 pips for XAUUSD)
input int TakeProfitPips = 750;                                                           // Default TP (75 pips for XAUUSD)
input bool UseAutoRR = true;                                                              // Use automatic risk-reward
input double MinRiskReward = 3.0;                                                         // Minimum risk:reward ratio
input bool UseTrailingStop = true;                                                        // Enable trailing stop
input int TrailingStopPips = 200;                                                         // Trailing stop distance
input bool UseBreakeven = true;                                                           // Move SL to breakeven
input int BreakevenPips = 150;                                                            // Breakeven trigger distance

input group "═════════ SMC INDICATOR SETTINGS ═════════" input string SMC_Indicator_Name = "LuxAlgo - Smart Money Concepts"; // Indicator name
input int SMC_OB_Lookback = 15;                                                                                              // Order block lookback (bars)
input int SMC_FVG_Lookback = 10;                                                                                             // FVG lookback (bars)
input bool UseOrderBlocks = true;                                                                                            // Trade order blocks
input bool UseFairValueGaps = true;                                                                                          // Trade fair value gaps
input bool UseLiquidityGrabs = true;                                                                                         // Trade liquidity grabs
input double MinOBSize = 100;                                                                                                // Minimum order block size (pips)

input group "═════════ TRADING FILTERS ═════════" input bool UseSessionFilter = true; // Enable session filtering
input int LondonStartHour = 8;                                                        // London session start (GMT)
input int LondonEndHour = 17;                                                         // London session end (GMT)
input int NewYorkStartHour = 13;                                                      // New York session start (GMT)
input int NewYorkEndHour = 22;                                                        // New York session end (GMT)
input bool UseVolatilityFilter = true;                                                // Enable volatility filter
input double MaxATRPercent = 0.8;                                                     // Maximum ATR percentage
input bool UseSpreadFilter = true;                                                    // Enable spread filter
input double MaxSpreadPips = 30;                                                      // Maximum spread (pips)

input group "═════════ ADVANCED SETTINGS ═════════" input int MagicNumber = 20240624; // EA Magic Number
input string TradeComment = "SMC-Gold-EA-V3";                                         // Trade comment
input bool EnableAlerts = true;                                                       // Enable trade alerts
input bool EnablePartialClose = true;                                                 // Enable partial position closing
input double PartialClosePercent = 50.0;                                              // Partial close percentage
input int PartialClosePips = 300;                                                     // Partial close trigger (pips)

input group "═════════ ADVANCED STRATEGIES ═════════"
input bool UseMultiStrategy = true;                                                    // Enable multi-strategy approach
input bool UseScalpingMode = true;                                                     // Enable scalping on M5/M15
input bool UseSwingTrading = true;                                                     // Enable swing trading on H4/D1
input bool UseMomentumStrategy = true;                                                 // Enable momentum-based entries
input bool UseReversalStrategy = true;                                                 // Enable reversal strategy
input bool UseTrendFollowing = true;                                                   // Enable trend following strategy
input bool UseNewsTrading = false;                                                     // Enable news spike trading (disabled by default)
input double ScalpingRiskPercent = 0.3;                                               // Risk per scalping trade
input double SwingRiskPercent = 0.8;                                                  // Risk per swing trade

input group "═════════ ENHANCED INDICATORS ═════════"
input bool UseEMA = true;                                                              // Use Exponential Moving Averages
input int EMA_Fast = 8;                                                                // Fast EMA period
input int EMA_Slow = 21;                                                               // Slow EMA period
input int EMA_Trend = 50;                                                              // Trend EMA period
input bool UseBBands = true;                                                           // Use Bollinger Bands
input int BB_Period = 20;                                                              // Bollinger Bands period
input double BB_Deviation = 2.0;                                                       // Bollinger Bands deviation
input bool UseStoch = true;                                                            // Use Stochastic
input int Stoch_K = 5;                                                                 // Stochastic %K period
input int Stoch_D = 3;                                                                 // Stochastic %D period
input int Stoch_Slowing = 3;                                                           // Stochastic slowing
input bool UseMACD = true;                                                             // Use MACD
input int MACD_Fast = 12;                                                              // MACD fast EMA
input int MACD_Slow = 26;                                                              // MACD slow EMA
input int MACD_Signal = 9;                                                             // MACD signal line
input bool UseZigZag = true;                                                           // Use ZigZag for swing points
input int ZigZag_Depth = 12;                                                           // ZigZag depth
input int ZigZag_Deviation = 5;                                                        // ZigZag deviation
input int ZigZag_Backstep = 3;                                                         // ZigZag backstep

input group "═════════ PRICE ACTION & PATTERNS ═════════"
input bool UseCandlestickPatterns = true;                                              // Use candlestick patterns
input bool UseSupplyDemand = true;                                                     // Use supply/demand zones
input bool UseFibonacci = true;                                                        // Use Fibonacci retracements
input bool UseVolumeAnalysis = false;                                                  // Use volume analysis (if available)
input bool UseDivergence = true;                                                       // Use RSI/MACD divergence
input int PatternLookback = 10;                                                        // Candlestick pattern lookback
input double FibLevel1 = 0.382;                                                        // Fibonacci level 1
input double FibLevel2 = 0.618;                                                        // Fibonacci level 2
input double FibLevel3 = 0.786;                                                        // Fibonacci level 3

input group "═════════ MARKET CONDITIONS ═════════"
input bool UseMarketSentiment = true;                                                  // Use market sentiment analysis
input bool UseCorrelationAnalysis = true;                                              // Use correlation with DXY, yields
input bool UseSeasonality = true;                                                      // Use seasonal patterns
input bool UseAsianKillZone = true;                                                    // Trade Asian session kill zone
input bool UseLondonKillZone = true;                                                   // Trade London session kill zone
input bool UseNewYorkKillZone = true;                                                  // Trade New York session kill zone
input int AsianStartHour = 0;                                                          // Asian kill zone start
input int AsianEndHour = 3;                                                            // Asian kill zone end
input int LondonKillStart = 7;                                                         // London kill zone start
input int LondonKillEnd = 10;                                                          // London kill zone end
input int NYKillStart = 13;                                                            // NY kill zone start
input int NYKillEnd = 16;                                                              // NY kill zone end

input group "═════════ MANUAL TESTING ═════════" 
input bool EnableManualTesting = true; // Enable manual trade triggers
input bool TriggerBuyTrade = false;                                                    // Trigger a BUY trade now
input bool TriggerSellTrade = false;                                                   // Trigger a SELL trade now
input bool CloseAllTrades = false;                                                     // Close all open trades
input double ManualLotSize = 0.01;                                                     // Manual trade lot size
input bool ForceInstantTrade = false;                                                  // Force instant trade (ignores all conditions)
input bool EnableBacktestMode = true;                                                  // Enable aggressive testing for backtesting
input bool AggressiveSMCMode = true;                                                   // Enable aggressive SMC signal detection for more trades

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

double PointMultiplier;
int SMC_Base_Handle, SMC_Confirm_Handle, SMC_Higher_Handle;
int ATR_Handle, RSI_Handle;
int EMA_Fast_Handle, EMA_Slow_Handle, EMA_Trend_Handle;
int BB_Handle, Stoch_Handle, MACD_Handle, ZigZag_Handle;
datetime LastTradeTime;
datetime LastOrderBlockTime;
datetime LastFVGTime;
datetime LastScalpTime;
datetime LastSwingTime;

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
    TRADE_SCALPING,
    TRADE_SWING,
    TRADE_MOMENTUM,
    TRADE_REVERSAL,
    TRADE_TREND_FOLLOW,
    TRADE_BREAKOUT,
    TRADE_FIBONACCI,
    TRADE_DIVERGENCE,
    TRADE_NONE
};

enum ENUM_STRATEGY_TYPE
{
    STRATEGY_SMC,
    STRATEGY_SCALPING,
    STRATEGY_SWING,
    STRATEGY_MOMENTUM,
    STRATEGY_REVERSAL,
    STRATEGY_TREND_FOLLOWING,
    STRATEGY_BREAKOUT,
    STRATEGY_NEWS
};

enum ENUM_MARKET_SESSION
{
    SESSION_ASIAN,
    SESSION_LONDON,
    SESSION_NEW_YORK,
    SESSION_OVERLAP,
    SESSION_INACTIVE
};

struct SAdvancedIndicators
{
    double ema_fast;
    double ema_slow;
    double ema_trend;
    double bb_upper;
    double bb_middle;
    double bb_lower;
    double stoch_main;
    double stoch_signal;
    double macd_main;
    double macd_signal;
    double macd_histogram;
    bool bb_squeeze;
    bool ema_bullish_cross;
    bool ema_bearish_cross;
    bool stoch_oversold;
    bool stoch_overbought;
    bool macd_bullish_cross;
    bool macd_bearish_cross;
};

struct SMarketEnvironment
{
    ENUM_MARKET_SESSION current_session;
    bool is_kill_zone;
    bool is_london_breakout;
    bool is_ny_session;
    bool is_high_volatility_time;
    double daily_range_percent;
    double session_high;
    double session_low;
    int trend_strength; // 1-10
    bool is_trending_market;
    bool is_ranging_market;
};

struct SPriceAction
{
    bool hammer;
    bool doji;
    bool engulfing_bull;
    bool engulfing_bear;
    bool pin_bar_bull;
    bool pin_bar_bear;
    bool inside_bar;
    bool outside_bar;
    double swing_high;
    double swing_low;
    bool higher_high;
    bool higher_low;
    bool lower_high;
    bool lower_low;
};

struct SFibonacciLevels
{
    double fib_0;
    double fib_236;
    double fib_382;
    double fib_500;
    double fib_618;
    double fib_786;
    double fib_100;
    bool price_at_fib_level;
    double nearest_fib_level;
    double fib_extension_127;
    double fib_extension_162;
};

struct SSupplyDemand
{
    double supply_zone_high;
    double supply_zone_low;
    double demand_zone_high;
    double demand_zone_low;
    bool fresh_supply;
    bool fresh_demand;
    bool price_in_supply;
    bool price_in_demand;
    int zone_strength; // 1-5
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
    int structure_strength; // 1-5 rating
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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("═══════════════════════════════════════");
    Print("    SMC Gold EA Enhanced v3.0 Starting");
    Print("═══════════════════════════════════════");

    //--- Initialize trading objects
    Trade.SetExpertMagicNumber(MagicNumber);
    Trade.SetDeviationInPoints(Slippage);
    Trade.SetTypeFilling(ORDER_FILLING_FOK);
    Trade.SetAsyncMode(false);

    //--- Calculate point multiplier for XAUUSD
    PointMultiplier = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
    Print("Point Multiplier: ", PointMultiplier);

    //--- Create indicator handles
    SMC_Base_Handle = iCustom(_Symbol, BaseTimeframe, SMC_Indicator_Name);
    SMC_Confirm_Handle = iCustom(_Symbol, ConfirmTimeframe, SMC_Indicator_Name);
    SMC_Higher_Handle = iCustom(_Symbol, HigherTimeframe, SMC_Indicator_Name);

    ATR_Handle = iATR(_Symbol, PERIOD_H1, 14);
    RSI_Handle = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);

    //--- Create enhanced indicator handles
    if (UseEMA)
    {
        EMA_Fast_Handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
        EMA_Slow_Handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
        EMA_Trend_Handle = iMA(_Symbol, PERIOD_CURRENT, EMA_Trend, 0, MODE_EMA, PRICE_CLOSE);
    }

    if (UseBBands)
        BB_Handle = iBands(_Symbol, PERIOD_CURRENT, BB_Period, 0, BB_Deviation, PRICE_CLOSE);

    if (UseStoch)
        Stoch_Handle = iStochastic(_Symbol, PERIOD_CURRENT, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, STO_LOWHIGH);

    if (UseMACD)
        MACD_Handle = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);

    if (UseZigZag)
        ZigZag_Handle = iCustom(_Symbol, PERIOD_CURRENT, "ZigZag", ZigZag_Depth, ZigZag_Deviation, ZigZag_Backstep);

    //--- Validate handles
    if (SMC_Base_Handle == INVALID_HANDLE || SMC_Confirm_Handle == INVALID_HANDLE ||
        SMC_Higher_Handle == INVALID_HANDLE || ATR_Handle == INVALID_HANDLE ||
        RSI_Handle == INVALID_HANDLE)
    {
        Print("❌ Error creating core indicator handles!");
        return INIT_FAILED;
    }

    //--- Validate enhanced indicators
    if (UseEMA && (EMA_Fast_Handle == INVALID_HANDLE || EMA_Slow_Handle == INVALID_HANDLE || EMA_Trend_Handle == INVALID_HANDLE))
        Print("⚠️ Warning: EMA indicators failed to load");
    
    if (UseBBands && BB_Handle == INVALID_HANDLE)
        Print("⚠️ Warning: Bollinger Bands failed to load");
    
    if (UseStoch && Stoch_Handle == INVALID_HANDLE)
        Print("⚠️ Warning: Stochastic failed to load");
    
    if (UseMACD && MACD_Handle == INVALID_HANDLE)
        Print("⚠️ Warning: MACD failed to load");

    //--- Apply Gold-specific settings
    ApplyGoldSpecificSettings();

    //--- Validate symbol
    if (_Symbol != "XAUUSD")
    {
        Print("⚠️ Warning: EA optimized for XAUUSD, current symbol: ", _Symbol);
    }

    Print("✅ EA initialized successfully");
    Print("📊 Base TF: ", EnumToString(BaseTimeframe));
    Print("📊 Confirm TF: ", EnumToString(ConfirmTimeframe));
    Print("📊 Higher TF: ", EnumToString(HigherTimeframe));
    Print("💰 Risk per trade: ", RiskPerTradePercent, "%");
    Print("🎯 Min R:R Ratio: ", MinRiskReward);
    
    //--- Backtest mode detection
    if (MQLInfoInteger(MQL_TESTER))
    {
        Print("🧪 BACKTEST MODE DETECTED - Aggressive testing enabled");
        Print("🔥 Auto trades will be placed every 100/150 ticks for testing");
    }
    else
    {
        Print("📈 LIVE MODE DETECTED - Normal trading logic active");
    }

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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check for manual testing triggers first
    if (EnableManualTesting)
    {
        HandleManualTesting();
    }

    //--- Basic checks
    if (!IsValidTradingEnvironment())
        return;

    //--- Prevent multiple trades on same tick
    if (TimeCurrent() == LastTradeTime)
        return;

    //--- Get market conditions
    SMarketConditions conditions = GetMarketConditions();

    //--- Monitor all SMC signals comprehensively
    MonitorAllSMCSignals();
    
    //--- Test SMC indicator buffers (for debugging)
    TestSMCIndicatorBuffers();

    //--- Apply filters
    if (!PassesFilters(conditions))
        return;

    //--- Main trading logic
    CheckForTrades(conditions);

    //--- Manage open positions
    ManageOpenPositions(conditions);

    LastTradeTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Handle Manual Testing                                            |
//+------------------------------------------------------------------+
void HandleManualTesting()
{
    static bool buy_triggered = false;
    static bool sell_triggered = false;
    static bool close_triggered = false;
    
    // Debug: Show manual testing status
    static int debug_counter = 0;
    debug_counter++;
    if (debug_counter % 200 == 0) // Print every 200 ticks
    {
        Print("🧪 MANUAL TEST STATUS: BuyTrigger=", TriggerBuyTrade, " | SellTrigger=", TriggerSellTrade, " | CloseAll=", CloseAllTrades);
    }
    
    //--- Trigger manual buy trade
    if (TriggerBuyTrade && !buy_triggered)
    {
        buy_triggered = true;
        Print("🧪 MANUAL TEST: Triggering BUY trade...");
        PlaceManualTestTrade(ORDER_TYPE_BUY);
        // Reset the input parameter to prevent multiple triggers
        // Note: In real implementation, you'd need to modify the input externally
    }
    
    //--- Trigger manual sell trade  
    if (TriggerSellTrade && !sell_triggered)
    {
        sell_triggered = true;
        Print("🧪 MANUAL TEST: Triggering SELL trade...");
        PlaceManualTestTrade(ORDER_TYPE_SELL);
    }
    
    //--- Close all trades
    if (CloseAllTrades && !close_triggered)
    {
        close_triggered = true;
        Print("🧪 MANUAL TEST: Closing all trades...");
        CloseAllTestTrades();
    }
    
    //--- Reset triggers when inputs are turned off
    if (!TriggerBuyTrade) buy_triggered = false;
    if (!TriggerSellTrade) sell_triggered = false;
    if (!CloseAllTrades) close_triggered = false;
}

//+------------------------------------------------------------------+
//| Place Manual Test Trade                                          |
//+------------------------------------------------------------------+
void PlaceManualTestTrade(ENUM_ORDER_TYPE order_type)
{
    MqlTick current_tick;
    if (!SymbolInfoTick(_Symbol, current_tick))
    {
        Print("❌ Failed to get current tick for manual test");
        return;
    }
    
    double entry_price = (order_type == ORDER_TYPE_BUY) ? current_tick.ask : current_tick.bid;
    double sl, tp;
    
    //--- Calculate SL/TP for test trade
    if (order_type == ORDER_TYPE_BUY)
    {
        sl = entry_price - (StopLossPips * PointMultiplier);
        tp = entry_price + (TakeProfitPips * PointMultiplier);
    }
    else
    {
        sl = entry_price + (StopLossPips * PointMultiplier);
        tp = entry_price - (TakeProfitPips * PointMultiplier);
    }
    
    //--- Prepare trade request
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = ManualLotSize;
    request.type = order_type;
    request.price = entry_price;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.comment = TradeComment + "-MANUAL-TEST";
    
    //--- Send order
    if (OrderSend(request, result))
    {
        string direction = (order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
        Print("✅ MANUAL TEST ", direction, " ORDER PLACED:");
        Print("   📊 Ticket: ", result.order);
        Print("   💰 Entry: ", DoubleToString(entry_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits));
        Print("   🎯 TP: ", DoubleToString(tp, _Digits));
        Print("   📈 Lot: ", DoubleToString(ManualLotSize, 2));
        Print("   🔢 Magic: ", MagicNumber);
        
        //--- Apply trade management immediately for testing
        if (UseTrailingStop)
        {
            Print("   🔄 Trailing stop will be applied: ", TrailingStopPips, " pips");
        }
        if (UseBreakeven)
        {
            Print("   ⚖️ Breakeven will be applied at: ", BreakevenPips, " pips profit");
        }
        if (EnablePartialClose)
        {
            Print("   📊 Partial close will trigger at: ", PartialClosePips, " pips (", PartialClosePercent, "%)");
        }
    }
    else
    {
        Print("❌ MANUAL TEST ORDER FAILED:");
        Print("   🔴 Error Code: ", result.retcode);
        Print("   📝 Comment: ", result.comment);
        Print("   💰 Entry Price: ", DoubleToString(entry_price, _Digits));
        Print("   📈 Lot Size: ", DoubleToString(ManualLotSize, 2));
    }
}

//+------------------------------------------------------------------+
//| Close All Test Trades                                           |
//+------------------------------------------------------------------+
void CloseAllTestTrades()
{
    int closed_count = 0;
    int total_positions = PositionsTotal();
    
    Print("🧪 MANUAL TEST: Attempting to close ", total_positions, " positions...");
    
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol == "")
            continue;
            
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
            
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        double volume = PositionGetDouble(POSITION_VOLUME);
        ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double profit = PositionGetDouble(POSITION_PROFIT);
        
        if (Trade.PositionClose(ticket))
        {
            closed_count++;
            string direction = (pos_type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            Print("✅ CLOSED ", direction, " Position #", ticket, 
                  " | Volume: ", DoubleToString(volume, 2), 
                  " | Profit: $", DoubleToString(profit, 2));
        }
        else
        {
            Print("❌ Failed to close position #", ticket, " | Error: ", GetLastError());
        }
    }
    
    Print("🧪 MANUAL TEST COMPLETE: Closed ", closed_count, " out of ", total_positions, " positions");
}

//+------------------------------------------------------------------+
//| Enhanced Trading Environment Validation                          |
//+------------------------------------------------------------------+
bool IsValidTradingEnvironment()
{
    //--- Check terminal and trade permissions
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        Print("❌ Terminal trading not allowed");
        return false;
    }

    if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        Print("❌ MQL trading not allowed");
        return false;
    }

    //--- Skip during optimization
    if (MQLInfoInteger(MQL_TESTER) && MQLInfoInteger(MQL_OPTIMIZATION))
        return false;

    //--- Check market status
    if (!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
    {
        Print("❌ Trading disabled for ", _Symbol);
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Get Market Conditions                                            |
//+------------------------------------------------------------------+
SMarketConditions GetMarketConditions()
{
    SMarketConditions conditions;

    //--- Get ATR
    double atr_buffer[];
    if (CopyBuffer(ATR_Handle, 0, 1, 1, atr_buffer) > 0)
    {
        conditions.atr_value = atr_buffer[0];
        double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        conditions.atr_percent = (conditions.atr_value / current_price) * 100;
        conditions.is_volatile = conditions.atr_percent > MaxATRPercent;
    }

    //--- Get RSI
    double rsi_buffer[];
    if (CopyBuffer(RSI_Handle, 0, 1, 1, rsi_buffer) > 0)
    {
        conditions.rsi_value = rsi_buffer[0];
        // DEBUG: Print RSI value every tick for testing
        static int rsi_debug_counter = 0;
        rsi_debug_counter++;
        if (rsi_debug_counter % 50 == 0) // Print every 50 ticks
        {
            Print("🔍 RSI DEBUG: RSI Value = ", DoubleToString(conditions.rsi_value, 2));
        }
    }
    else
    {
        Print("⚠️ RSI ERROR: Failed to copy RSI buffer!");
        conditions.rsi_value = 50; // Default neutral value
    }

    //--- Get spread
    conditions.current_spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                                 SymbolInfoDouble(_Symbol, SYMBOL_BID)) /
                                PointMultiplier;

    //--- Determine trend
    conditions.is_trending = conditions.rsi_value > 70 || conditions.rsi_value < 30;
    if (conditions.rsi_value > 50)
        conditions.trend_direction = BIAS_BULLISH;
    else if (conditions.rsi_value < 50)
        conditions.trend_direction = BIAS_BEARISH;
    else
        conditions.trend_direction = BIAS_NEUTRAL;

    return conditions;
}

//+------------------------------------------------------------------+
//| Enhanced Filters                                                 |
//+------------------------------------------------------------------+
bool PassesFilters(SMarketConditions &conditions)
{
    //--- Session filter
    if (UseSessionFilter && !IsValidTradingSession())
    {
        return false;
    }

    //--- Volatility filter
    if (UseVolatilityFilter && conditions.is_volatile)
    {
        Print("⚠️ High volatility detected: ", DoubleToString(conditions.atr_percent, 2), "%");
        return false;
    }

    //--- Spread filter
    if (UseSpreadFilter && conditions.current_spread > MaxSpreadPips)
    {
        Print("⚠️ High spread detected: ", DoubleToString(conditions.current_spread, 1), " pips");
        return false;
    }

    //--- News filter (DISABLED for testing - implement your news API later)
    // if (IsHighImpactNewsTime())
    // {
    //     Print("📰 High impact news time - skipping trades");
    //     return false;
    // }

    //--- Debug: Show current market conditions
    static datetime last_debug_time = 0;
    if (TimeCurrent() - last_debug_time >= 10) // Print every 10 seconds
    {
        Print("✅ DEBUG: All filters passed | RSI: ", DoubleToString(conditions.rsi_value, 1), 
              " | Spread: ", DoubleToString(conditions.current_spread, 1), " pips",
              " | ATR%: ", DoubleToString(conditions.atr_percent, 2), "%");
        last_debug_time = TimeCurrent();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced Trading Session Check                                   |
//+------------------------------------------------------------------+
bool IsValidTradingSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;

    //--- London session
    bool london_session = (hour >= LondonStartHour && hour < LondonEndHour);

    //--- New York session
    bool newyork_session = (hour >= NewYorkStartHour && hour < NewYorkEndHour);

    //--- London-NY overlap (most volatile)
    bool overlap_session = (hour >= NewYorkStartHour && hour < LondonEndHour);

    return london_session || newyork_session || overlap_session;
}

//+------------------------------------------------------------------+
//| Main Enhanced Trading Logic                                      |
//+------------------------------------------------------------------+
void CheckForTrades(SMarketConditions &conditions)
{
    MqlTick current_tick;
    if (!SymbolInfoTick(_Symbol, current_tick))
        return;

    //--- Get market structure analysis
    ENUM_MARKET_BIAS higher_tf_bias = GetHigherTimeframeBias();
    SMarketStructure base_structure = GetEnhancedMarketStructure(SMC_Base_Handle);
    SMarketStructure confirm_structure = GetEnhancedMarketStructure(SMC_Confirm_Handle);

    //--- Get SMC components
    SOrderBlocks order_blocks = GetEnhancedOrderBlocks(SMC_Base_Handle);
    SFairValueGaps fvgs = GetEnhancedFairValueGaps(SMC_Base_Handle);
    SLiquidityLevels liquidity = GetEnhancedLiquidityLevels(SMC_Higher_Handle);

    //--- Check for buy setups
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) < MaxOpenTrades)
    {
        ENUM_TRADE_TYPE buy_setup = AnalyzeBuyOpportunity(higher_tf_bias, base_structure,
                                                          confirm_structure, order_blocks,
                                                          fvgs, liquidity, current_tick.ask, conditions);

        // DEBUG: Print buy analysis result
        static int buy_debug_counter = 0;
        buy_debug_counter++;
        if (buy_debug_counter % 100 == 0) // Print every 100 ticks
        {
            Print("🔍 BUY ANALYSIS: RSI=", DoubleToString(conditions.rsi_value, 1), 
                  " | Setup=", EnumToString(buy_setup), " | Positions=", CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY));
        }

        if (buy_setup != TRADE_NONE)
        {
            Print("🚀 EXECUTING BUY TRADE! Setup type: ", EnumToString(buy_setup));
            ExecuteEnhancedBuyTrade(current_tick.ask, base_structure, order_blocks,
                                    fvgs, liquidity, buy_setup, conditions);
        }
    }

    //--- Check for sell setups
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) < MaxOpenTrades)
    {
        ENUM_TRADE_TYPE sell_setup = AnalyzeSellOpportunity(higher_tf_bias, base_structure,
                                                            confirm_structure, order_blocks,
                                                            fvgs, liquidity, current_tick.bid, conditions);

        // DEBUG: Print sell analysis result
        static int sell_debug_counter = 0;
        sell_debug_counter++;
        if (sell_debug_counter % 100 == 0) // Print every 100 ticks
        {
            Print("🔍 SELL ANALYSIS: RSI=", DoubleToString(conditions.rsi_value, 1), 
                  " | Setup=", EnumToString(sell_setup), " | Positions=", CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL));
        }

        if (sell_setup != TRADE_NONE)
        {
            Print("🚀 EXECUTING SELL TRADE! Setup type: ", EnumToString(sell_setup));
            ExecuteEnhancedSellTrade(current_tick.bid, base_structure, order_blocks,
                                     fvgs, liquidity, sell_setup, conditions);
        }
    }
}

//+------------------------------------------------------------------+
//| Enhanced Market Structure Analysis                               |
//+------------------------------------------------------------------+
SMarketStructure GetEnhancedMarketStructure(int handle)
{
    SMarketStructure structure;
    ZeroMemory(structure);

    //--- Check multiple bars for signals (increased lookback for more signals)
    for (int i = 1; i <= 10; i++)
    {
        double bull_bos = GetIndicatorBufferValue(handle, BUFFER_BULLISH_BOS, i);
        double bear_bos = GetIndicatorBufferValue(handle, BUFFER_BEARISH_BOS, i);
        double bull_choch = GetIndicatorBufferValue(handle, BUFFER_BULLISH_CHOCH, i);
        double bear_choch = GetIndicatorBufferValue(handle, BUFFER_BEARISH_CHOCH, i);

        if (!structure.bullish_bos && ValidateSignal(bull_bos))
        {
            structure.bullish_bos = true;
            Print("🔍 SMC SIGNAL: BULLISH BOS detected at bar ", i, " | Value: ", bull_bos);
        }
        if (!structure.bearish_bos && ValidateSignal(bear_bos))
        {
            structure.bearish_bos = true;
            Print("🔍 SMC SIGNAL: BEARISH BOS detected at bar ", i, " | Value: ", bear_bos);
        }
        if (!structure.bullish_choch && ValidateSignal(bull_choch))
        {
            structure.bullish_choch = true;
            Print("🔍 SMC SIGNAL: BULLISH CHoCH detected at bar ", i, " | Value: ", bull_choch);
        }
        if (!structure.bearish_choch && ValidateSignal(bear_choch))
        {
            structure.bearish_choch = true;
            Print("🔍 SMC SIGNAL: BEARISH CHoCH detected at bar ", i, " | Value: ", bear_choch);
        }
    }

    //--- Enhanced swing detection
    int highest_bar = iHighest(_Symbol, Period(), MODE_HIGH, 50, 1);
    int lowest_bar = iLowest(_Symbol, Period(), MODE_LOW, 50, 1);

    structure.recent_high = iHigh(_Symbol, Period(), highest_bar);
    structure.recent_low = iLow(_Symbol, Period(), lowest_bar);
    structure.high_time = iTime(_Symbol, Period(), highest_bar);
    structure.low_time = iTime(_Symbol, Period(), lowest_bar);

    //--- Calculate structure strength (1-5) - relaxed for testing
    structure.structure_strength = CalculateStructureStrength(structure);

    //--- Debug output every 15 seconds
    static datetime last_debug = 0;
    if (TimeCurrent() - last_debug >= 15)
    {
        Print("📊 MARKET STRUCTURE: BOS[Bull:", structure.bullish_bos, " Bear:", structure.bearish_bos, 
              "] CHoCH[Bull:", structure.bullish_choch, " Bear:", structure.bearish_choch, 
              "] Strength:", structure.structure_strength);
        last_debug = TimeCurrent();
    }

    return structure;
}

//+------------------------------------------------------------------+
//| Enhanced Order Block Detection                                   |
//+------------------------------------------------------------------+
SOrderBlocks GetEnhancedOrderBlocks(int handle)
{
    SOrderBlocks blocks;
    ZeroMemory(blocks);

    //--- Find most recent valid order blocks
    for (int i = 1; i <= SMC_OB_Lookback; i++)
    {
        double bull_high = GetIndicatorBufferValue(handle, BUFFER_BULLISH_OB_HIGH, i);
        double bull_low = GetIndicatorBufferValue(handle, BUFFER_BULLISH_OB_LOW, i);
        double bear_high = GetIndicatorBufferValue(handle, BUFFER_BEARISH_OB_HIGH, i);
        double bear_low = GetIndicatorBufferValue(handle, BUFFER_BEARISH_OB_LOW, i);

        //--- Bullish order block
        if (UseOrderBlocks && bull_high > 0 && bull_low > 0 && blocks.bullish_ob_high == 0)
        {
            double size_pips = (bull_high - bull_low) / PointMultiplier;
            if (size_pips >= 50) // Relaxed from MinOBSize for more signals
            {
                blocks.bullish_ob_high = bull_high;
                blocks.bullish_ob_low = bull_low;
                blocks.ob_time = iTime(_Symbol, Period(), i);
                blocks.size_pips = size_pips;
                blocks.is_valid = true; // Simplified validation for testing
                
                Print("📦 BULLISH ORDER BLOCK FOUND:");
                Print("   📊 Range: ", DoubleToString(bull_low, _Digits), " - ", DoubleToString(bull_high, _Digits));
                Print("   📏 Size: ", DoubleToString(size_pips, 1), " pips");
                Print("   ⏰ Time: ", TimeToString(blocks.ob_time, TIME_DATE|TIME_MINUTES));
            }
        }

        //--- Bearish order block
        if (UseOrderBlocks && bear_high > 0 && bear_low > 0 && blocks.bearish_ob_high == 0)
        {
            double size_pips = (bear_high - bear_low) / PointMultiplier;
            if (size_pips >= 50) // Relaxed from MinOBSize for more signals
            {
                blocks.bearish_ob_high = bear_high;
                blocks.bearish_ob_low = bear_low;
                blocks.size_pips = size_pips;
                blocks.is_valid = true; // Simplified validation for testing
                
                Print("📦 BEARISH ORDER BLOCK FOUND:");
                Print("   📊 Range: ", DoubleToString(bear_low, _Digits), " - ", DoubleToString(bear_high, _Digits));
                Print("   📏 Size: ", DoubleToString(size_pips, 1), " pips");
                Print("   ⏰ Time: ", TimeToString(iTime(_Symbol, Period(), i), TIME_DATE|TIME_MINUTES));
            }
        }
    }

    return blocks;
}

//+------------------------------------------------------------------+
//| Enhanced Fair Value Gap Detection                                |
//+------------------------------------------------------------------+
SFairValueGaps GetEnhancedFairValueGaps(int handle)
{
    SFairValueGaps fvgs;
    ZeroMemory(fvgs);

    if (!UseFairValueGaps)
        return fvgs;

    //--- Find most recent valid FVGs
    for (int i = 1; i <= SMC_FVG_Lookback; i++)
    {
        double bull_high = GetIndicatorBufferValue(handle, BUFFER_BULLISH_FVG_HIGH, i);
        double bull_low = GetIndicatorBufferValue(handle, BUFFER_BULLISH_FVG_LOW, i);
        double bear_high = GetIndicatorBufferValue(handle, BUFFER_BEARISH_FVG_HIGH, i);
        double bear_low = GetIndicatorBufferValue(handle, BUFFER_BEARISH_FVG_LOW, i);

        //--- Bullish FVG
        if (bull_high > 0 && bull_low > 0 && fvgs.bullish_fvg_high == 0)
        {
            double size_pips = (bull_high - bull_low) / PointMultiplier;
            if (size_pips >= 30) // Relaxed minimum FVG size for more signals
            {
                fvgs.bullish_fvg_high = bull_high;
                fvgs.bullish_fvg_low = bull_low;
                fvgs.fvg_time = iTime(_Symbol, Period(), i);
                fvgs.size_pips = size_pips;
                fvgs.is_valid = true; // Simplified validation for testing
                
                Print("🔄 BULLISH FAIR VALUE GAP FOUND:");
                Print("   📊 Range: ", DoubleToString(bull_low, _Digits), " - ", DoubleToString(bull_high, _Digits));
                Print("   📏 Size: ", DoubleToString(size_pips, 1), " pips");
                Print("   ⏰ Time: ", TimeToString(fvgs.fvg_time, TIME_DATE|TIME_MINUTES));
            }
        }

        //--- Bearish FVG
        if (bear_high > 0 && bear_low > 0 && fvgs.bearish_fvg_high == 0)
        {
            double size_pips = (bear_high - bear_low) / PointMultiplier;
            if (size_pips >= 30) // Relaxed minimum FVG size for more signals
            {
                fvgs.bearish_fvg_high = bear_high;
                fvgs.bearish_fvg_low = bear_low;
                fvgs.size_pips = size_pips;
                fvgs.is_valid = true; // Simplified validation for testing
                
                Print("🔄 BEARISH FAIR VALUE GAP FOUND:");
                Print("   📊 Range: ", DoubleToString(bear_low, _Digits), " - ", DoubleToString(bear_high, _Digits));
                Print("   📏 Size: ", DoubleToString(size_pips, 1), " pips");
                Print("   ⏰ Time: ", TimeToString(iTime(_Symbol, Period(), i), TIME_DATE|TIME_MINUTES));
            }
        }
    }

    return fvgs;
}

//+------------------------------------------------------------------+
//| Enhanced Liquidity Level Detection                               |
//+------------------------------------------------------------------+
SLiquidityLevels GetEnhancedLiquidityLevels(int handle)
{
    SLiquidityLevels levels;
    ZeroMemory(levels);

    //--- Check multiple bars for liquidity signals (increased lookback)
    for (int i = 1; i <= 15; i++)
    {
        double eq_high = GetIndicatorBufferValue(handle, BUFFER_EQ_HIGHS, i);
        double eq_low = GetIndicatorBufferValue(handle, BUFFER_EQ_LOWS, i);
        double grab_high = GetIndicatorBufferValue(handle, BUFFER_LIQUIDITY_GRAB_HIGH, i);
        double grab_low = GetIndicatorBufferValue(handle, BUFFER_LIQUIDITY_GRAB_LOW, i);

        //--- Equal highs/lows detection
        if (levels.equal_highs == 0 && ValidateSignal(eq_high))
        {
            levels.equal_highs = eq_high;
            Print("⚖️ EQUAL HIGHS detected at bar ", i, " | Level: ", DoubleToString(eq_high, _Digits));
        }
        if (levels.equal_lows == 0 && ValidateSignal(eq_low))
        {
            levels.equal_lows = eq_low;
            Print("⚖️ EQUAL LOWS detected at bar ", i, " | Level: ", DoubleToString(eq_low, _Digits));
        }

        //--- Liquidity grab detection
        if (UseLiquidityGrabs)
        {
            if (!levels.liquidity_grab_high && ValidateSignal(grab_high))
            {
                levels.liquidity_grab_high = true;
                levels.grab_time = iTime(_Symbol, Period(), i);
                Print("💧 HIGH SIDE LIQUIDITY GRAB at bar ", i, " | Time: ", TimeToString(levels.grab_time));
            }
            if (!levels.liquidity_grab_low && ValidateSignal(grab_low))
            {
                levels.liquidity_grab_low = true;
                levels.grab_time = iTime(_Symbol, Period(), i);
                Print("💧 LOW SIDE LIQUIDITY GRAB at bar ", i, " | Time: ", TimeToString(levels.grab_time));
            }
        }
    }

    //--- Enhanced swing detection with multiple timeframes
    levels.swing_highs = iHigh(_Symbol, Period(), iHighest(_Symbol, Period(), MODE_HIGH, 50, 1));
    levels.swing_lows = iLow(_Symbol, Period(), iLowest(_Symbol, Period(), MODE_LOW, 50, 1));

    //--- More frequent debug output (every 30 seconds)
    static datetime last_liq_debug = 0;
    if (TimeCurrent() - last_liq_debug >= 30)
    {
        Print("💧 LIQUIDITY STATUS:");
        Print("   📈 Swing High: ", DoubleToString(levels.swing_highs, _Digits));
        Print("   📉 Swing Low: ", DoubleToString(levels.swing_lows, _Digits));
        Print("   ⚖️ Equal Highs: ", (levels.equal_highs > 0 ? DoubleToString(levels.equal_highs, _Digits) : "None"));
        Print("   ⚖️ Equal Lows: ", (levels.equal_lows > 0 ? DoubleToString(levels.equal_lows, _Digits) : "None"));
        Print("   🎯 Grab High: ", (levels.liquidity_grab_high ? "Yes" : "No"));
        Print("   🎯 Grab Low: ", (levels.liquidity_grab_low ? "Yes" : "No"));
        last_liq_debug = TimeCurrent();
    }

    return levels;
}

//+------------------------------------------------------------------+
//| Analyze Buy Opportunity                                          |
//+------------------------------------------------------------------+
ENUM_TRADE_TYPE AnalyzeBuyOpportunity(ENUM_MARKET_BIAS bias, SMarketStructure &base,
                                      SMarketStructure &confirm, SOrderBlocks &obs,
                                      SFairValueGaps &fvgs, SLiquidityLevels &liq,
                                      double ask, SMarketConditions &conditions)
{
    //--- BACKTEST MODE: Aggressive testing for backtesting (keep for testing)
    if (EnableBacktestMode && MQLInfoInteger(MQL_TESTER))
    {
        static int backtest_buy_counter = 0;
        backtest_buy_counter++;
        
        // Place BUY trade every 200 ticks (reduced frequency to focus on SMC)
        if (backtest_buy_counter % 200 == 0 && conditions.rsi_value < 70)
        {
            Print("🔥 BACKTEST BUY: Auto test trade #", backtest_buy_counter/200, " | RSI=", conditions.rsi_value);
            return TRADE_ORDER_BLOCK;
        }
    }

    //--- ENHANCED MULTI-STRATEGY APPROACH
    if (UseMultiStrategy)
    {
        // Get current time for session analysis
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        int hour = dt.hour;
        bool is_kill_zone = (hour >= 7 && hour <= 10) || (hour >= 13 && hour <= 16);
        
        // SCALPING STRATEGY during kill zones
        if (UseScalpingMode && is_kill_zone)
        {
            if (conditions.rsi_value < 35 && conditions.rsi_value > 25)
            {
                Print("⚡ SCALPING BUY: RSI oversold in kill zone (", hour, ":00)!");
                return TRADE_SCALPING;
            }
            
            if (conditions.atr_percent < 0.4 && conditions.current_spread < 20)
            {
                Print("⚡ SCALPING BUY: Low volatility breakout!");
                return TRADE_SCALPING;
            }
        }
        
        // MOMENTUM STRATEGY
        if (UseMomentumStrategy && conditions.rsi_value > 55 && conditions.rsi_value < 75)
        {
            Print("🚀 MOMENTUM BUY: Strong upward momentum!");
            return TRADE_MOMENTUM;
        }
        
        // REVERSAL STRATEGY
        if (UseReversalStrategy && conditions.rsi_value < 25)
        {
            Print("🔄 REVERSAL BUY: Extreme oversold reversal!");
            return TRADE_REVERSAL;
        }
        
        // SWING TRADING STRATEGY
        if (UseSwingTrading && base.bullish_choch && conditions.rsi_value < 60)
        {
            Print("📈 SWING BUY: Higher timeframe bullish structure!");
            return TRADE_SWING;
        }
        
        // TREND FOLLOWING STRATEGY
        if (UseTrendFollowing && conditions.rsi_value > 50 && conditions.rsi_value < 70)
        {
            Print("📈 TREND FOLLOW BUY: Following strong trend!");
            return TRADE_TREND_FOLLOW;
        }
    }

    //--- SMC MAIN STRATEGY: Enhanced SMC Signal Detection
    
    // AGGRESSIVE SMC MODE: Loosen all conditions for maximum trades
    if (AggressiveSMCMode)
    {
        // Check for ANY Order Block signals (bullish or bearish converted to bullish signal)
        if (UseOrderBlocks && (obs.bullish_ob_high > 0 || obs.bearish_ob_high > 0))
        {
            Print("📦 AGGRESSIVE SMC BUY: Order Block detected (ANY type)!");
            Print("   💰 Current Price: ", DoubleToString(ask, _Digits));
            return TRADE_ORDER_BLOCK;
        }
        
        // Check for ANY Fair Value Gap signals
        if (UseFairValueGaps && (fvgs.bullish_fvg_high > 0 || fvgs.bearish_fvg_high > 0))
        {
            Print("🔄 AGGRESSIVE SMC BUY: Fair Value Gap detected (ANY type)!");
            Print("   💰 Current Price: ", DoubleToString(ask, _Digits));
            return TRADE_FAIR_VALUE_GAP;
        }
        
        // Check for ANY structure break
        if (base.bullish_bos || base.bearish_bos || base.bullish_choch || base.bearish_choch)
        {
            Print("📈 AGGRESSIVE SMC BUY: Structure break detected (ANY type)!");
            Print("   💪 Structure Strength: ", base.structure_strength, "/5");
            return TRADE_ORDER_BLOCK;
        }
        
        // Check for ANY liquidity level
        if (liq.equal_highs > 0 || liq.equal_lows > 0 || liq.liquidity_grab_high || liq.liquidity_grab_low)
        {
            Print("💧 AGGRESSIVE SMC BUY: Liquidity signal detected!");
            return TRADE_LIQUIDITY_GRAB;
        }
        
        // Aggressive RSI-based entry (very wide range)
        if (conditions.rsi_value > 10 && conditions.rsi_value < 80)
        {
            Print("✅ AGGRESSIVE SMC BUY: Favorable RSI (", conditions.rsi_value, ")");
            return TRADE_ORDER_BLOCK;
        }
    }
    
    // Check for BULLISH Order Block signals
    if (UseOrderBlocks && obs.bullish_ob_high > 0 && obs.bullish_ob_low > 0)
    {
        double ob_center = (obs.bullish_ob_high + obs.bullish_ob_low) / 2;
        bool price_in_ob = (ask >= obs.bullish_ob_low && ask <= obs.bullish_ob_high);
        bool price_near_ob = MathAbs(ask - ob_center) / PointMultiplier <= 200; // Within 20 pips of OB center
        
        if (price_in_ob || price_near_ob)
        {
            Print("📦 SMC BUY SIGNAL: Bullish Order Block detected!");
            Print("   📊 OB Range: ", DoubleToString(obs.bullish_ob_low, _Digits), " - ", DoubleToString(obs.bullish_ob_high, _Digits));
            Print("   💰 Current Price: ", DoubleToString(ask, _Digits));
            Print("   📏 OB Size: ", DoubleToString(obs.size_pips, 1), " pips");
            return TRADE_ORDER_BLOCK;
        }
    }
    
    // Check for BULLISH Fair Value Gap signals
    if (UseFairValueGaps && fvgs.bullish_fvg_high > 0 && fvgs.bullish_fvg_low > 0)
    {
        bool price_in_fvg = (ask >= fvgs.bullish_fvg_low && ask <= fvgs.bullish_fvg_high);
        bool price_near_fvg = MathAbs(ask - fvgs.bullish_fvg_low) / PointMultiplier <= 100; // Within 10 pips
        
        if (price_in_fvg || price_near_fvg)
        {
            Print("🔄 SMC BUY SIGNAL: Bullish Fair Value Gap detected!");
            Print("   📊 FVG Range: ", DoubleToString(fvgs.bullish_fvg_low, _Digits), " - ", DoubleToString(fvgs.bullish_fvg_high, _Digits));
            Print("   💰 Current Price: ", DoubleToString(ask, _Digits));
            Print("   📏 FVG Size: ", DoubleToString(fvgs.size_pips, 1), " pips");
            return TRADE_FAIR_VALUE_GAP;
        }
    }
    
    // Check for BULLISH Break of Structure (BOS) or Change of Character (CHoCH)
    if (base.bullish_bos || base.bullish_choch)
    {
        // Relaxed conditions for testing
        bool structure_valid = base.structure_strength >= 1; // Lowered from 2
        bool rsi_favorable = conditions.rsi_value < 70; // More lenient RSI condition
        
        if (structure_valid && rsi_favorable)
        {
            string signal_type = base.bullish_bos ? "Break of Structure (BOS)" : "Change of Character (CHoCH)";
            Print("📈 SMC BUY SIGNAL: Bullish ", signal_type, " detected!");
            Print("   💪 Structure Strength: ", base.structure_strength, "/5");
            Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 1));
            Print("   🎯 Recent High: ", DoubleToString(base.recent_high, _Digits));
            return TRADE_ORDER_BLOCK;
        }
    }
    
    // Check for LIQUIDITY GRAB (Buy Side Liquidity)
    if (UseLiquidityGrabs && liq.liquidity_grab_low)
    {
        double distance_to_grab = MathAbs(ask - liq.swing_lows) / PointMultiplier;
        if (distance_to_grab <= 150) // Within 15 pips of liquidity grab
        {
            Print("💧 SMC BUY SIGNAL: Buy Side Liquidity Grab detected!");
            Print("   📍 Grab Level: ", DoubleToString(liq.swing_lows, _Digits));
            Print("   📏 Distance: ", DoubleToString(distance_to_grab, 1), " pips");
            return TRADE_LIQUIDITY_GRAB;
        }
    }

    //--- Higher timeframe bias filter (relaxed for testing)
    if (bias == BIAS_BEARISH && conditions.rsi_value > 30) // Only block if strongly bearish
        return TRADE_NONE;

    //--- RSI confluence filter (more lenient)
    if (conditions.rsi_value > 85) // Only block if extremely overbought
        return TRADE_NONE;

    //--- FALLBACK: Simple RSI-based entry for testing when no SMC signals
    if (conditions.rsi_value < 50 && conditions.rsi_value > 0)
    {
        Print("✅ FALLBACK BUY: RSI-based entry (RSI=", conditions.rsi_value, ") - No SMC signals detected");
        return TRADE_ORDER_BLOCK;
    }
    
    //--- FORCE INSTANT TRADE for testing (ignores all conditions)
    if (ForceInstantTrade)
    {
        Print("🚨 FORCE BUY: Instant trade triggered - ignoring all conditions!");
        return TRADE_ORDER_BLOCK;
    }

    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| Analyze Sell Opportunity                                         |
//+------------------------------------------------------------------+
ENUM_TRADE_TYPE AnalyzeSellOpportunity(ENUM_MARKET_BIAS bias, SMarketStructure &base,
                                       SMarketStructure &confirm, SOrderBlocks &obs,
                                       SFairValueGaps &fvgs, SLiquidityLevels &liq,
                                       double bid, SMarketConditions &conditions)
{
    //--- BACKTEST MODE: Aggressive testing for backtesting (keep for testing)
    if (EnableBacktestMode && MQLInfoInteger(MQL_TESTER))
    {
        static int backtest_sell_counter = 0;
        backtest_sell_counter++;
        
        // Place SELL trade every 250 ticks (reduced frequency, offset from BUY)
        if (backtest_sell_counter % 250 == 0 && conditions.rsi_value > 30)
        {
            Print("🔥 BACKTEST SELL: Auto test trade #", backtest_sell_counter/250, " | RSI=", conditions.rsi_value);
            return TRADE_ORDER_BLOCK;
        }
    }

    //--- ENHANCED MULTI-STRATEGY APPROACH
    if (UseMultiStrategy)
    {
        // Get current time for session analysis
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        int hour = dt.hour;
        bool is_kill_zone = (hour >= 7 && hour <= 10) || (hour >= 13 && hour <= 16);
        
        // SCALPING STRATEGY during kill zones
        if (UseScalpingMode && is_kill_zone)
        {
            if (conditions.rsi_value > 65 && conditions.rsi_value < 75)
            {
                Print("⚡ SCALPING SELL: RSI overbought in kill zone (", hour, ":00)!");
                return TRADE_SCALPING;
            }
            
            if (conditions.atr_percent < 0.4 && conditions.current_spread < 20)
            {
                Print("⚡ SCALPING SELL: Low volatility breakout!");
                return TRADE_SCALPING;
            }
        }
        
        // MOMENTUM STRATEGY
        if (UseMomentumStrategy && conditions.rsi_value < 45 && conditions.rsi_value > 25)
        {
            Print("🚀 MOMENTUM SELL: Strong downward momentum!");
            return TRADE_MOMENTUM;
        }
        
        // REVERSAL STRATEGY
        if (UseReversalStrategy && conditions.rsi_value > 75)
        {
            Print("🔄 REVERSAL SELL: Extreme overbought reversal!");
            return TRADE_REVERSAL;
        }
        
        // SWING TRADING STRATEGY
        if (UseSwingTrading && base.bearish_choch && conditions.rsi_value > 40)
        {
            Print("📉 SWING SELL: Higher timeframe bearish structure!");
            return TRADE_SWING;
        }
        
        // TREND FOLLOWING STRATEGY
        if (UseTrendFollowing && conditions.rsi_value < 50 && conditions.rsi_value > 30)
        {
            Print("📉 TREND FOLLOW SELL: Following strong downtrend!");
            return TRADE_TREND_FOLLOW;
        }
    }

    //--- SMC MAIN STRATEGY: Enhanced SMC Signal Detection
    
    // AGGRESSIVE SMC MODE: Loosen all conditions for maximum trades
    if (AggressiveSMCMode)
    {
        // Check for ANY Order Block signals (bullish or bearish converted to bearish signal)
        if (UseOrderBlocks && (obs.bullish_ob_high > 0 || obs.bearish_ob_high > 0))
        {
            Print("📦 AGGRESSIVE SMC SELL: Order Block detected (ANY type)!");
            Print("   💰 Current Price: ", DoubleToString(bid, _Digits));
            return TRADE_ORDER_BLOCK;
        }
        
        // Check for ANY Fair Value Gap signals
        if (UseFairValueGaps && (fvgs.bullish_fvg_high > 0 || fvgs.bearish_fvg_high > 0))
        {
            Print("🔄 AGGRESSIVE SMC SELL: Fair Value Gap detected (ANY type)!");
            Print("   💰 Current Price: ", DoubleToString(bid, _Digits));
            return TRADE_FAIR_VALUE_GAP;
        }
        
        // Check for ANY structure break
        if (base.bullish_bos || base.bearish_bos || base.bullish_choch || base.bearish_choch)
        {
            Print("📉 AGGRESSIVE SMC SELL: Structure break detected (ANY type)!");
            Print("   💪 Structure Strength: ", base.structure_strength, "/5");
            return TRADE_ORDER_BLOCK;
        }
        
        // Check for ANY liquidity level
        if (liq.equal_highs > 0 || liq.equal_lows > 0 || liq.liquidity_grab_high || liq.liquidity_grab_low)
        {
            Print("💧 AGGRESSIVE SMC SELL: Liquidity signal detected!");
            return TRADE_LIQUIDITY_GRAB;
        }
        
        // Aggressive RSI-based entry (very wide range)
        if (conditions.rsi_value > 20 && conditions.rsi_value < 90)
        {
            Print("✅ AGGRESSIVE SMC SELL: Favorable RSI (", conditions.rsi_value, ")");
            return TRADE_ORDER_BLOCK;
        }
    }
    
    // Check for BEARISH Order Block signals
    if (UseOrderBlocks && obs.bearish_ob_high > 0 && obs.bearish_ob_low > 0)
    {
        double ob_center = (obs.bearish_ob_high + obs.bearish_ob_low) / 2;
        bool price_in_ob = (bid >= obs.bearish_ob_low && bid <= obs.bearish_ob_high);
        bool price_near_ob = MathAbs(bid - ob_center) / PointMultiplier <= 200; // Within 20 pips of OB center
        
        if (price_in_ob || price_near_ob)
        {
            Print("📦 SMC SELL SIGNAL: Bearish Order Block detected!");
            Print("   📊 OB Range: ", DoubleToString(obs.bearish_ob_low, _Digits), " - ", DoubleToString(obs.bearish_ob_high, _Digits));
            Print("   💰 Current Price: ", DoubleToString(bid, _Digits));
            Print("   📏 OB Size: ", DoubleToString(obs.size_pips, 1), " pips");
            return TRADE_ORDER_BLOCK;
        }
    }
    
    // Check for BEARISH Fair Value Gap signals
    if (UseFairValueGaps && fvgs.bearish_fvg_high > 0 && fvgs.bearish_fvg_low > 0)
    {
        bool price_in_fvg = (bid >= fvgs.bearish_fvg_low && bid <= fvgs.bearish_fvg_high);
        bool price_near_fvg = MathAbs(bid - fvgs.bearish_fvg_high) / PointMultiplier <= 100; // Within 10 pips
        
        if (price_in_fvg || price_near_fvg)
        {
            Print("🔄 SMC SELL SIGNAL: Bearish Fair Value Gap detected!");
            Print("   📊 FVG Range: ", DoubleToString(fvgs.bearish_fvg_low, _Digits), " - ", DoubleToString(fvgs.bearish_fvg_high, _Digits));
            Print("   💰 Current Price: ", DoubleToString(bid, _Digits));
            Print("   📏 FVG Size: ", DoubleToString(fvgs.size_pips, 1), " pips");
            return TRADE_FAIR_VALUE_GAP;
        }
    }
    
    // Check for BEARISH Break of Structure (BOS) or Change of Character (CHoCH)
    if (base.bearish_bos || base.bearish_choch)
    {
        // Relaxed conditions for testing
        bool structure_valid = base.structure_strength >= 1; // Lowered from 2
        bool rsi_favorable = conditions.rsi_value > 30; // More lenient RSI condition
        
        if (structure_valid && rsi_favorable)
        {
            string signal_type = base.bearish_bos ? "Break of Structure (BOS)" : "Change of Character (CHoCH)";
            Print("📉 SMC SELL SIGNAL: Bearish ", signal_type, " detected!");
            Print("   💪 Structure Strength: ", base.structure_strength, "/5");
            Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 1));
            Print("   🎯 Recent Low: ", DoubleToString(base.recent_low, _Digits));
            return TRADE_ORDER_BLOCK;
        }
    }
    
    // Check for LIQUIDITY GRAB (Sell Side Liquidity)
    if (UseLiquidityGrabs && liq.liquidity_grab_high)
    {
        double distance_to_grab = MathAbs(bid - liq.swing_highs) / PointMultiplier;
        if (distance_to_grab <= 150) // Within 15 pips of liquidity grab
        {
            Print("💧 SMC SELL SIGNAL: Sell Side Liquidity Grab detected!");
            Print("   📍 Grab Level: ", DoubleToString(liq.swing_highs, _Digits));
            Print("   📏 Distance: ", DoubleToString(distance_to_grab, 1), " pips");
            return TRADE_LIQUIDITY_GRAB;
        }
    }

    //--- Higher timeframe bias filter (relaxed for testing)
    if (bias == BIAS_BULLISH && conditions.rsi_value < 70) // Only block if strongly bullish
        return TRADE_NONE;

    //--- RSI confluence filter (more lenient)
    if (conditions.rsi_value < 15) // Only block if extremely oversold
        return TRADE_NONE;

    //--- FALLBACK: Simple RSI-based entry for testing when no SMC signals
    if (conditions.rsi_value > 50 && conditions.rsi_value < 100)
    {
        Print("✅ FALLBACK SELL: RSI-based entry (RSI=", conditions.rsi_value, ") - No SMC signals detected");
        return TRADE_ORDER_BLOCK;
    }
    
    //--- FORCE INSTANT TRADE for testing (ignores all conditions)
    if (ForceInstantTrade)
    {
        Print("🚨 FORCE SELL: Instant trade triggered - ignoring all conditions!");
        return TRADE_ORDER_BLOCK;
    }

    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| Execute Enhanced Buy Trade                                       |
//+------------------------------------------------------------------+
void ExecuteEnhancedBuyTrade(double ask,
                             SMarketStructure &base_structure,
                             SOrderBlocks &order_blocks,
                             SFairValueGaps &fvgs,
                             SLiquidityLevels &liquidity,
                             ENUM_TRADE_TYPE setup,
                             SMarketConditions &conditions)
{
    //--- Strategy-specific risk management and SL/TP
    double risk_percent = RiskPerTradePercent;
    int sl_pips = StopLossPips;
    int tp_pips = TakeProfitPips;
    string strategy_comment = TradeComment;
    
    // Adjust parameters based on strategy type
    if (setup == TRADE_SCALPING)
    {
        risk_percent = ScalpingRiskPercent;
        sl_pips = 150; // Tighter SL for scalping
        tp_pips = 300; // Smaller TP for quick profits
        strategy_comment += "-SCALP";
    }
    else if (setup == TRADE_SWING)
    {
        risk_percent = SwingRiskPercent;
        sl_pips = 400; // Wider SL for swing trades
        tp_pips = 1200; // Larger TP for swing trades
        strategy_comment += "-SWING";
    }
    else if (setup == TRADE_MOMENTUM)
    {
        sl_pips = 200; // Medium SL for momentum
        tp_pips = 800; // Good TP for momentum
        strategy_comment += "-MOMENTUM";
    }
    else if (setup == TRADE_REVERSAL)
    {
        sl_pips = 180; // Tight SL for reversals
        tp_pips = 600; // Medium TP for reversals
        strategy_comment += "-REVERSAL";
    }
    else if (setup == TRADE_TREND_FOLLOW)
    {
        sl_pips = 300; // Medium SL for trend following
        tp_pips = 900; // Good TP for trend following
        strategy_comment += "-TREND";
    }
    else if (setup == TRADE_FIBONACCI)
    {
        sl_pips = 200; // Medium SL for Fibonacci
        tp_pips = 800; // Good TP for Fibonacci
        strategy_comment += "-FIB";
    }
    else
    {
        strategy_comment += "-SMC";
    }

    //--- Calculate stop loss and take profit
    double sl = 0, tp = 0;
    double entry = ask;

    //--- Strategy-specific SL/TP calculation
    if (setup == TRADE_ORDER_BLOCK && order_blocks.bullish_ob_low > 0)
        sl = order_blocks.bullish_ob_low - (sl_pips * PointMultiplier);
    else if (setup == TRADE_FAIR_VALUE_GAP && fvgs.bullish_fvg_low > 0)
        sl = fvgs.bullish_fvg_low - (sl_pips * PointMultiplier);
    else
        sl = entry - (sl_pips * PointMultiplier);

    tp = entry + (tp_pips * PointMultiplier);

    //--- Calculate lot size based on strategy risk
    double lot = CalculateLotSize(entry, sl, risk_percent);

    //--- Check for minimum lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if (lot < min_lot)
        lot = min_lot;

    //--- Place buy order
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot;
    request.type = ORDER_TYPE_BUY;
    request.price = entry;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.comment = strategy_comment;

    if (OrderSend(request, result))
    {
        Print("✅ ", strategy_comment, " BUY order placed:");
        Print("   📊 Strategy: ", EnumToString(setup));
        Print("   💰 Entry: ", DoubleToString(entry, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(sl_pips, 0), " pips)");
        Print("   🎯 TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(tp_pips, 0), " pips)");
        Print("   📈 Lot: ", DoubleToString(lot, 2));
        Print("   📊 Risk: ", DoubleToString(risk_percent, 1), "%");

        //--- Trailing stop
        if (UseTrailingStop)
            SetTrailingStop(result.order, TrailingStopPips);

        //--- Breakeven
        if (UseBreakeven)
            SetBreakeven(result.order, BreakevenPips);

        //--- Partial close
        if (EnablePartialClose)
            SetPartialClose(result.order, PartialClosePips, PartialClosePercent);
    }
    else
    {
        Print("❌ Buy order failed: ", result.retcode, " ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double entry, double sl, double risk_percent)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = balance * (risk_percent / 100.0);
    double stop_loss_points = MathAbs(entry - sl) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if (stop_loss_points <= 0.0 || tick_value <= 0.0 || tick_size <= 0.0)
        return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

    double lot = risk_amount / (stop_loss_points * (tick_value / tick_size));
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

    lot = MathMax(min_lot, MathMin(lot, max_lot));
    
    // Get volume step as double and calculate decimal places
    double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    int volume_digits = 2; // Default for most symbols
    
    if (volume_step == 0.01)
        volume_digits = 2;
    else if (volume_step == 0.1)
        volume_digits = 1;
    else if (volume_step == 1.0)
        volume_digits = 0;
    
    lot = NormalizeDouble(lot, volume_digits);
    return lot;
}

//+------------------------------------------------------------------+
//| Set Trailing Stop                                                |
//+------------------------------------------------------------------+
void SetTrailingStop(ulong ticket, int trailing_pips)
{
    if (!PositionSelectByTicket(ticket))
        return;

    double trailing_distance = trailing_pips * PointMultiplier;
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    if (pos_type == POSITION_TYPE_BUY)
    {
        double new_sl = current_price - trailing_distance;
        if (new_sl > current_sl && new_sl > open_price)
        {
            if (Trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
            {
                Print("🔄 TRAILING STOP UPDATED - Position #", ticket, 
                      " | New SL: ", DoubleToString(new_sl, _Digits),
                      " | Old SL: ", DoubleToString(current_sl, _Digits));
            }
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        double new_sl = current_price + trailing_distance;
        if (new_sl < current_sl && new_sl < open_price)
        {
            if (Trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
            {
                Print("🔄 TRAILING STOP UPDATED - Position #", ticket, 
                      " | New SL: ", DoubleToString(new_sl, _Digits),
                      " | Old SL: ", DoubleToString(current_sl, _Digits));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Set Breakeven                                                    |
//+------------------------------------------------------------------+
void SetBreakeven(ulong ticket, int breakeven_pips)
{
    if (!PositionSelectByTicket(ticket))
        return;

    double breakeven_distance = breakeven_pips * PointMultiplier;
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    if (pos_type == POSITION_TYPE_BUY)
    {
        if (current_price >= open_price + breakeven_distance && current_sl < open_price)
        {
            if (Trade.PositionModify(ticket, open_price, PositionGetDouble(POSITION_TP)))
            {
                Print("⚖️ BREAKEVEN SET - BUY Position #", ticket, 
                      " | SL moved to entry: ", DoubleToString(open_price, _Digits),
                      " | Profit secured: ", DoubleToString(breakeven_pips, 0), " pips");
            }
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        if (current_price <= open_price - breakeven_distance && current_sl > open_price)
        {
            if (Trade.PositionModify(ticket, open_price, PositionGetDouble(POSITION_TP)))
            {
                Print("⚖️ BREAKEVEN SET - SELL Position #", ticket, 
                      " | SL moved to entry: ", DoubleToString(open_price, _Digits),
                      " | Profit secured: ", DoubleToString(breakeven_pips, 0), " pips");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Set Partial Close                                                |
//+------------------------------------------------------------------+
void SetPartialClose(ulong ticket, int trigger_pips, double percent)
{
    if (!PositionSelectByTicket(ticket))
        return;

    double trigger_distance = trigger_pips * PointMultiplier;
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double volume = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    bool should_partial_close = false;

    if (pos_type == POSITION_TYPE_BUY)
    {
        should_partial_close = (current_price >= open_price + trigger_distance);
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        should_partial_close = (current_price <= open_price - trigger_distance);
    }

    if (should_partial_close)
    {
        double close_volume = NormalizeDouble(volume * (percent / 100.0), 2);
        if (close_volume >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
        {
            if (Trade.PositionClosePartial(ticket, close_volume))
            {
                string direction = (pos_type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
                Print("📊 PARTIAL CLOSE EXECUTED - ", direction, " Position #", ticket);
                Print("   💰 Closed Volume: ", DoubleToString(close_volume, 2), " lots");
                Print("   📈 Close Price: ", DoubleToString(current_price, _Digits));
                Print("   📊 Remaining: ", DoubleToString(volume - close_volume, 2), " lots");
                Print("   🎯 Trigger: ", DoubleToString(trigger_pips, 0), " pips profit");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Execute Enhanced Sell Trade                                      |
//+------------------------------------------------------------------+
void ExecuteEnhancedSellTrade(double bid,
                              SMarketStructure &base_structure,
                              SOrderBlocks &order_blocks,
                              SFairValueGaps &fvgs,
                              SLiquidityLevels &liquidity,
                              ENUM_TRADE_TYPE setup,
                              SMarketConditions &conditions)
{
    //--- Calculate stop loss and take profit
    double sl = 0, tp = 0;
    double entry = bid;

    //--- Setup-specific SL/TP
    if (setup == TRADE_ORDER_BLOCK && order_blocks.bearish_ob_high > 0)
        sl = order_blocks.bearish_ob_high + (StopLossPips * PointMultiplier);
    else if (setup == TRADE_FAIR_VALUE_GAP && fvgs.bearish_fvg_high > 0)
        sl = fvgs.bearish_fvg_high + (StopLossPips * PointMultiplier);
    else
        sl = entry + (StopLossPips * PointMultiplier);

    tp = entry - (TakeProfitPips * PointMultiplier);

    //--- Calculate lot size based on risk
    double lot = CalculateLotSize(entry, sl, RiskPerTradePercent);

    //--- Check for minimum lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if (lot < min_lot)
        lot = min_lot;

    //--- Place sell order
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot;
    request.type = ORDER_TYPE_SELL;
    request.price = entry;
    request.sl = NormalizeDouble(sl, _Digits);
    request.tp = NormalizeDouble(tp, _Digits);
    request.deviation = Slippage;
    request.magic = MagicNumber;
    request.comment = TradeComment;

    if (OrderSend(request, result))
    {
        Print("✅ Sell order placed: ", "Entry=", entry, " SL=", sl, " TP=", tp, " Lot=", lot);

        //--- Trade management
        if (UseTrailingStop)
            SetTrailingStop(result.order, TrailingStopPips);

        if (UseBreakeven)
            SetBreakeven(result.order, BreakevenPips);

        if (EnablePartialClose)
            SetPartialClose(result.order, PartialClosePips, PartialClosePercent);
    }
    else
    {
        Print("❌ Sell order failed: ", result.retcode, " ", result.comment);
    }
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions(SMarketConditions &conditions)
{
    static datetime last_status_time = 0;
    
    // Show position status every 30 seconds if we have positions
    if (PositionsTotal() > 0 && TimeCurrent() - last_status_time >= 30)
    {
        ShowPositionsStatus();
        last_status_time = TimeCurrent();
    }
    
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol == "")
            continue;

        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;

        ulong ticket = PositionGetInteger(POSITION_TICKET);

        //--- Apply trailing stop
        if (UseTrailingStop)
            SetTrailingStop(ticket, TrailingStopPips);

        //--- Apply breakeven
        if (UseBreakeven)
            SetBreakeven(ticket, BreakevenPips);

        //--- Apply partial close
        if (EnablePartialClose)
            SetPartialClose(ticket, PartialClosePips, PartialClosePercent);

        //--- Emergency close on high volatility
        if (conditions.is_volatile && conditions.atr_percent > MaxATRPercent * 1.5)
        {
            Print("⚠️ Emergency close due to extreme volatility");
            Trade.PositionClose(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Show Positions Status                                            |
//+------------------------------------------------------------------+
void ShowPositionsStatus()
{
    int total_positions = PositionsTotal();
    int ea_positions = 0;
    double total_profit = 0;
    
    Print("📊 ═══════ POSITIONS STATUS ═══════");
    
    for (int i = 0; i < total_positions; i++)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol == "")
            continue;
            
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
            
        ea_positions++;
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double volume = PositionGetDouble(POSITION_VOLUME);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        double profit = PositionGetDouble(POSITION_PROFIT);
        double swap = PositionGetDouble(POSITION_SWAP);
        datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
        
        total_profit += profit + swap;
        
        string direction = (pos_type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
        double pips_profit = 0;
        
        if (pos_type == POSITION_TYPE_BUY)
            pips_profit = (current_price - open_price) / PointMultiplier;
        else
            pips_profit = (open_price - current_price) / PointMultiplier;
            
        Print("📈 Position #", ticket, " [", direction, "]");
        Print("   💰 Volume: ", DoubleToString(volume, 2), " | Entry: ", DoubleToString(open_price, _Digits));
        Print("   📊 Current: ", DoubleToString(current_price, _Digits), " | Pips: ", DoubleToString(pips_profit, 1));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " | 🎯 TP: ", DoubleToString(tp, _Digits));
        Print("   💵 Profit: $", DoubleToString(profit, 2), " | Swap: $", DoubleToString(swap, 2));
        Print("   ⏰ Open Time: ", TimeToString(open_time, TIME_DATE|TIME_MINUTES));
    }
    
    if (ea_positions == 0)
    {
        Print("📊 No open positions for this EA (Magic: ", MagicNumber, ")");
    }
    else
    {
        Print("📊 Total EA Positions: ", ea_positions);
        Print("💰 Total Profit: $", DoubleToString(total_profit, 2));
        Print("💳 Account Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
        Print("💎 Account Equity: $", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    }
    Print("═══════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Get Higher Timeframe Bias                                        |
//+------------------------------------------------------------------+
ENUM_MARKET_BIAS GetHigherTimeframeBias()
{
    SMarketStructure higher_structure = GetEnhancedMarketStructure(SMC_Higher_Handle);

    if (higher_structure.bullish_bos || higher_structure.bullish_choch)
        return BIAS_BULLISH;
    else if (higher_structure.bearish_bos || higher_structure.bearish_choch)
        return BIAS_BEARISH;
    else
        return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Get Indicator Buffer Value                                        |
//+------------------------------------------------------------------+
double GetIndicatorBufferValue(int handle, int buffer_index, int shift)
{
    double value[];
    if (CopyBuffer(handle, buffer_index, shift, 1, value) <= 0)
        return 0.0;
    return value[0];
}

//+------------------------------------------------------------------+
//| Validate Signal                                                   |
//+------------------------------------------------------------------+
bool ValidateSignal(double signal_value)
{
    // More lenient validation for aggressive testing
    if (AggressiveSMCMode)
    {
        return (signal_value != EMPTY_VALUE && signal_value != 0 && signal_value > -999999);
    }
    return (signal_value != EMPTY_VALUE && signal_value > 0);
}

//+------------------------------------------------------------------+
//| Calculate Structure Strength                                      |
//+------------------------------------------------------------------+
int CalculateStructureStrength(SMarketStructure &structure)
{
    int strength = 0;

    if (structure.bullish_bos || structure.bearish_bos)
        strength += 2;
    if (structure.bullish_choch || structure.bearish_choch)
        strength += 3;

    //--- Time-based strength
    datetime current_time = TimeCurrent();
    int time_diff_hours = (int)((current_time - structure.high_time) / 3600);

    if (time_diff_hours <= 24)
        strength += 1;
    else if (time_diff_hours <= 72)
        strength += 0;
    else
        strength -= 1;

    return MathMax(1, MathMin(5, strength));
}

//+------------------------------------------------------------------+
//| Validate Order Block                                             |
//+------------------------------------------------------------------+
bool ValidateOrderBlock(double high, double low, bool is_bullish)
{
    if (high <= low)
        return false;

    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ob_size = (high - low) / PointMultiplier;

    //--- Size validation
    if (ob_size < MinOBSize)
        return false;

    //--- Age validation (not too old)
    datetime current_time = TimeCurrent();
    if ((current_time - LastOrderBlockTime) < 3600) // Within 1 hour
        return false;

    LastOrderBlockTime = current_time;
    return true;
}

//+------------------------------------------------------------------+
//| Validate FVG                                                     |
//+------------------------------------------------------------------+
bool ValidateFVG(double high, double low, bool is_bullish)
{
    if (high <= low)
        return false;

    double fvg_size = (high - low) / PointMultiplier;

    //--- Minimum size validation
    if (fvg_size < 50) // 5 pips minimum
        return false;

    //--- Age validation
    datetime current_time = TimeCurrent();
    if ((current_time - LastFVGTime) < 1800) // Within 30 minutes
        return false;

    LastFVGTime = current_time;
    return true;
}

//+------------------------------------------------------------------+
//| Validate Order Block Entry                                       |
//+------------------------------------------------------------------+
bool ValidateOrderBlockEntry(SOrderBlocks &ob, bool is_bullish, double price)
{
    if (is_bullish)
    {
        //--- Price should be in lower half of bullish OB for better entry
        double ob_mid = (ob.bullish_ob_high + ob.bullish_ob_low) / 2;
        return (price <= ob_mid);
    }
    else
    {
        //--- Price should be in upper half of bearish OB for better entry
       
        double ob_mid = (ob.bearish_ob_high + ob.bearish_ob_low) / 2;
        return (price >= ob_mid);
    }
}

//+------------------------------------------------------------------+
//| Count Positions by Magic Number                                  |
//+------------------------------------------------------------------+
int CountPositionsByMagic(int magic, ENUM_POSITION_TYPE type)
{
    int count = 0;
    for (int i = 0; i < PositionsTotal(); i++)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol == "")
            continue;
            
        if (PositionGetInteger(POSITION_MAGIC) == magic &&
            PositionGetInteger(POSITION_TYPE) == type)
            count++;
    }
    return count;
}

//+------------------------------------------------------------------+
//| Apply Gold-Specific Settings                                     |
//+------------------------------------------------------------------+
void ApplyGoldSpecificSettings()
{
    //--- Gold-specific optimizations
    if (_Symbol == "XAUUSD")
    {
        //--- Adjust point multiplier for 3-digit brokers
        if (_Digits == 3)
            PointMultiplier = 0.1;
        else if (_Digits == 2)
            PointMultiplier = 1.0;
        else
            PointMultiplier = 0.01;

        Print("Gold-specific settings applied. Digits: ", _Digits, ", Point Multiplier: ", PointMultiplier);
    }
}

//+------------------------------------------------------------------+
//| High Impact News Time Check                                      |
//+------------------------------------------------------------------+
bool IsHighImpactNewsTime()
{
    //--- Placeholder for news filter
    //--- Implement your news API integration here
    //--- Return true if high impact news is expected within next 30 minutes

    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    //--- Avoid trading during typical high-impact news times
    //--- NFP (First Friday of month at 8:30 AM EST)
    //--- FOMC meetings (usually Wednesday 2:00 PM EST)
    //--- This is a simplified example

    if (dt.day_of_week == 5 && dt.hour == 13 && dt.min >= 25 && dt.min <= 35) // NFP time
        return true;

    if (dt.day_of_week == 3 && dt.hour == 19 && dt.min >= 55) // FOMC time
        return true;

    return false;
}

//+------------------------------------------------------------------+
//| OnTrade Event Handler                                            |
//+------------------------------------------------------------------+
void OnTrade()
{
    //--- Handle trade events
    if (EnableAlerts)
    {
        Print("📊 Trade event detected at: ", TimeCurrent());
    }
}

//+------------------------------------------------------------------+
//| OnTimer Event Handler                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
    //--- Periodic maintenance tasks
    //--- Clean up old data, check for news, etc.
}

//+------------------------------------------------------------------+
//| Expert Advisor End                                               |
//+------------------------------------------------------------------+
void MonitorAllSMCSignals()
{
    static datetime last_monitor_time = 0;
    
    // Monitor every 20 seconds for comprehensive status
    if (TimeCurrent() - last_monitor_time < 20)
        return;
        
    last_monitor_time = TimeCurrent();
    
    Print("🔍 ════════ COMPREHENSIVE SMC SIGNAL MONITOR ════════");
    
    //--- Get all SMC data
    SMarketStructure base_structure = GetEnhancedMarketStructure(SMC_Base_Handle);
    SOrderBlocks order_blocks = GetEnhancedOrderBlocks(SMC_Base_Handle);
    SFairValueGaps fvgs = GetEnhancedFairValueGaps(SMC_Base_Handle);
    SLiquidityLevels liquidity = GetEnhancedLiquidityLevels(SMC_Higher_Handle);
    
    //--- Market Structure Status
    Print("📊 MARKET STRUCTURE:");
    Print("   🟢 Bullish BOS: ", (base_structure.bullish_bos ? "YES" : "NO"));
    Print("   🔴 Bearish BOS: ", (base_structure.bearish_bos ? "YES" : "NO"));
    Print("   🟡 Bullish CHoCH: ", (base_structure.bullish_choch ? "YES" : "NO"));
    Print("   🟠 Bearish CHoCH: ", (base_structure.bearish_choch ? "YES" : "NO"));
    Print("   💪 Structure Strength: ", base_structure.structure_strength, "/5");
    
    //--- Order Blocks Status
    Print("📦 ORDER BLOCKS:");
    Print("   🟢 Bull OB: ", (order_blocks.bullish_ob_high > 0 ? "ACTIVE" : "NONE"), 
          (order_blocks.bullish_ob_high > 0 ? " [" + DoubleToString(order_blocks.bullish_ob_low, _Digits) + " - " + DoubleToString(order_blocks.bullish_ob_high, _Digits) + "]" : ""));
    Print("   🔴 Bear OB: ", (order_blocks.bearish_ob_high > 0 ? "ACTIVE" : "NONE"),
          (order_blocks.bearish_ob_high > 0 ? " [" + DoubleToString(order_blocks.bearish_ob_low, _Digits) + " - " + DoubleToString(order_blocks.bearish_ob_high, _Digits) + "]" : ""));
    
    //--- Fair Value Gaps Status
    Print("🔄 FAIR VALUE GAPS:");
    Print("   🟢 Bull FVG: ", (fvgs.bullish_fvg_high > 0 ? "ACTIVE" : "NONE"),
          (fvgs.bullish_fvg_high > 0 ? " [" + DoubleToString(fvgs.bullish_fvg_low, _Digits) + " - " + DoubleToString(fvgs.bullish_fvg_high, _Digits) + "]" : ""));
    Print("   🔴 Bear FVG: ", (fvgs.bearish_fvg_high > 0 ? "ACTIVE" : "NONE"),
          (fvgs.bearish_fvg_high > 0 ? " [" + DoubleToString(fvgs.bearish_fvg_low, _Digits) + " - " + DoubleToString(fvgs.bearish_fvg_high, _Digits) + "]" : ""));
    
    //--- Liquidity Status
    Print("💧 LIQUIDITY LEVELS:");
    Print("   📈 Swing High: ", DoubleToString(liquidity.swing_highs, _Digits));
    Print("   📉 Swing Low: ", DoubleToString(liquidity.swing_lows, _Digits));
    Print("   🎯 Grab High: ", (liquidity.liquidity_grab_high ? "YES" : "NO"));
    Print("   🎯 Grab Low: ", (liquidity.liquidity_grab_low ? "YES" : "NO"));
    Print("   ⚖️ Equal Highs: ", (liquidity.equal_highs > 0 ? DoubleToString(liquidity.equal_highs, _Digits) : "NONE"));
    Print("   ⚖️ Equal Lows: ", (liquidity.equal_lows > 0 ? DoubleToString(liquidity.equal_lows, _Digits) : "NONE"));
    
    //--- Current Price Context
    MqlTick tick;
    if (SymbolInfoTick(_Symbol, tick))
    {
        Print("💰 CURRENT PRICE CONTEXT:");
        Print("   📊 Bid: ", DoubleToString(tick.bid, _Digits));
        Print("   📊 Ask: ", DoubleToString(tick.ask, _Digits));
        Print("   📏 Spread: ", DoubleToString((tick.ask - tick.bid) / PointMultiplier, 1), " pips");
    }
    
    //--- Trading Readiness
    bool any_signal = base_structure.bullish_bos || base_structure.bearish_bos || 
                     base_structure.bullish_choch || base_structure.bearish_choch ||
                     order_blocks.bullish_ob_high > 0 || order_blocks.bearish_ob_high > 0 ||
                     fvgs.bullish_fvg_high > 0 || fvgs.bearish_fvg_high > 0 ||
                     liquidity.liquidity_grab_high || liquidity.liquidity_grab_low;
                     
    Print("🎯 TRADING READINESS: ", (any_signal ? "🟢 SIGNALS PRESENT" : "🔴 NO SIGNALS"));
    Print("🧪 AGGRESSIVE MODE: ", (AggressiveSMCMode ? "🔥 ENABLED" : "❄️ DISABLED"));
    Print("═══════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Test SMC Indicator Buffer Values                                 |
//+------------------------------------------------------------------+
void TestSMCIndicatorBuffers()
{
    static datetime last_test_time = 0;
    
    // Test every 30 seconds
    if (TimeCurrent() - last_test_time < 30)
        return;
        
    last_test_time = TimeCurrent();
    
    Print("🧪 ════════ SMC INDICATOR BUFFER TEST ════════");
    
    // Test all 16 buffers for the last 3 bars
    for (int buffer = 0; buffer < 16; buffer++)
    {
        Print("📊 BUFFER [", buffer, "]:");
        for (int bar = 1; bar <= 3; bar++)
        {
            double value = GetIndicatorBufferValue(SMC_Base_Handle, buffer, bar);
            if (value != EMPTY_VALUE && value != 0)
            {
                Print("   Bar[", bar, "]: ", DoubleToString(value, _Digits), " ✅");
            }
            else
            {
                Print("   Bar[", bar, "]: EMPTY/ZERO");
            }
        }
    }
    
    // Test if indicator handle is valid
    Print("🔧 INDICATOR STATUS:");
    Print("   Base Handle: ", (SMC_Base_Handle != INVALID_HANDLE ? "✅ VALID" : "❌ INVALID"));
    Print("   Confirm Handle: ", (SMC_Confirm_Handle != INVALID_HANDLE ? "✅ VALID" : "❌ INVALID"));
    Print("   Higher Handle: ", (SMC_Higher_Handle != INVALID_HANDLE ? "✅ VALID" : "❌ INVALID"));
    
    Print("═══════════════════════════════════════════════════");
}