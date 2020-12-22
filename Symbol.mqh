struct Properties
  {
   double close;
   int    bound_begin,
          bound_finish,
          begin_time[3],
          finish_time[3];
   double loss[3],
          profit[3],
          tick_size;
   string label;
   double multiplier;
  };

namespace Paibot
{
class Symbol
  {
private:
   static string   equities[];

   Properties      none;

   Properties      GetEquity(string symbol);
   Properties      GetIBOV(string symbol, string label, double multiplier);
   Properties      GetUSD(string symbol, string label, double multiplier);
   Properties      Future(string symbol);
   Properties      Base(string symbol);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

string Symbol::equities[] = { "PETR4", "VALE3" };

Properties Symbol::GetProperties(string symbol)
  {
   for(int i = 0; i < ArraySize(equities); i++) if(symbol == equities[i]) return GetEquity(symbol              ); // R$   1,00 / tick
                                                if(symbol == "WIN$N"    ) return GetIBOV  (symbol, "WIN",   0.2); // R$   1,00 / tick
                                                if(symbol == "IND$N"    ) return GetIBOV  (symbol, "IND",   5.0); // R$  25,00 / tick
                                                if(symbol == "WDO$N"    ) return GetUSD   (symbol, "WDO",  10.0); // R$   5,00 / tick
                                                if(symbol == "DOL$N"    ) return GetUSD   (symbol, "DOL", 250.0); // R$ 125,00 / tick
   return none;
  }

Properties Symbol::GetEquity(string symbol)
  {
   Properties equity = Base(symbol);

   equity.bound_begin    =  10;
   equity.bound_finish   =  15; // ==> 15:59
   equity.begin_time[0]  =  10;
   equity.begin_time[1]  =  11;
   equity.begin_time[2]  =   1;
   equity.finish_time[0] =  11;
   equity.finish_time[1] =  15; // ==> xx:59
   equity.finish_time[2] =   1;
   equity.loss[0]        =   0.1;
   equity.loss[1]        =   1.9;
   equity.loss[2]        =   0.1;
   equity.profit[0]      =   0.1;
   equity.profit[1]      =   1.9;
   equity.profit[2]      =   0.1;
   equity.tick_size      =   0.01;
   equity.label          = symbol;
   equity.multiplier     = 100;

   return equity;
  }

Properties Symbol::GetIBOV(string symbol, string label, double multiplier)
  {
   Properties ibov = Future(symbol);

   ibov.loss[0]    =  50;
   ibov.loss[1]    = 950;
   ibov.loss[2]    =  50;
   ibov.profit[0]  =  50;
   ibov.profit[1]  = 950;
   ibov.profit[2]  =  50;
   ibov.tick_size  =   5;
   ibov.label      = label;
   ibov.multiplier = multiplier;

   return ibov;
  }

Properties Symbol::GetUSD(string symbol, string label, double multiplier)
  {
   Properties usd = Future(symbol);

   usd.loss[0]    =  5;
   usd.loss[1]    = 95;
   usd.loss[2]    =  5;
   usd.profit[0]  =  5;
   usd.profit[1]  = 95;
   usd.profit[2]  =  5;
   usd.tick_size  =  0.5;
   usd.label      = label;
   usd.multiplier = multiplier;

   return usd;
  }

Properties Symbol::Future(string symbol)
  {
   Properties future = Base(symbol);

   future.bound_begin    =  9;
   future.bound_finish   = 16; // ==> 16:59
   future.begin_time[0]  =  9;
   future.begin_time[1]  = 10;
   future.begin_time[2]  =  1;
   future.finish_time[0] = 12;
   future.finish_time[1] = 16; // ==> xx:59
   future.finish_time[2] =  1;

   return future;
  }

Properties Symbol::Base(string symbol)
  {
   Properties base;

   base.close = iClose(symbol, 0, 0);

   return base;
  }
}
