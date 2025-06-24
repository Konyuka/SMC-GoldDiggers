//+------------------------------------------------------------------+
//|                                                      SMC_GoldEA.mq5 |
//|                                                     (c) 2024, GM |
//|                                          https://www.google.com/ |
//+------------------------------------------------------------------+
#property copyright "(c) 2024, GM"
#property link "https://www.google.com/"
#property version "1.00"
#property description "Expert Advisor for Gold using LuxAlgo Smart Money Concepts (SMC) Indicator."

//--- Include necessary MQL5 libraries for trading operations
#include <Trade/Trade.mqh>        // Standard library for sending trade requests
#include <Arrays/ArrayDouble.mqh> // For handling dynamic arrays (indicator buffers)

//--- Input parameters for the EA ---
sinput string StrategySettings = "--- Strategy Settings ---";
input ENUM_TIMEFRAMES BaseTimeframe = PERIOD_H4;    // Base timeframe for primary market structure (e.g., H4)
input ENUM_TIMEFRAMES ConfirmTimeframe = PERIOD_H1; // Confirmation timeframe for entries (e.g., H1 or M30)
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_D1;  // Higher timeframe for overall bias (e.g., D1 or W1)
input double RiskPerTradePercent = 1.0;             // Risk per trade as a percentage of balance (e.g., 1.0 = 1%)
input int MaxOpenTrades = 5;                        // Maximum number of open trades by this EA
input int Slippage = 5;                             // Max price slippage in points

sinput string SMCIndicatorSettings = "--- SMC Indicator Settings ---";
input string SMC_Indicator_Name = "LuxAlgo - Smart Money Concepts"; // Exact name of your .ex5 file without extension
// Add more SMC indicator inputs here as needed, matching your .ex5 inputs.
// Example:
// input bool        SMC_ShowBOS = true;
// input bool        SMC_ShowCHoCH = true;
// input bool        SMC_ShowOrderBlocks = true;
// input bool        SMC_ShowFVG = true;

sinput string TradingHours = "--- Trading Hours (Server Time) ---";
input int StartHour = 0; // Start hour for trading (0-23)
input int EndHour = 23;  // End hour for trading (0-23)

//--- Global variables ---
CTrade m_trade;             // Instance of the CTrade class for trading operations
double g_point;             // Stores the point value for the current symbol
string g_symbol;            // Stores the current symbol name
int g_digits;               // Stores the number of decimal digits for the current symbol
datetime lastTradeTime = 0; // To prevent multiple trades on the same tick (or within a short period)

//--- Handles for the SMC indicator on different timeframes ---
int h_smc_base_tf;
int h_smc_confirm_tf;
int h_smc_higher_tf;

//--- Indicator buffer IDs (These are assumptions and MUST be verified from your .ex5 documentation or MetaEditor) ---
// You might need to examine the indicator's buffers using MetaEditor's Navigator -> Indicators -> Right-click -> Properties -> Colors tab
// Or use the MQL5 Reference for iCustom to understand common buffer indexing for SMC-like indicators.
enum ENUM_SMC_BUFFERS
{
    SMC_BUFFER_BULLISH_CHoCH = 0,            // Example: Buffer for bullish CHoCH signal
    SMC_BUFFER_BEARISH_CHoCH = 1,            // Example: Buffer for bearish CHoCH signal
    SMC_BUFFER_BULLISH_BOS = 2,              // Example: Buffer for bullish BOS signal
    SMC_BUFFER_BEARISH_BOS = 3,              // Example: Buffer for bearish BOS signal
    SMC_BUFFER_BULLISH_ORDER_BLOCK_HIGH = 4, // Example: Buffer for Bullish OB High price
    SMC_BUFFER_BULLISH_ORDER_BLOCK_LOW = 5,  // Example: Buffer for Bullish OB Low price
    SMC_BUFFER_BEARISH_ORDER_BLOCK_HIGH = 6, // Example: Buffer for Bearish OB High price
    SMC_BUFFER_BEARISH_ORDER_BLOCK_LOW = 7,  // Example: Buffer for Bearish OB Low price
    SMC_BUFFER_BULLISH_FVG_HIGH = 8,         // Example: Buffer for Bullish FVG High price
    SMC_BUFFER_BULLISH_FVG_LOW = 9,          // Example: Buffer for Bullish FVG Low price
    SMC_BUFFER_BEARISH_FVG_HIGH = 10,        // Example: Buffer for Bearish FVG High price
    SMC_BUFFER_BEARISH_FVG_LOW = 11,         // Example: Buffer for Bearish FVG Low price
    SMC_BUFFER_EQ_HIGH = 12,                 // Example: Buffer for Equal Highs
    SMC_BUFFER_EQ_LOW = 13,                  // Example: Buffer for Equal Lows
    // ... add more buffers as needed for other SMC features you want to use (e.g., Premium/Discount Zones)
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialize global variables ---
    g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    g_symbol = _Symbol;
    g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    //--- Check if lot size is valid ---
    if (LotSize <= 0 && RiskPerTradePercent <= 0)
    {
        Print("ERROR: LotSize or RiskPerTradePercent must be greater than 0!");
        return INIT_PARAMETERS_INCORRECT;
    }

    //--- Create handles for the SMC indicator on different timeframes ---
    // The iCustom function takes parameters in the order they appear in the indicator's Inputs tab.
    // You MUST verify these parameters (e.g., SMC_ShowBOS, SMC_ShowCHoCH) if your .ex5 indicator has them.
    // If your .ex5 indicator doesn't expose these inputs, you can remove them from iCustom().
    h_smc_base_tf = iCustom(g_symbol, BaseTimeframe, SMC_Indicator_Name);
    h_smc_confirm_tf = iCustom(g_symbol, ConfirmTimeframe, SMC_Indicator_Name);
    h_smc_higher_tf = iCustom(g_symbol, HigherTimeframe, SMC_Indicator_Name);

    //--- Check if indicator handles were created successfully ---
    if (h_smc_base_tf == INVALID_HANDLE || h_smc_confirm_tf == INVALID_HANDLE || h_smc_higher_tf == INVALID_HANDLE)
    {
        Print("ERROR: Failed to get SMC indicator handle. Check indicator name and parameters.");
        return INIT_FAILED;
    }

    //--- Initialize CTrade object ---
    m_trade.SetExpertMagic(MagicNumber);
    m_trade.SetDeviationInPoints(Slippage);

    Print("SMC_GoldEA initialized successfully for ", g_symbol);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    //--- Release indicator handles ---
    if (h_smc_base_tf != INVALID_HANDLE)
        IndicatorRelease(h_smc_base_tf);
    if (h_smc_confirm_tf != INVALID_HANDLE)
        IndicatorRelease(h_smc_confirm_tf);
    if (h_smc_higher_tf != INVALID_HANDLE)
        IndicatorRelease(h_smc_higher_tf);
    Print("SMC_GoldEA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Basic checks to prevent excessive operations ---
    if (IsTradeAllowed() == false || IsTesting() && IsOptimization())
        return; // Don't trade if trading is disabled or during optimization

    // Prevent re-entry on the same tick if logic is complex and takes time
    if (TimeCurrent() == lastTradeTime)
        return;
    lastTradeTime = TimeCurrent();

    //--- Get current price information ---
    MqlTick latest_tick;
    SymbolInfoTick(g_symbol, latest_tick);
    double bid_price = latest_tick.bid;
    double ask_price = latest_tick.ask;

    //--- Check if current trading hour is within allowed range ---
    int current_hour = TimeHour(TimeCurrent());
    if (current_hour < StartHour || current_hour >= EndHour)
    {
        // Print("Current hour ", current_hour, " is outside trading hours."); // Uncomment for debugging
        return;
    }

    //--- Strategy Implementation ---
    // We'll focus on opening new trades if no open positions managed by this EA
    if (CountPositionsByMagic(MagicNumber) < MaxOpenTrades)
    {
        // --- Get SMC data from indicator buffers ---
        // We'll primarily get data for the most recent closed bar (index 1) for signals
        // Current bar (index 0) can be volatile.
        double base_choc_bullish_signal = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BULLISH_CHoCH, 1);
        double base_choc_bearish_signal = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BEARISH_CHoCH, 1);
        double base_bos_bullish_signal = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BULLISH_BOS, 1);
        double base_bos_bearish_signal = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BEARISH_BOS, 1);

        double confirm_choc_bullish_signal = GetSMCBufferValue(h_smc_confirm_tf, SMC_BUFFER_BULLISH_CHoCH, 1);
        double confirm_choc_bearish_signal = GetSMCBufferValue(h_smc_confirm_tf, SMC_BUFFER_BEARISH_CHoCH, 1);
        // We could also get Order Blocks, FVGs, etc., from buffers here for more complex logic.
        double base_bullish_ob_low = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BULLISH_ORDER_BLOCK_LOW, 0); // Current OB might be forming
        double base_bullish_ob_high = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BULLISH_ORDER_BLOCK_HIGH, 0);
        double base_bearish_ob_low = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BEARISH_ORDER_BLOCK_LOW, 0);
        double base_bearish_ob_high = GetSMCBufferValue(h_smc_base_tf, SMC_BUFFER_BEARISH_ORDER_BLOCK_HIGH, 0);

        //--- Get higher timeframe bias ---
        double higher_tf_bos_bullish_signal = GetSMCBufferValue(h_smc_higher_tf, SMC_BUFFER_BULLISH_BOS, 1);
        double higher_tf_bos_bearish_signal = GetSMCBufferValue(h_smc_higher_tf, SMC_BUFFER_BEARISH_BOS, 1);

        bool higher_tf_bullish_bias = (higher_tf_bos_bullish_signal != 0.0); // Assuming non-zero means signal
        bool higher_tf_bearish_bias = (higher_tf_bos_bearish_signal != 0.0); // Assuming non-zero means signal

        // --- BUY LOGIC ---
        // Example Strategy:
        // 1. Higher Timeframe (H1/D1) is Bullish (BOS).
        // 2. Base Timeframe (H4) shows a recent Bullish CHoCH AND a Bullish BOS.
        // 3. Current price retraces into a Bullish Order Block (or FVG).
        // 4. Confirmation Timeframe (H1) shows a Bullish CHoCH.

        // This is a simplified logic. You'll expand on this with your precise rules.
        bool entry_buy_condition = false;
        if (higher_tf_bullish_bias && base_choc_bullish_signal != 0.0 && base_bos_bullish_signal != 0.0)
        {
            // Check if price is within the Bullish Order Block (requires precise OB buffer values)
            // This assumes the OB values are valid (not EMPTY_VALUE) and reflect current OBs.
            if (base_bullish_ob_low != EMPTY_VALUE && base_bullish_ob_high != EMPTY_VALUE &&
                ask_price >= base_bullish_ob_low && ask_price <= base_bullish_ob_high)
            {
                // Confirmation from lower timeframe (optional, but good for scalping/day trading)
                if (confirm_choc_bullish_signal != 0.0)
                {
                    entry_buy_condition = true;
                    Print("BUY Signal: HFT Bullish, H4 CHoCH/BOS, Price in OB, H1 CHoCH.");
                }
            }
        }

        if (entry_buy_condition)
        {
            // Calculate Stop Loss (e.g., just below the order block low, or a fixed amount below entry)
            double sl_price = base_bullish_ob_low - (StopLossPips * g_point); // Place SL below the OB

            // Calculate Take Profit (e.g., fixed pips or target next liquidity/opposing OB)
            double tp_price = ask_price + TakeProfitPips * g_point; // Initial TP, can be dynamic

            // Normalize prices to symbol's digits
            sl_price = NormalizeDouble(sl_price, g_digits);
            tp_price = NormalizeDouble(tp_price, g_digits);

            // Ensure SL/TP are valid (above/below current price for buy/sell)
            if (sl_price >= ask_price || tp_price <= ask_price)
            {
                Print("Invalid SL/TP for BUY. SL: ", sl_price, ", TP: ", tp_price, ", Ask: ", ask_price);
                return;
            }

            // Calculate Lot Size based on risk
            double calculated_lots = CalculateLotSize(RiskPerTradePercent, sl_price, ask_price);

            if (calculated_lots > 0)
            {
                if (m_trade.Buy(calculated_lots, g_symbol, ask_price, sl_price, tp_price, CommentString))
                {
                    PrintFormat("BUY Order sent: %s Lots: %.2f SL: %.5f TP: %.5f", g_symbol, calculated_lots, sl_price, tp_price);
                }
            }
        }

        // --- SELL LOGIC ---
        // Similarly for SELL:
        // 1. Higher Timeframe (H1/D1) is Bearish (BOS).
        // 2. Base Timeframe (H4) shows a recent Bearish CHoCH AND a Bearish BOS.
        // 3. Current price retraces into a Bearish Order Block (or FVG).
        // 4. Confirmation Timeframe (H1) shows a Bearish CHoCH.

        bool entry_sell_condition = false;
        if (higher_tf_bearish_bias && base_choc_bearish_signal != 0.0 && base_bos_bearish_signal != 0.0)
        {
            // Check if price is within the Bearish Order Block
            if (base_bearish_ob_low != EMPTY_VALUE && base_bearish_ob_high != EMPTY_VALUE &&
                bid_price >= base_bearish_ob_low && bid_price <= base_bearish_ob_high)
            {
                // Confirmation from lower timeframe
                if (confirm_choc_bearish_signal != 0.0)
                {
                    entry_sell_condition = true;
                    Print("SELL Signal: HFT Bearish, H4 CHoCH/BOS, Price in OB, H1 CHoCH.");
                }
            }
        }

        if (entry_sell_condition)
        {
            // Calculate Stop Loss (e.g., just above the order block high)
            double sl_price = base_bearish_ob_high + (StopLossPips * g_point);

            // Calculate Take Profit
            double tp_price = bid_price - TakeProfitPips * g_point;

            // Normalize prices
            sl_price = NormalizeDouble(sl_price, g_digits);
            tp_price = NormalizeDouble(tp_price, g_digits);

            // Ensure SL/TP are valid
            if (sl_price <= bid_price || tp_price >= bid_price)
            {
                Print("Invalid SL/TP for SELL. SL: ", sl_price, ", TP: ", tp_price, ", Bid: ", bid_price);
                return;
            }

            // Calculate Lot Size based on risk
            double calculated_lots = CalculateLotSize(RiskPerTradePercent, bid_price, sl_price);

            if (calculated_lots > 0)
            {
                if (m_trade.Sell(calculated_lots, g_symbol, bid_price, sl_price, tp_price, CommentString))
                {
                    PrintFormat("SELL Order sent: %s Lots: %.2f SL: %.5f TP: %.5f", g_symbol, calculated_lots, sl_price, tp_price);
                }
            }
        }
    }
    else
    {
        // --- Manage Open Positions (e.g., trailing stop, partial close, break-even) ---
        // This is where your exit logic beyond initial SL/TP would go.
        // For simplicity, this example just prints a message.
        // You would iterate through open positions and apply your management rules.
        // Example: Iterate through positions:
        // PositionSelectByMagic(MagicNumber, g_symbol);
        // long position_ticket = PositionGetTicket();
        // double current_profit = PositionGetDouble(POSITION_PROFIT);
        // ... then modify/close if conditions are met.
    }
}

//+------------------------------------------------------------------+
//| Helper function to get SMC indicator buffer value                |
//+------------------------------------------------------------------+
// This function attempts to read a value from a specified indicator buffer at a given bar index.
// Returns EMPTY_VALUE if the handle is invalid or data cannot be copied.
double GetSMCBufferValue(int indicator_handle, int buffer_index, int bar_index)
{
    if (indicator_handle == INVALID_HANDLE)
        return EMPTY_VALUE;

    CArrayDouble buffer_array;
    buffer_array.Resize(2); // We only need the value for one or two bars

    // Copy buffer data from the indicator handle
    // CopyBuffer(indicator_handle, buffer_index, start_position, count, destination_array)
    if (CopyBuffer(indicator_handle, buffer_index, bar_index, 1, buffer_array.GetData()) == 0)
    {
        return EMPTY_VALUE; // No data copied
    }

    // Return the value at the specified index relative to the copied data (which is usually 0 for the first element)
    return buffer_array.At(0);
}

//+------------------------------------------------------------------+
//| Helper function to count open positions by Magic Number          |
//+------------------------------------------------------------------+
int CountPositionsByMagic(int magic)
{
    int count = 0;
    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong position_ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(position_ticket))
        {
            if (PositionGetInteger(POSITION_MAGIC) == magic && PositionGetString(POSITION_SYMBOL) == g_symbol)
            {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Function to calculate lot size based on risk percentage          |
//+------------------------------------------------------------------+
// Calculates lot size based on a percentage of account balance and stop loss distance.
// Ensures lot size is within symbol's min/max and step.
double CalculateLotSize(double risk_percent, double entry_price, double sl_price)
{
    if (risk_percent <= 0 || AccountInfoDouble(ACCOUNT_BALANCE) <= 0)
    {
        Print("CalculateLotSize Error: Invalid risk percent or account balance.");
        return 0.0;
    }

    // Calculate stop loss distance in points
    double sl_distance_pips = MathAbs(entry_price - sl_price) / g_point;
    if (sl_distance_pips <= 0)
    {
        Print("CalculateLotSize Error: Stop Loss distance is zero or negative.");
        return 0.0;
    }

    // Calculate value per pip for a standard lot (1.00 lot)
    // For Gold (XAUUSD), 1 lot is 100 ounces. 1 pip movement is $1 per ounce.
    // So 1 lot movement of 1 point (0.01 for XAUUSD) is $1.
    // For USD quoted pairs (like EURUSD), value per pip = 10 USD (for 5-digit broker, 1 pip = 0.0001, so 1 lot = 100,000 units. 100,000 * 0.0001 = 10 USD per pip).
    // Given XAUUSD, where a point is 0.01 USD, and 1 lot is 100 units (ounces)
    // Value of 1 standard lot (1.0) per point = 1 USD (for XAUUSD, where SYMBOL_POINT is 0.01).
    // Or, value per lot per pip (for 4-digit broker) or value per lot per point (for 5-digit broker).

    // Correct value per lot calculation for Gold (XAUUSD)
    // 1 standard lot of XAUUSD is 100 ounces.
    // If point is 0.01 ($0.01 per ounce movement)
    // 1 point movement on 1 standard lot = 100 ounces * 0.01 USD/ounce = 1 USD.
    double value_per_point_per_lot = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
    // Alternatively, for XAUUSD, it's often simpler: 1 point (0.01) move on 1 standard lot (100 units) means 1 USD change.
    // So if SL distance is X points, and 1 lot changes by 1 USD per point, risk is X USD per lot.

    // Calculate monetary risk per lot
    double monetary_risk_per_lot = sl_distance_pips * value_per_point_per_lot;
    if (monetary_risk_per_lot <= 0)
    {
        Print("CalculateLotSize Error: Monetary risk per lot is zero or negative. Check symbol settings.");
        return 0.0;
    }

    // Calculate maximum risk in account currency
    double max_risk_amount = AccountInfoDouble(ACCOUNT_BALANCE) * (risk_percent / 100.0);

    // Calculate desired lots
    double desired_lots = max_risk_amount / monetary_risk_per_lot;

    // Adjust for symbol's minimum, maximum, and step size
    double min_lot = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_STEP);

    // Normalize to the nearest valid lot step
    desired_lots = NormalizeDouble(floor(desired_lots / lot_step) * lot_step, 2); // Round down to ensure we don't exceed risk

    // Apply min/max constraints
    desired_lots = MathMax(min_lot, MathMin(desired_lots, max_lot));

    // Ensure we don't open trades if the calculated lot size is too small or invalid
    if (desired_lots < min_lot)
    {
        Print("Calculated lot size (", desired_lots, ") is less than minimum lot (", min_lot, "). Not trading.");
        return 0.0;
    }

    PrintFormat("Calculated Lot Size: %.2f (Risk: %.2f%%, SL Pips: %.2f)", desired_lots, risk_percent, sl_distance_pips);
    return desired_lots;
}

/*
//+------------------------------------------------------------------+
//| Trade Class for simplified trading operations (replaced by CTrade) |
//| You can use the built-in CTrade class (from MQL5/Include/Trade/Trade.mqh) |
//| or create a simplified one like this for basic operations.       |
//+------------------------------------------------------------------+
class CTrade // This class is commented out as we are using the built-in CTrade
  {
public:
   //--- Order properties
   MqlTradeRequest m_request;
   MqlTradeResult  m_result;
   CSymbolInfo     m_symbol_info;
   CAccountInfo    m_account_info;

   CTrade()
     {
      // Constructor: Initialize request and info objects
      ZeroMemory(m_request);
      ZeroMemory(m_result);
      m_symbol_info.Name(g_symbol);
     }

   //--- Send a buy order
   bool Buy(double lots, string symbol, double price, double sl, double tp, string comment)
     {
      m_request.action      = TRADE_ACTION_DEAL;         // Immediate execution
      m_request.symbol      = symbol;                    // Symbol
      m_request.volume      = lots;                      // Volume in lots
      m_request.price       = price;                     // Entry price (Ask for Buy)
      m_request.sl          = sl;                        // Stop Loss
      m_request.tp          = tp;                        // Take Profit
      m_request.deviation   = Slippage;                  // Allowed deviation from price
      m_request.type        = ORDER_TYPE_BUY;            // Order type
      m_request.type_filling = ORDER_FILLING_FOK;         // Fill or Kill
      m_request.comment     = comment;                   // Comment
      m_request.magic       = MagicNumber;               // Magic number

      // Send the order
      if (!OrderSend(m_request, m_result))
        {
         PrintFormat("OrderSend failed, error code %d", GetLastError());
         return false;
        }
      PrintFormat("OrderSend successful, deal ticket %I64d", m_result.deal);
      return true;
     }

   //--- Send a sell order (simplified)
   bool Sell(double lots, string symbol, double price, double sl, double tp, string comment)
     {
      m_request.action      = TRADE_ACTION_DEAL;
      m_request.symbol      = symbol;
      m_request.volume      = lots;
      m_request.price       = price; // Bid for Sell
      m_request.sl          = sl;
      m_request.tp          = tp;
      m_request.deviation   = Slippage;
      m_request.type        = ORDER_TYPE_SELL;
      m_request.type_filling = ORDER_FILLING_FOK;
      m_request.comment     = comment;
      m_request.magic       = MagicNumber;

      if (!OrderSend(m_request, m_result))
        {
         PrintFormat("OrderSend failed, error code %d", GetLastError());
         return false;
        }
      PrintFormat("OrderSend successful, deal ticket %I64d", m_result.deal);
      return true;
     }

    // --- You can add more trade functions here, e.g., ClosePosition, ModifyPosition, etc. ---
  };

//--- Create an instance of the CTrade class
CTrade Trade; // This line would be removed/changed if using built-in CTrade
*/
