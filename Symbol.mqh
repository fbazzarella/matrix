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
   void            SetParameters(Properties &properties, string parameters_chain);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

Properties Symbol::GetProperties(string symbol)
  {
   string params_order_ibov = "01", params_chain_ibov = "1_2_3_4_5_6_10_12_15_20_30#7_7_7#14_14_7#9_16_1#9_16_1#5.0_955.0_50.0#5.0_955.0_50.0",
          params_order_usd  = "01", params_chain_usd  = "1_2_3_4_5_6_10_12_15_20_30#7_7_7#14_14_7#9_16_1#9_16_1#5.0_95.0_5.0#5.0_95.0_5.0";

   if(symbol == "WIN$N") return GetFuture(symbol, params_order_ibov, params_chain_ibov, 5.0,   0.2, 0.50); //   1 BRL/tick
   if(symbol == "IND$N") return GetFuture(symbol, params_order_ibov, params_chain_ibov, 5.0,   5.0, 0.50); //  25
   if(symbol == "WDO$N") return GetFuture(symbol, params_order_usd,  params_chain_usd,  0.5,  10.0, 2.28); //   5
   if(symbol == "DOL$N") return GetFuture(symbol, params_order_usd,  params_chain_usd,  0.5, 250.0, 2.28); // 125

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
