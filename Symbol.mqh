struct Properties
  {
   double          close;
   ENUM_TIMEFRAMES timeframes[];
   int             ma_short[3],
                   ma_long[3],
                   bound_begin,
                   bound_finish,
                   begin_time[3],
                   finish_time[3];
   double          loss[3],
                   profit[3],
                   tick_size;
   string          label;
   double          multiplier;
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
   for(int i = 0; i < ArraySize(equities); i++) if(symbol == equities[i]) return GetEquity(symbol              ); //   1 BRL/tick
                                                if(symbol == "WIN$N"    ) return GetIBOV  (symbol, "WIN",   0.2); //   1
                                                if(symbol == "IND$N"    ) return GetIBOV  (symbol, "IND",   5.0); //  25
                                                if(symbol == "WDO$N"    ) return GetUSD   (symbol, "WDO",  10.0); //   5
                                                if(symbol == "DOL$N"    ) return GetUSD   (symbol, "DOL", 250.0); // 125
   return none;
  }

Properties Symbol::GetEquity(string symbol)
  {
   Properties equity      = Base(symbol);

   equity.bound_begin     =  10; // ==> xx:00
   equity.bound_finish    =  15; // ==> xx:59

   equity.begin_time[0]   =  10; // ==> xx:00
   equity.begin_time[1]   =  11;
   equity.begin_time[2]   =   1;

   equity.finish_time[0]  =  11; // ==> xx:59
   equity.finish_time[1]  =  15;
   equity.finish_time[2]  =   1;

   equity.loss[0]         =   0.1;
   equity.loss[1]         =   1.9;
   equity.loss[2]         =   0.1;

   equity.profit[0]       =   0.1;
   equity.profit[1]       =   1.9;
   equity.profit[2]       =   0.1;

   equity.tick_size       =   0.01;
   equity.label           = symbol;
   equity.multiplier      = 100;

   return equity;
  }

Properties Symbol::GetIBOV(string symbol, string label, double multiplier)
  {
   Properties ibov = Future(symbol);

   ibov.loss[0]           =  50;
   ibov.loss[1]           = 950;
   ibov.loss[2]           =  50;

   ibov.profit[0]         =  50;
   ibov.profit[1]         = 950;
   ibov.profit[2]         =  50;

   ibov.tick_size         =   5;
   ibov.label             = label;
   ibov.multiplier        = multiplier;

   return ibov;
  }

Properties Symbol::GetUSD(string symbol, string label, double multiplier)
  {
   Properties usd         = Future(symbol);

   usd.loss[0]            =  5;
   usd.loss[1]            = 95;
   usd.loss[2]            =  5;

   usd.profit[0]          =  5;
   usd.profit[1]          = 95;
   usd.profit[2]          =  5;

   usd.tick_size          =  0.5;
   usd.label              = label;
   usd.multiplier         = multiplier;

   return usd;
  }

Properties Symbol::Future(string symbol)
  {
   Properties future      = Base(symbol);

   future.bound_begin     =  9; // ==> xx:00
   future.bound_finish    = 16; // ==> xx:59

   future.begin_time[0]   =  9; // ==> xx:00
   future.begin_time[1]   = 10;
   future.begin_time[2]   =  1;

   future.finish_time[0]  = 12; // ==> xx:59
   future.finish_time[1]  = 16;
   future.finish_time[2]  =  1;

   return future;
  }

Properties Symbol::Base(string symbol)
  {
   Properties base;

   ArrayResize(base.timeframes, 11);

   base.close             = iClose(symbol, 0, 0);

   base.timeframes[0]     = PERIOD_M1;
   base.timeframes[1]     = PERIOD_M2;
   base.timeframes[2]     = PERIOD_M3;
   base.timeframes[3]     = PERIOD_M4;
   base.timeframes[4]     = PERIOD_M5;
   base.timeframes[5]     = PERIOD_M6;
   base.timeframes[6]     = PERIOD_M10;
   base.timeframes[7]     = PERIOD_M12;
   base.timeframes[8]     = PERIOD_M15;
   base.timeframes[9]     = PERIOD_M20;
   base.timeframes[10]    = PERIOD_M30;

   base.ma_short[0]       =  7;
   base.ma_short[1]       =  7;
   base.ma_short[2]       =  7;

   base.ma_long[0]        = 21;
   base.ma_long[1]        = 21;
   base.ma_long[2]        =  7;

   return base;
  }
}
