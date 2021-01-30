struct Properties
  {
   ENUM_TIMEFRAMES timeframes[];
   int             ma_short[],
                   ma_long[],
                   bound_begin,
                   bound_finish,
                   time_begin[],
                   time_finish[];
   double          loss[],
                   profit[],
                   close,
                   tick_size,
                   multiplier,
                   comission;
   string          label,
                   order;
  };

namespace Matrix
{
class Symbol
  {
private:
   Properties      none;
   Properties      GetFuture(string symbol, string parameters_order, string parameters_chain, double tick_size, double multiplier, double comission);
   bool            LoadParameters(string symbol, string &parameters[]);
   void            SetParameters(Properties &properties, string parameters_chain);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

Properties Symbol::GetProperties(string symbol)
  {
   string parameters[];

   if(!LoadParameters(symbol, parameters)) return none;

        if(symbol == "WIN$N") return GetFuture(symbol, parameters[1], parameters[2], 5.0,   0.2, 0.50); //   1 BRL/tick
   else if(symbol == "IND$N") return GetFuture(symbol, parameters[1], parameters[2], 5.0,   5.0, 0.00); //  25
   else if(symbol == "WDO$N") return GetFuture(symbol, parameters[1], parameters[2], 0.5,  10.0, 2.28); //   5
   else if(symbol == "DOL$N") return GetFuture(symbol, parameters[1], parameters[2], 0.5, 250.0, 0.00); // 125

   return none;
  }

Properties Symbol::GetFuture(string symbol, string parameters_order, string parameters_chain, double tick_size, double multiplier, double comission)
  {
   Properties future;

   future.bound_begin  =  9;
   future.bound_finish = 16;

   future.close        = iClose(symbol, 0, 0);
   future.label        = StringSubstr(symbol, 0, 3);
   future.order        = parameters_order;
   future.tick_size    = tick_size;
   future.multiplier   = multiplier;
   future.comission    = comission;

   StringToLower(future.label);
   SetParameters(future, parameters_chain);

   return future;
  }

bool Symbol::LoadParameters(string symbol, string &parameters[])
  {
   int handler = FileOpen("Matrix/_ParametersSets/" + symbol + ".csv", FILE_READ|FILE_TXT|FILE_COMMON|FILE_ANSI, ";");

   if(handler == -1) return false;

   while(!FileIsEnding(handler))
     {
      StringSplit(FileReadString(handler), StringGetCharacter(";", 0), parameters);

      if(parameters[0] == "use") break;
     }

   FileClose(handler);

   return true;
  }

void Symbol::SetParameters(Properties &properties, string parameters_chain)
  {
   string parameters[];
   
   StringSplit(parameters_chain, StringGetCharacter("#", 0), parameters);

   ArrayFillFromString(properties.timeframes,  parameters[0]);
   ArrayFillFromString(properties.ma_short,    parameters[1]);
   ArrayFillFromString(properties.ma_long,     parameters[2]);
   ArrayFillFromString(properties.time_begin,  parameters[3]);
   ArrayFillFromString(properties.time_finish, parameters[4]);
   ArrayFillFromString(properties.loss,        parameters[5]);
   ArrayFillFromString(properties.profit,      parameters[6]);
  }
}
