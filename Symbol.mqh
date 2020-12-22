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
   Properties      none;

   Properties      GetWIN(string symbol);
   Properties      GetWDO(string symbol);
   Properties      GetIND(string symbol);
   Properties      GetDOL(string symbol);
   Properties      IBOV(string symbol);
   Properties      USD(string symbol);
   Properties      Future(string symbol);
   Properties      Base(string symbol);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

Properties Symbol::GetProperties(string symbol)
  {
   if(symbol == "WIN$N") return GetWIN(symbol);
   if(symbol == "WDO$N") return GetWDO(symbol);
   if(symbol == "IND$N") return GetIND(symbol);
   if(symbol == "DOL$N") return GetDOL(symbol); 

   return none;
  }

Properties Symbol::GetWIN(string symbol)
  {
   Properties win = IBOV(symbol);

   win.label      = "WIN";
   win.multiplier = 0.2;

   return win;
  }

Properties Symbol::GetWDO(string symbol)
  {
   Properties wdo = USD(symbol);

   wdo.label      = "WDO";
   wdo.multiplier = 10;

   return wdo;
  }

Properties Symbol::GetIND(string symbol)
  {
   Properties ind = IBOV(symbol);

   ind.label      = "IND";
   ind.multiplier = 5;

   return ind;
  }

Properties Symbol::GetDOL(string symbol)
  {
   Properties dol = USD(symbol);

   dol.label      = "DOL";
   dol.multiplier = 250;

   return dol;
  }

Properties Symbol::IBOV(string symbol)
  {
   Properties ibov = Future(symbol);

   ibov.loss[0]   =  50;
   ibov.loss[1]   = 950;
   ibov.loss[2]   =  50;
   ibov.profit[0] =  50;
   ibov.profit[1] = 950;
   ibov.profit[2] =  50;
   ibov.tick_size =   5;

   return ibov;
  }

Properties Symbol::USD(string symbol)
  {
   Properties usd = Future(symbol);

   usd.loss[0]   =  5;
   usd.loss[1]   = 95;
   usd.loss[2]   =  5;
   usd.profit[0] =  5;
   usd.profit[1] = 95;
   usd.profit[2] =  5;
   usd.tick_size =  0.5;

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
