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
   string          id_parent,
                   id_tabulated;
   double          data_compiled[7];
   string          data_balance_chain,
                   data_raw[];
   int             data_raw_size;
public:
                   Logger(void);
                  ~Logger(void){};

   void            SetIdParent(string _id_parent);
   double          GetValue(ENUM_LOGGER_KEY key);
   string          GetValue(ENUM_LOGGER_KEY key, int precision);
   double          GetRate(ENUM_LOGGER_KEY key_numerator, ENUM_LOGGER_KEY key_denominator);
   string          GetRate(ENUM_LOGGER_KEY key_numerator, ENUM_LOGGER_KEY key_denominator, int precision);
   void            Increment(ENUM_LOGGER_KEY key, double value);
   void            KeepMax(ENUM_LOGGER_KEY key, double value);
   void            AddBalance(double balance);
   void            AddDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit);
   void            PrintDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit);
   void            PrintDataCompiled(void);
   void            DumpDataRaw(int handler);
   void            DumpDataCompiled(int handler);
  };

void Logger::Logger(void)
  {
   for(int i = 0; i < ArraySize(data_compiled); i++) data_compiled[i] = 0;

   data_balance_chain = "0\t";
   data_raw_size      = 0;
  }

void Logger::SetIdParent(string _id_parent)
  {
   id_parent = id_tabulated = _id_parent;

   StringReplace(id_tabulated, "_", "_\t");
  }

double Logger::GetValue(ENUM_LOGGER_KEY key)
  {
   return data_compiled[key];
  }

string Logger::GetValue(ENUM_LOGGER_KEY key, int precision)
  {
   return DoubleToString(data_compiled[key], precision);
  }

double Logger::GetRate(ENUM_LOGGER_KEY key_numerator, ENUM_LOGGER_KEY key_denominator)
  {
   double denominator = data_compiled[key_denominator];

   return denominator != 0 ? data_compiled[key_numerator] / denominator * 100 : 0;
  }

string Logger::GetRate(ENUM_LOGGER_KEY key_numerator, ENUM_LOGGER_KEY key_denominator, int precision)
  {
   return DoubleToString(GetRate(key_numerator, key_denominator), precision);
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
   data_compiled[BALANCE_FINAL] += balance;

   StringConcatenate(data_balance_chain, data_balance_chain, (string)data_compiled[BALANCE_FINAL] + "\t");
  }

void Logger::AddDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit)
  {
   uint   time_diff = (uint)(time_closed - time_opened);
   string prices_chain,
          data_raw_chain;

   StringConcatenate(prices_chain, price_for_loss, "\t", price_opened, "\t", price_for_profit, "\t", price_closed, "\t",
      tick.bid, "\t", tick.last, "\t", tick.ask, "\t", balance, "\t", data_compiled[BALANCE_FINAL]);

   StringReplace(prices_chain, ".", ",");

   StringConcatenate(data_raw_chain, "!", "\t", id_parent, "\t", time_opened, "\t",
      time_closed, "\t", time_diff, "\t", side, "\t", prices_chain);

   ArrayResize(data_raw, ++data_raw_size);
   
   data_raw[data_raw_size - 1] = data_raw_chain;
  }

void Logger::PrintDataRaw(MqlTick &tick, string side, double price_closed, double balance, datetime time_closed, datetime time_opened, double price_opened, double price_for_loss, double price_for_profit)
  {
   Print(id_parent + ": " + side +
      " position opened at "     + DoubleToString(price_opened, 2) +
      " and closed at "          + DoubleToString(price_closed, 2) +
      " with a balance of R$ "   + DoubleToString(balance, 2) +
      ". Total of "              + GetValue(COUNT, 0) +
      " positions and "          + GetValue(OPENED, 0) +
      " currently opened with a" +
      " partial balance of "     + GetValue(BALANCE_FINAL, 2) + " BRL." );
  }

void Logger::PrintDataCompiled(void)
  {
   if(data_compiled[COUNT] == 0) return;

   Print("Position stats for '" + id_parent + "':");
   Print("| count          "    + GetValue(COUNT, 0));
   Print("| with loss      "    + GetValue(WITH_LOSS, 0) + " (" + GetRate(WITH_LOSS, COUNT, 1) + "%)");
   Print("| with profit    "    + GetValue(WITH_PROFIT, 0) + " (" + GetRate(WITH_PROFIT, COUNT, 1) + "%)");
   Print("| opened         "    + GetValue(OPENED, 0));
   Print("| opened max     "    + GetValue(OPENED_MAX, 0));
   Print("| opened aborted "    + GetValue(OPENED_ABORTED, 0));
   Print("| final balance  "    + GetValue(BALANCE_FINAL, 2) + " BRL");
   Print(""); Print(""); Print(""); Print("");
  }

void Logger::DumpDataRaw(int handler)
  {
   for(int i = 0; i < data_raw_size; i++) FileWrite(handler, data_raw[i]);
  }

void Logger::DumpDataCompiled(int handler)
  {
   string profit_rate  = "0",
          prices_chain,
          data_compiled_chain;

   if(data_compiled[COUNT] > 0) profit_rate = GetRate(WITH_PROFIT, COUNT, 3);

   StringConcatenate(prices_chain, profit_rate, "\t", GetValue(BALANCE_FINAL, 2), "\t", data_balance_chain);

   StringReplace(prices_chain, ".", ",");

   StringConcatenate(data_compiled_chain, "!", "\t", id_tabulated, "_\t", id_parent, "\t",
     GetValue(COUNT, 0), "\t", GetValue(WITH_LOSS, 0), "\t", GetValue(WITH_PROFIT, 0), "\t",
     GetValue(OPENED_MAX, 0), "\t", GetValue(OPENED_ABORTED, 0), "\t", prices_chain);

   FileWrite(handler, data_compiled_chain);
  }
}
