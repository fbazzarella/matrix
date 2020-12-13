enum ENUM_LOGGER_KEY
  {
   COUNT          = 0,
   WITH_LOSS      = 1,
   WITH_PROFIT    = 2,
   OPENED         = 3,
   OPENED_MAX     = 4,
   OPENED_ABORTED = 5,
   BALANCE_FINAL  = 6
  };

namespace Paibot
{
class Logger
  {
private:
   string          parent_id;
   double          data_compiled[7];
   string          data_balance_chain,
                   data_raw[];
   int             data_raw_size;
public:
                   Logger(void);
                  ~Logger(void){};

   void            SetParentId(string _parent_id);
   double          GetValue(ENUM_LOGGER_KEY key);
   void            Increment(ENUM_LOGGER_KEY key, double value);
   void            KeepMax(ENUM_LOGGER_KEY key, double value);
   void            AddBalance(double balance);
   void            AddDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit);
   void            PrintDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit);
   void            PrintDataCompiled(void);
  };

void Logger::Logger(void)
  {
   for(int i = 0; i < ArraySize(data_compiled); i++) data_compiled[i] = 0;

   data_balance_chain = "0\t";
   data_raw_size      = 0;
  }

void Logger::SetParentId(string _parent_id)
  {
   parent_id = _parent_id;
  }

double Logger::GetValue(ENUM_LOGGER_KEY key)
  {
   return data_compiled[key];
  }

void Logger::Increment(ENUM_LOGGER_KEY key, double value)
  {
   data_compiled[key] += value;
  }

void Logger::KeepMax(ENUM_LOGGER_KEY key, double value)
  {
   data_compiled[key] = MathMax(data_compiled[key], value);
  }

void Logger::AddBalance(double balance)
  {
   StringConcatenate(data_balance_chain, data_balance_chain, (string)balance + "\t");

   data_compiled[BALANCE_FINAL] += balance;
  }

void Logger::AddDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit)
  {
   uint   time_diff = (uint)(time_closed - time_opened);
   string prices_chain,
          data_raw_chain;

   StringConcatenate(prices_chain, price_for_loss, "\t", price_opened, "\t", price_for_profit, "\t",
      price_closed, "\t", tick.bid, "\t", tick.last, "\t", tick.ask, "\t", balance, "\t", data_compiled[BALANCE_FINAL]);

   StringReplace(prices_chain, ".", ",");

   StringConcatenate(data_raw_chain, "invalid", "\t", time_opened, "\t",
      time_closed, "\t", time_diff, "\t", side, "\t", prices_chain);

   ArrayResize(data_raw, ++data_raw_size);
   
   data_raw[data_raw_size - 1] = data_raw_chain;
  }

void Logger::PrintDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit)
  {
   Print(parent_id + ": " + side +
      " position opened at "      + DoubleToString(price_opened, 2) +
      " and closed at "           + DoubleToString(price_closed, 2) +
      " with a balance of R$ "    + DoubleToString(balance,      2) +
      ". Total of "               + DoubleToString(data_compiled[COUNT],         0) +
      " positions and "           + DoubleToString(data_compiled[OPENED],        0) +
      " currently opened with a"  +
      " partial balance of "      + DoubleToString(data_compiled[BALANCE_FINAL], 2) + " BRL." );
  }

void Logger::PrintDataCompiled(void)
  {
   if(data_compiled[COUNT] > 0)
     {
      Print("Position stats for '" + parent_id + "':");
      Print("| count          " + DoubleToString(data_compiled[COUNT],          0));
      Print("| with loss      " + DoubleToString(data_compiled[WITH_LOSS],      0) +
                           " (" + DoubleToString(data_compiled[WITH_LOSS]   / data_compiled[COUNT] * 100, 1) + "%)");
      Print("| with profit    " + DoubleToString(data_compiled[WITH_PROFIT],    0) +
                           " (" + DoubleToString(data_compiled[WITH_PROFIT] / data_compiled[COUNT] * 100, 1) + "%)");
      Print("| opened         " + DoubleToString(data_compiled[OPENED],         0));
      Print("| opened max     " + DoubleToString(data_compiled[OPENED_MAX],     0));
      Print("| opened aborted " + DoubleToString(data_compiled[OPENED_ABORTED], 0));
      Print("| final balance  " + DoubleToString(data_compiled[BALANCE_FINAL],  2) + " BRL");
      Print(""); Print(""); Print(""); Print("");
     }
  }
}
