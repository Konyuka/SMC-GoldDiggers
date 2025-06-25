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
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <Indicators/Indicator.mqh>
#include <Math/Stat/Math.mqh>

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

//--- Global Variables
CTrade Trade;
CPositionInfo PositionInfo;
CHistoryOrderInfo HistoryInfo;

double PointMultiplier;
int SMC_Base_Handle, SMC_Confirm_Handle, SMC_Higher_Handle;
int ATR_Handle, RSI_Handle;
datetime LastTradeTime;
datetime LastOrderBlockTime;
datetime LastFVGTime;

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
    TRADE_NONE
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

    //--- Validate handles
    if (SMC_Base_Handle == INVALID_HANDLE || SMC_Confirm_Handle == INVALID_HANDLE ||
        SMC_Higher_Handle == INVALID_HANDLE || ATR_Handle == INVALID_HANDLE ||
        RSI_Handle == INVALID_HANDLE)
    {
        Print("❌ Error creating indicator handles!");
        return INIT_FAILED;
    }

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
    //--- Basic checks
    if (!IsValidTradingEnvironment())
        return;

    //--- Prevent multiple trades on same tick
    if (TimeCurrent() == LastTradeTime)
        return;

    //--- Get market conditions
    SMarketConditions conditions = GetMarketConditions();

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

    //--- News filter (placeholder - implement your news API)
    if (IsHighImpactNewsTime())
    {
        Print("📰 High impact news time - skipping trades");
        return false;
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

        if (buy_setup != TRADE_NONE)
        {
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

        if (sell_setup != TRADE_NONE)
        {
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

    //--- Get BOS/CHoCH signals with validation
    structure.bullish_bos = ValidateSignal(GetIndicatorBufferValue(handle, BUFFER_BULLISH_BOS, 1));
    structure.bearish_bos = ValidateSignal(GetIndicatorBufferValue(handle, BUFFER_BEARISH_BOS, 1));
    structure.bullish_choch = ValidateSignal(GetIndicatorBufferValue(handle, BUFFER_BULLISH_CHOCH, 1));
    structure.bearish_choch = ValidateSignal(GetIndicatorBufferValue(handle, BUFFER_BEARISH_CHOCH, 1));

    //--- Enhanced swing detection
    int highest_bar = iHighest(_Symbol, Period(), MODE_HIGH, 50, 1);
    int lowest_bar = iLowest(_Symbol, Period(), MODE_LOW, 50, 1);

    structure.recent_high = iHigh(_Symbol, Period(), highest_bar);
    structure.recent_low = iLow(_Symbol, Period(), lowest_bar);
    structure.high_time = iTime(_Symbol, Period(), highest_bar);
    structure.low_time = iTime(_Symbol, Period(), lowest_bar);

    //--- Calculate structure strength (1-5)
    structure.structure_strength = CalculateStructureStrength(structure);

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
            if (size_pips >= MinOBSize)
            {
                blocks.bullish_ob_high = bull_high;
                blocks.bullish_ob_low = bull_low;
                blocks.ob_time = iTime(_Symbol, Period(), i);
                blocks.size_pips = size_pips;
                blocks.is_valid = ValidateOrderBlock(bull_high, bull_low, true);
            }
        }

        //--- Bearish order block
        if (UseOrderBlocks && bear_high > 0 && bear_low > 0 && blocks.bearish_ob_high == 0)
        {
            double size_pips = (bear_high - bear_low) / PointMultiplier;
            if (size_pips >= MinOBSize)
            {
                blocks.bearish_ob_high = bear_high;
                blocks.bearish_ob_low = bear_low;
                blocks.size_pips = size_pips;
                blocks.is_valid = ValidateOrderBlock(bear_high, bear_low, false);
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
            if (size_pips >= 50) // Minimum FVG size
            {
                fvgs.bullish_fvg_high = bull_high;
                fvgs.bullish_fvg_low = bull_low;
                fvgs.fvg_time = iTime(_Symbol, Period(), i);
                fvgs.size_pips = size_pips;
                fvgs.is_valid = ValidateFVG(bull_high, bull_low, true);
            }
        }

        //--- Bearish FVG
        if (bear_high > 0 && bear_low > 0 && fvgs.bearish_fvg_high == 0)
        {
            double size_pips = (bear_high - bear_low) / PointMultiplier;
            if (size_pips >= 50) // Minimum FVG size
            {
                fvgs.bearish_fvg_high = bear_high;
                fvgs.bearish_fvg_low = bear_low;
                fvgs.size_pips = size_pips;
                fvgs.is_valid = ValidateFVG(bear_high, bear_low, false);
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

    //--- Get equal highs/lows from indicator
    levels.equal_highs = GetIndicatorBufferValue(handle, BUFFER_EQ_HIGHS, 1);
    levels.equal_lows = GetIndicatorBufferValue(handle, BUFFER_EQ_LOWS, 1);

    //--- Check for liquidity grabs
    if (UseLiquidityGrabs)
    {
        levels.liquidity_grab_high = ValidateSignal(GetIndicatorBufferValue(handle, BUFFER_LIQUIDITY_GRAB_HIGH, 1));
        levels.liquidity_grab_low = ValidateSignal(GetIndicatorBufferValue(handle, BUFFER_LIQUIDITY_GRAB_LOW, 1));

        if (levels.liquidity_grab_high || levels.liquidity_grab_low)
        {
            levels.grab_time = iTime(_Symbol, Period(), 1);
        }
    }

    //--- Enhanced swing detection
    levels.swing_highs = iHigh(_Symbol, Period(), iHighest(_Symbol, Period(), MODE_HIGH, 100, 1));
    levels.swing_lows = iLow(_Symbol, Period(), iLowest(_Symbol, Period(), MODE_LOW, 100, 1));

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
    //--- Higher timeframe bias filter
    if (bias == BIAS_BEARISH)
        return TRADE_NONE;

    //--- Structure confirmation
    if (!base.bullish_choch || base.structure_strength < 2)
        return TRADE_NONE;
    if (!confirm.bullish_choch)
        return TRADE_NONE;

    //--- RSI filter for confluence
    if (conditions.rsi_value > 80)
        return TRADE_NONE; // Overbought

    //--- Check order block setup
    if (UseOrderBlocks && obs.is_valid && obs.bullish_ob_low > 0 && obs.bullish_ob_high > 0)
    {
        if (ask >= obs.bullish_ob_low && ask <= obs.bullish_ob_high)
        {
            // Additional validation for order block
            if (ValidateOrderBlockEntry(obs, true, ask))
            {
                return TRADE_ORDER_BLOCK;
            }
        }
    }

    //--- Check FVG setup
    if (UseFairValueGaps && fvgs.is_valid && fvgs.bullish_fvg_low > 0 && fvgs.bullish_fvg_high > 0)
    {
        if (ask >= fvgs.bullish_fvg_low && ask <= fvgs.bullish_fvg_high)
        {
            return TRADE_FAIR_VALUE_GAP;
        }
    }

    //--- Check liquidity grab setup
    if (UseLiquidityGrabs && liq.liquidity_grab_low)
    {
        // Price should be near the liquidity grab level
        double distance = MathAbs(ask - liq.swing_lows) / PointMultiplier;
        if (distance <= 100) // Within 10 pips
        {
            return TRADE_LIQUIDITY_GRAB;
        }
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
    //--- Higher timeframe bias filter
    if (bias == BIAS_BULLISH)
        return TRADE_NONE;

    //--- Structure confirmation
    if (!base.bearish_choch || base.structure_strength < 2)
        return TRADE_NONE;
    if (!confirm.bearish_choch)
        return TRADE_NONE;

    //--- RSI filter for confluence
    if (conditions.rsi_value < 20)
        return TRADE_NONE; // Oversold

    //--- Check order block setup
    if (UseOrderBlocks && obs.is_valid && obs.bearish_ob_low > 0 && obs.bearish_ob_high > 0)
    {
        if (bid >= obs.bearish_ob_low && bid <= obs.bearish_ob_high)
        {
            if (ValidateOrderBlockEntry(obs, false, bid))
            {
                return TRADE_ORDER_BLOCK;
            }
        }
    }

    //--- Check FVG setup
    if (UseFairValueGaps && fvgs.is_valid && fvgs.bearish_fvg_low > 0 && fvgs.bearish_fvg_high > 0)
    {
        if (bid >= fvgs.bearish_fvg_low && bid <= fvgs.bearish_fvg_high)
        {
            return TRADE_FAIR_VALUE_GAP;
        }
    }

    //--- Check liquidity grab setup
    if (UseLiquidityGrabs && liq.liquidity_grab_high)
    {
        double distance = MathAbs(bid - liq.swing_highs) / PointMultiplier;
        if (distance <= 100) // Within 10 pips
        {
            return TRADE_LIQUIDITY_GRAB;
        }
    }

    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| Execute Enhanced Buy Trade
// ...existing code...

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
    //--- Calculate stop loss and take profit
    double sl = 0, tp = 0;
    double entry = ask;

    //--- Default SL/TP (can be enhanced per setup)
    if (setup == TRADE_ORDER_BLOCK && order_blocks.bullish_ob_low > 0)
        sl = order_blocks.bullish_ob_low - (StopLossPips * PointMultiplier);
    else if (setup == TRADE_FAIR_VALUE_GAP && fvgs.bullish_fvg_low > 0)
        sl = fvgs.bullish_fvg_low - (StopLossPips * PointMultiplier);
    else
        sl = entry - (StopLossPips * PointMultiplier);

    tp = entry + (TakeProfitPips * PointMultiplier);

    //--- Calculate lot size based on risk
    double lot = CalculateLotSize(entry, sl, RiskPerTradePercent);

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
    request.comment = TradeComment;

    if (OrderSend(request, result))
    {
        Print("✅ Buy order placed: ", "Entry=", entry, " SL=", sl, " TP=", tp, " Lot=", lot);

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
            Trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        double new_sl = current_price + trailing_distance;
        if (new_sl < current_sl && new_sl < open_price)
        {
            Trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
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
            Trade.PositionModify(ticket, open_price, PositionGetDouble(POSITION_TP));
            Print("✅ Breakeven set for buy position: ", ticket);
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        if (current_price <= open_price - breakeven_distance && current_sl > open_price)
        {
            Trade.PositionModify(ticket, open_price, PositionGetDouble(POSITION_TP));
            Print("✅ Breakeven set for sell position: ", ticket);
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
            Trade.PositionClosePartial(ticket, close_volume);
            Print("📊 Partial close executed: ", close_volume, " lots at ", current_price);
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