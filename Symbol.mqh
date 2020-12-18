struct Properties
  {
   string label;
   int    multiplier,
          bound_begin,
          bound_finish,
          begin_time[3],
          finish_time[3];
   double loss[3],
          profit[3],
          tick_size,
          trade_cost,
          close;
  };

namespace Paibot
{
class Symbol
  {
private:
   Properties      none;

   Properties      GetWDO(string symbol);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

Properties Symbol::GetProperties(string symbol)
  {
   if(symbol == "WDO$N") return GetWDO(symbol);

   return none;
  }

Properties Symbol::GetWDO(string symbol)
  {
   Properties wdo;

   wdo.label          = "WDO";
   wdo.multiplier     = 10;
   wdo.bound_begin    =  9;
   wdo.bound_finish   = 16;
   wdo.begin_time[0]  =  9;
   wdo.begin_time[1]  = 10;
   wdo.begin_time[2]  =  1;
   wdo.finish_time[0] = 12;
   wdo.finish_time[1] = 16;
   wdo.finish_time[2] =  1;
   wdo.loss[0]        =  5;
   wdo.loss[1]        = 95;
   wdo.loss[2]        =  5;
   wdo.profit[0]      =  5;
   wdo.profit[1]      = 95;
   wdo.profit[2]      =  5;
   wdo.tick_size      =  0.5;
   wdo.trade_cost     =  2.4;
   wdo.close          = iClose(symbol, 0, 0);

   return wdo;
  }
}
