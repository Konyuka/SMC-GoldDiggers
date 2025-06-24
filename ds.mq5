//+------------------------------------------------------------------+
//|                                                      SMC_GoldEA.mq5 |
//|                        Copyright 2024, LuxAlgo & Smart Money Concepts |
//|                                       https://www.luxalgo.com/   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, LuxAlgo & Smart Money Concepts"
#property link "https://www.luxalgo.com/"
#property version "2.00"
#property description "Expert Advisor for Gold (XAUUSD) using LuxAlgo Smart Money Concepts"
#property description "Implements ICT/SMC strategies with multi-timeframe confirmation"

//--- Includes
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <Indicators/Indicator.mqh>

//--- Input Parameters
input group "Strategy Settings" input ENUM_TIMEFRAMES BaseTimeframe = PERIOD_H4; // Base timeframe (market structure)
input ENUM_TIMEFRAMES ConfirmTimeframe = PERIOD_H1;                              // Confirmation timeframe
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_D1;                               // Higher timeframe (bias)
input int MaxOpenTrades = 3;                                                     // Maximum open trades
input int Slippage = 5;                                                          // Slippage in points

input group "Risk Management" double RiskPerTradePercent = 1.0; // Risk per trade (% of balance)
int StopLossPips = 300;                                         // Default SL (30 pips for XAUUSD)
int TakeProfitPips = 600;                                       // Default TP (60 pips for XAUUSD)
input bool UseAutoRR = true;                                          // Use automatic risk-reward
input double MinRiskReward = 2.0;                                     // Minimum risk:reward ratio

input group "SMC Indicator Settings" input string SMC_Indicator_Name = "LuxAlgo - Smart Money Concepts"; // Indicator name
input int SMC_OB_Lookback = 20;                                                                          // Order block lookback (bars)
input int SMC_FVG_Lookback = 10;                                                                         // FVG lookback (bars)

input group "Trading Hours (GMT)" input int TradingStartHour = 13; // London/NY overlap start (8AM EST)
input int TradingEndHour = 17;                                     // London/NY overlap end (12PM EST)

input group "Advanced" input int MagicNumber = 20240624; // EA Magic Number
input string TradeComment = "SMC-Gold-EA";               // Trade comment

//--- Global Variables
CTrade Trade;
CPositionInfo PositionInfo;
CHistoryOrderInfo HistoryInfo;

double PointMultiplier;
int SMC_Base_Handle, SMC_Confirm_Handle, SMC_Higher_Handle;
datetime LastTradeTime;

//--- SMC Buffer Mapping (adjust based on your indicator analysis)
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
    BUFFER_EQ_LOWS = 13
};

//+------------------------------------------------------------------+
//| Market Structure Types                                           |
//+------------------------------------------------------------------+
enum ENUM_MARKET_BIAS
{
    BIAS_BULLISH,
    BIAS_BEARISH,
    BIAS_NEUTRAL
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
};

struct SOrderBlocks
{
    double bullish_ob_high;
    double bullish_ob_low;
    double bearish_ob_high;
    double bearish_ob_low;
    datetime ob_time;
};

struct SFairValueGaps
{
    double bullish_fvg_high;
    double bullish_fvg_low;
    double bearish_fvg_high;
    double bearish_fvg_low;
};

struct SLiquidityLevels
{
    double equal_highs;
    double equal_lows;
    double swing_highs;
    double swing_lows;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialize trading objects
    Trade.SetExpertMagicNumber(MagicNumber);
    Trade.SetDeviationInPoints(Slippage);
    Trade.SetTypeFilling(ORDER_FILLING_FOK);

    //--- Calculate point multiplier
    PointMultiplier = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10; // For XAUUSD (0.01 -> 0.10)

    //--- Create indicator handles
    SMC_Base_Handle = iCustom(_Symbol, BaseTimeframe, SMC_Indicator_Name);
    SMC_Confirm_Handle = iCustom(_Symbol, ConfirmTimeframe, SMC_Indicator_Name);
    SMC_Higher_Handle = iCustom(_Symbol, HigherTimeframe, SMC_Indicator_Name);

    if (SMC_Base_Handle == INVALID_HANDLE || SMC_Confirm_Handle == INVALID_HANDLE || SMC_Higher_Handle == INVALID_HANDLE)
    {
        Print("Error creating indicator handles!");
        return INIT_FAILED;
    }

    //--- Verify buffers (comment out after testing)
    AnalyzeIndicatorBuffers(SMC_Base_Handle);

    //--- Apply Gold-specific settings
    ApplyGoldSpecificSettings();

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release indicators
    if (SMC_Base_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Base_Handle);
    if (SMC_Confirm_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Confirm_Handle);
    if (SMC_Higher_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Higher_Handle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Basic checks
    // if (!IsTradeAllowed() || IsTradeContextBusy() || IsTesting() && IsOptimization())
    if (
        !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
        MQLInfoInteger(MQL_TRADE_ALLOWED) == false ||
        MQLInfoInteger(MQL_TESTER) && MQLInfoInteger(MQL_OPTIMIZATION))
        return;

    //--- Prevent multiple trades on same tick
    if (TimeCurrent() == LastTradeTime)
        return;
    LastTradeTime = TimeCurrent();

    //--- Check trading hours
    if (!IsTradingHours())
        return;

    //--- Check news filter
    if (IsHighImpactNews())
    {
        Print("High impact news - skipping trade");
        return;
    }

    //--- Check volatility
    if (IsExcessiveVolatility())
    {
        Print("Excessive volatility - skipping trade");
        return;
    }

    //--- Main trading logic
    CheckForTrades();

    //--- Manage open positions
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Main Trading Logic                                               |
//+------------------------------------------------------------------+
void CheckForTrades()
{
    MqlTick current_tick;
    if (!SymbolInfoTick(_Symbol, current_tick))
    {
        Print("Failed to get current tick!");
        return;
    }

    //--- Get market structure
    ENUM_MARKET_BIAS higher_tf_bias = GetHigherTimeframeBias();
    SMarketStructure base_structure = GetMarketStructure(SMC_Base_Handle);
    SMarketStructure confirm_structure = GetMarketStructure(SMC_Confirm_Handle);

    //--- Get SMC components
    SOrderBlocks order_blocks = GetOrderBlocks(SMC_Base_Handle);
    SFairValueGaps fvgs = GetFairValueGaps(SMC_Base_Handle);
    SLiquidityLevels liquidity = GetLiquidityLevels(SMC_Higher_Handle);

    //--- Check buy conditions
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) < MaxOpenTrades)
    {
        if (CheckBuyConditions(higher_tf_bias, base_structure, confirm_structure, order_blocks, fvgs, liquidity, current_tick.ask))
        {
            ExecuteBuyTrade(current_tick.ask, base_structure, order_blocks, liquidity);
        }
    }

    //--- Check sell conditions
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) < MaxOpenTrades)
    {
        if (CheckSellConditions(higher_tf_bias, base_structure, confirm_structure, order_blocks, fvgs, liquidity, current_tick.bid))
        {
            ExecuteSellTrade(current_tick.bid, base_structure, order_blocks, liquidity);
        }
    }
}

//+------------------------------------------------------------------+
//| Higher Timeframe Bias                                            |
//+------------------------------------------------------------------+
ENUM_MARKET_BIAS GetHigherTimeframeBias()
{
    SMarketStructure daily = GetMarketStructure(SMC_Higher_Handle);

    if (daily.bullish_bos && daily.bullish_choch)
        return BIAS_BULLISH;

    if (daily.bearish_bos && daily.bearish_choch)
        return BIAS_BEARISH;

    return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Get Market Structure                                             |
//+------------------------------------------------------------------+
SMarketStructure GetMarketStructure(int handle)
{
    SMarketStructure structure;

    //--- Get BOS/CHoCH signals
    structure.bullish_bos = GetIndicatorBufferValue(handle, BUFFER_BULLISH_BOS, 1) > 0;
    structure.bearish_bos = GetIndicatorBufferValue(handle, BUFFER_BEARISH_BOS, 1) > 0;
    structure.bullish_choch = GetIndicatorBufferValue(handle, BUFFER_BULLISH_CHOCH, 1) > 0;
    structure.bearish_choch = GetIndicatorBufferValue(handle, BUFFER_BEARISH_CHOCH, 1) > 0;

    //--- Get recent highs/lows (simplified - would be better with proper swing detection)
    structure.recent_high = iHigh(_Symbol, Period(), iHighest(_Symbol, Period(), MODE_HIGH, 20, 1));
    structure.recent_low = iLow(_Symbol, Period(), iLowest(_Symbol, Period(), MODE_LOW, 20, 1));

    return structure;
}

//+------------------------------------------------------------------+
//| Get Order Blocks                                                 |
//+------------------------------------------------------------------+
SOrderBlocks GetOrderBlocks(int handle)
{
    SOrderBlocks blocks;

    //--- Find most recent valid order blocks
    for (int i = 1; i <= SMC_OB_Lookback; i++)
    {
        double bull_high = GetIndicatorBufferValue(handle, BUFFER_BULLISH_OB_HIGH, i);
        double bull_low = GetIndicatorBufferValue(handle, BUFFER_BULLISH_OB_LOW, i);
        double bear_high = GetIndicatorBufferValue(handle, BUFFER_BEARISH_OB_HIGH, i);
        double bear_low = GetIndicatorBufferValue(handle, BUFFER_BEARISH_OB_LOW, i);

        if (bull_high > 0 && bull_low > 0 && blocks.bullish_ob_high == 0)
        {
            blocks.bullish_ob_high = bull_high;
            blocks.bullish_ob_low = bull_low;
            blocks.ob_time = iTime(_Symbol, Period(), i);
        }

        if (bear_high > 0 && bear_low > 0 && blocks.bearish_ob_high == 0)
        {
            blocks.bearish_ob_high = bear_high;
            blocks.bearish_ob_low = bear_low;
        }
    }

    return blocks;
}

//+------------------------------------------------------------------+
//| Get Fair Value Gaps                                              |
//+------------------------------------------------------------------+
SFairValueGaps GetFairValueGaps(int handle)
{
    SFairValueGaps fvgs;

    //--- Find most recent valid FVGs
    for (int i = 1; i <= SMC_FVG_Lookback; i++)
    {
        double bull_high = GetIndicatorBufferValue(handle, BUFFER_BULLISH_FVG_HIGH, i);
        double bull_low = GetIndicatorBufferValue(handle, BUFFER_BULLISH_FVG_LOW, i);
        double bear_high = GetIndicatorBufferValue(handle, BUFFER_BEARISH_FVG_HIGH, i);
        double bear_low = GetIndicatorBufferValue(handle, BUFFER_BEARISH_FVG_LOW, i);

        if (bull_high > 0 && bull_low > 0 && fvgs.bullish_fvg_high == 0)
        {
            fvgs.bullish_fvg_high = bull_high;
            fvgs.bullish_fvg_low = bull_low;
        }

        if (bear_high > 0 && bear_low > 0 && fvgs.bearish_fvg_high == 0)
        {
            fvgs.bearish_fvg_high = bear_high;
            fvgs.bearish_fvg_low = bear_low;
        }
    }

    return fvgs;
}

//+------------------------------------------------------------------+
//| Get Liquidity Levels                                             |
//+------------------------------------------------------------------+
SLiquidityLevels GetLiquidityLevels(int handle)
{
    SLiquidityLevels levels;

    //--- Get equal highs/lows
    levels.equal_highs = GetIndicatorBufferValue(handle, BUFFER_EQ_HIGHS, 1);
    levels.equal_lows = GetIndicatorBufferValue(handle, BUFFER_EQ_LOWS, 1);

    //--- Get swing highs/lows (simplified)
    levels.swing_highs = iHigh(_Symbol, Period(), iHighest(_Symbol, Period(), MODE_HIGH, 50, 1));
    levels.swing_lows = iLow(_Symbol, Period(), iLowest(_Symbol, Period(), MODE_LOW, 50, 1));

    return levels;
}

//+------------------------------------------------------------------+
//| Check Buy Conditions                                             |
//+------------------------------------------------------------------+
bool CheckBuyConditions(ENUM_MARKET_BIAS bias, SMarketStructure &base, SMarketStructure &confirm,
                        SOrderBlocks &obs, SFairValueGaps &fvgs, SLiquidityLevels &liq, double ask)
{
    // 1. Higher timeframe bias must be bullish or neutral
    if (bias == BIAS_BEARISH)
        return false;

    // 2. Base timeframe shows bullish structure
    if (!base.bullish_bos || !base.bullish_choch)
        return false;

    // 3. Confirmation timeframe agrees
    if (!confirm.bullish_choch)
        return false;

    // 4. Price is at a bullish order block or FVG
    bool in_bullish_zone = false;

    // Check order blocks
    if (obs.bullish_ob_low > 0 && obs.bullish_ob_high > 0)
    {
        if (ask >= obs.bullish_ob_low && ask <= obs.bullish_ob_high)
            in_bullish_zone = true;
    }

    // Check FVGs if not in OB
    if (!in_bullish_zone && fvgs.bullish_fvg_low > 0 && fvgs.bullish_fvg_high > 0)
    {
        if (ask >= fvgs.bullish_fvg_low && ask <= fvgs.bullish_fvg_high)
            in_bullish_zone = true;
    }

    if (!in_bullish_zone)
        return false;

    // 5. Check liquidity (we want to see equal lows or swing lows below)
    if (liq.equal_lows <= 0 && liq.swing_lows <= 0)
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Execute Buy Trade                                                |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(double entry_price, SMarketStructure &structure, SOrderBlocks &obs, SLiquidityLevels &liq)
{
    // Calculate stop loss
    double stop_loss = MathMin(structure.recent_low, obs.bullish_ob_low);
    stop_loss -= StopLossPips * PointMultiplier;

    // Calculate take profit
    double take_profit = liq.equal_highs > 0 ? liq.equal_highs : liq.swing_highs;

    // Adjust TP if needed for risk-reward
    if (UseAutoRR)
    {
        double risk = entry_price - stop_loss;
        double reward = take_profit - entry_price;

        if (reward < risk * MinRiskReward)
        {
            take_profit = entry_price + (risk * MinRiskReward);
        }
    }

    // Normalize prices
    stop_loss = NormalizeDouble(stop_loss, _Digits);
    take_profit = NormalizeDouble(take_profit, _Digits);

    // Calculate lot size
    double lots = CalculateLotSize(RiskPerTradePercent, entry_price, stop_loss);
    if (lots <= 0)
        return;

    // Send buy order
    if (Trade.Buy(lots, _Symbol, entry_price, stop_loss, take_profit, TradeComment))
    {
        Print("Buy order placed at ", entry_price, " SL: ", stop_loss, " TP: ", take_profit);
    }
}

//+------------------------------------------------------------------+
//| Check Sell Conditions                                            |
//+------------------------------------------------------------------+
bool CheckSellConditions(ENUM_MARKET_BIAS bias, SMarketStructure &base, SMarketStructure &confirm,
                         SOrderBlocks &obs, SFairValueGaps &fvgs, SLiquidityLevels &liq, double bid)
{
    // 1. Higher timeframe bias must be bearish or neutral
    if (bias == BIAS_BULLISH)
        return false;

    // 2. Base timeframe shows bearish structure
    if (!base.bearish_bos || !base.bearish_choch)
        return false;

    // 3. Confirmation timeframe agrees
    if (!confirm.bearish_choch)
        return false;

    // 4. Price is at a bearish order block or FVG
    bool in_bearish_zone = false;

    // Check order blocks
    if (obs.bearish_ob_low > 0 && obs.bearish_ob_high > 0)
    {
        if (bid >= obs.bearish_ob_low && bid <= obs.bearish_ob_high)
            in_bearish_zone = true;
    }

    // Check FVGs if not in OB
    if (!in_bearish_zone && fvgs.bearish_fvg_low > 0 && fvgs.bearish_fvg_high > 0)
    {
        if (bid >= fvgs.bearish_fvg_low && bid <= fvgs.bearish_fvg_high)
            in_bearish_zone = true;
    }

    if (!in_bearish_zone)
        return false;

    // 5. Check liquidity (we want to see equal highs or swing highs above)
    if (liq.equal_highs <= 0 && liq.swing_highs <= 0)
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                               |
//+------------------------------------------------------------------+
void ExecuteSellTrade(double entry_price, SMarketStructure &structure, SOrderBlocks &obs, SLiquidityLevels &liq)
{
    // Calculate stop loss
    double stop_loss = MathMax(structure.recent_high, obs.bearish_ob_high);
    stop_loss += StopLossPips * PointMultiplier;

    // Calculate take profit
    double take_profit = liq.equal_lows > 0 ? liq.equal_lows : liq.swing_lows;

    // Adjust TP if needed for risk-reward
    if (UseAutoRR)
    {
        double risk = stop_loss - entry_price;
        double reward = entry_price - take_profit;

        if (reward < risk * MinRiskReward)
        {
            take_profit = entry_price - (risk * MinRiskReward);
        }
    }

    // Normalize prices
    stop_loss = NormalizeDouble(stop_loss, _Digits);
    take_profit = NormalizeDouble(take_profit, _Digits);

    // Calculate lot size
    double lots = CalculateLotSize(RiskPerTradePercent, entry_price, stop_loss);
    if (lots <= 0)
        return;

    // Send sell order
    if (Trade.Sell(lots, _Symbol, entry_price, stop_loss, take_profit, TradeComment))
    {
        Print("Sell order placed at ", entry_price, " SL: ", stop_loss, " TP: ", take_profit);
    }
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double current_sl = PositionGetDouble(POSITION_SL);
            double current_tp = PositionGetDouble(POSITION_TP);
            double current_price = type == POSITION_TYPE_BUY ? PositionGetDouble(POSITION_PRICE_CURRENT) : PositionGetDouble(POSITION_PRICE_CURRENT);

            //--- Get current market structure
            SMarketStructure current_structure = GetMarketStructure(SMC_Base_Handle);

            //--- Handle buy positions
            if (type == POSITION_TYPE_BUY)
            {
                // Check for early exit if structure turns bearish
                if (current_structure.bearish_choch || current_structure.bearish_bos)
                {
                    Trade.PositionClose(ticket);
                    continue;
                }

                // Move stop to breakeven if not already
                if (current_sl < open_price && PositionGetDouble(POSITION_PROFIT) > 0)
                {
                    Trade.PositionModify(ticket, open_price, current_tp);
                }

                // Trailing stop
                double new_sl = current_price - (StopLossPips * PointMultiplier);
                if (new_sl > current_sl && new_sl > open_price)
                {
                    Trade.PositionModify(ticket, new_sl, current_tp);
                }
            }

            //--- Handle sell positions
            if (type == POSITION_TYPE_SELL)
            {
                // Check for early exit if structure turns bullish
                if (current_structure.bullish_choch || current_structure.bullish_bos)
                {
                    Trade.PositionClose(ticket);
                    continue;
                }

                // Move stop to breakeven if not already
                if (current_sl > open_price && PositionGetDouble(POSITION_PROFIT) > 0)
                {
                    Trade.PositionModify(ticket, open_price, current_tp);
                }

                // Trailing stop
                double new_sl = current_price + (StopLossPips * PointMultiplier);
                if (new_sl < current_sl && new_sl < open_price)
                {
                    Trade.PositionModify(ticket, new_sl, current_tp);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
double GetIndicatorBufferValue(int handle, int buffer, int shift)
{
    double buffer_value[];
    if (CopyBuffer(handle, buffer, shift, 1, buffer_value) <= 0)
    {
        Print("Error copying buffer ", buffer, " shift ", shift, " error ", GetLastError());
        return EMPTY_VALUE;
    }
    return buffer_value[0];
}

double CalculateLotSize(double risk_percent, double entry_price, double stop_loss)
{
    if (risk_percent <= 0 || AccountInfoDouble(ACCOUNT_BALANCE) <= 0)
    {
        Print("Invalid risk percentage or account balance");
        return 0.0;
    }

    // Calculate risk amount
    double risk_amount = AccountInfoDouble(ACCOUNT_BALANCE) * (risk_percent / 100.0);

    // Calculate risk per lot
    double risk_per_lot = MathAbs(entry_price - stop_loss) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    if (risk_per_lot <= 0)
    {
        Print("Invalid risk per lot calculation");
        return 0.0;
    }

    // Calculate lots
    double lots = risk_amount / risk_per_lot;

    // Normalize to allowed lot steps
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    lots = floor(lots / lot_step) * lot_step;

    // Apply min/max constraints
    lots = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),
                   MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)));

    return NormalizeDouble(lots, 2);
}

int CountPositionsByMagic(int magic, ENUM_POSITION_TYPE type = WRONG_VALUE)
{
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == magic)
        {
            if (type == WRONG_VALUE || (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == type)
            {
                count++;
            }
        }
    }
    return count;
}

bool IsTradingHours()
{
    datetime now = TimeCurrent();

    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;

    return (hour >= TradingStartHour && hour < TradingEndHour);
}

bool IsHighImpactNews()
{
    // Implement your own news checking logic here
    return false;
}

bool IsExcessiveVolatility()
{
    // Create ATR indicator handle
    int atr_handle = iATR(_Symbol, PERIOD_H1, 14);

    if (atr_handle == INVALID_HANDLE)
    {
        Print("Failed to create ATR indicator handle");
        return false;
    }

    // Array to store ATR values
    double atr_values[];
    ArraySetAsSeries(atr_values, true);

    // Copy ATR values (get the last completed bar - index 1)
    if (CopyBuffer(atr_handle, 0, 1, 1, atr_values) <= 0)
    {
        Print("Failed to copy ATR values");
        return false;
    }

    double atr = atr_values[0];
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double atr_percent = (atr / current_bid) * 100;

    return atr_percent > 0.5; // 0.5% of price
}

void ApplyGoldSpecificSettings()
{
    // Gold-specific adjustments
    StopLossPips = 300;        // 30 pips for XAUUSD
    TakeProfitPips = 600;      // 60 pips for XAUUSD
    RiskPerTradePercent = 0.5; // Lower risk for gold
}

void AnalyzeIndicatorBuffers(int handle)
{
    Print("===== Analyzing Indicator Buffers =====");
    for (int buffer = 0; buffer < 20; buffer++)
    {
        Print("Buffer ", buffer, " values:");
        for (int i = 1; i <= 10; i++)
        {
            double val = GetIndicatorBufferValue(handle, buffer, i);
            if (val != 0 && val != EMPTY_VALUE)
                Print("  Bar ", i, ": ", val);
        }
    }
}
//+------------------------------------------------------------------+