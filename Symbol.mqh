struct Properties
  {
   double          close;
   ENUM_TIMEFRAMES timeframes[];
   int             ma_short[3],
                   ma_long[3],
                   bound_begin,
                   bound_finish,
                   time_begin[3],
                   time_finish[3];
   double          loss[3],
                   profit[3],
                   tick_size,
                   comission,
                   multiplier;
   string          label,
                   id,
                   hash;
  };

namespace Matrix
{
class Symbol
  {
private:
   static string   equities[];

   Properties      none;

   Properties      GetEquity(string symbol);
   Properties      GetIBOV(string symbol, double multiplier, string label);
   Properties      GetUSD(string symbol, double multiplier, string label);
   Properties      Future(string symbol);
   Properties      Base(string symbol);
   void            SetIdAndHash(Properties &properties);
                   template<typename T>
   void            ArrayConcatenate(string &id, T &array[]);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

string Symbol::equities[] = { "PETR4", "VALE3" };

Properties Symbol::GetProperties(string symbol)
  {
   for(int i = 0; i < ArraySize(equities); i++) if(symbol == equities[i]) return GetEquity(symbol              ); //   1 BRL/tick
                                                if(symbol == "WIN$N"    ) return GetIBOV  (symbol,   0.2, "win"); //   1
                                                if(symbol == "IND$N"    ) return GetIBOV  (symbol,   5.0, "ind"); //  25
                                                if(symbol == "WDO$N"    ) return GetUSD   (symbol,  10.0, "wdo"); //   5
                                                if(symbol == "DOL$N"    ) return GetUSD   (symbol, 250.0, "dol"); // 125
   return none;
  }

Properties Symbol::GetEquity(string symbol)
  {
   Properties equity      = Base(symbol);

   equity.bound_begin     =   10; // ==> xx:00
   equity.bound_finish    =   15; // ==> xx:59
 
   equity.time_begin[0]   =   10; // ==> xx:00
   equity.time_begin[1]   =   11;
   equity.time_begin[2]   =    1;
 
   equity.time_finish[0]  =   11; // ==> xx:59
   equity.time_finish[1]  =   15;
   equity.time_finish[2]  =    1;
 
   equity.loss[0]         =    0.1;
   equity.loss[1]         =    1.9;
   equity.loss[2]         =    0.1;
 
   equity.profit[0]       =    0.1;
   equity.profit[1]       =    1.9;
   equity.profit[2]       =    0.1;
 
   equity.tick_size       =    0.01;
   equity.multiplier      =  100;
   equity.label           = symbol;
   
   SetIdAndHash(equity);

   return equity;
  }

Properties Symbol::GetIBOV(string symbol, double multiplier, string label)
  {
   Properties ibov        = Future(symbol);

   // ArrayResize(ibov.timeframes, 1);

   // ibov.timeframes[0]     = PERIOD_M1;

   ibov.time_begin[0]     =    9; // ==> xx:00
   ibov.time_begin[1]     =   16;
   ibov.time_begin[2]     =    1;

   ibov.time_finish[0]    =    9; // ==> xx:59
   ibov.time_finish[1]    =   16;
   ibov.time_finish[2]    =    1;

   ibov.loss[0]           =    5;
   ibov.loss[1]           =  955;
   ibov.loss[2]           =   50;

   ibov.profit[0]         =    5;
   ibov.profit[1]         =  955;
   ibov.profit[2]         =   50;

   ibov.tick_size         =    5;
   ibov.comission         =    0.5;
   ibov.multiplier        = multiplier;
   ibov.label             = label;
   
   SetIdAndHash(ibov);

   return ibov;
  }

Properties Symbol::GetUSD(string symbol, double multiplier, string label)
  {
   Properties usd         = Future(symbol);

   // ArrayResize(usd.timeframes, 1);

   // usd.timeframes[0]      = PERIOD_M1;

   usd.time_begin[0]      =   9; // ==> xx:00
   usd.time_begin[1]      =  16;
   usd.time_begin[2]      =   1;

   usd.time_finish[0]     =   9; // ==> xx:59
   usd.time_finish[1]     =  16;
   usd.time_finish[2]     =   1;

   usd.loss[0]            =   5;
   usd.loss[1]            =  95;
   usd.loss[2]            =   5;

   usd.profit[0]          =   5;
   usd.profit[1]          =  95;
   usd.profit[2]          =   5;

   usd.tick_size          =   0.5;
   usd.comission          =   2.28;
   usd.multiplier         = multiplier;
   usd.label              = label;
   
   SetIdAndHash(usd);

   return usd;
  }

Properties Symbol::Future(string symbol)
  {
   Properties future      = Base(symbol);

   future.bound_begin     =  9; // ==> xx:00
   future.bound_finish    = 16; // ==> xx:59

   return future;
  }

Properties Symbol::Base(string symbol)
  {
   Properties base;

   base.close             = iClose(symbol, 0, 0);

   ArrayResize(base.timeframes, 11);

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

   base.ma_long[0]        = 14;
   base.ma_long[1]        = 14;
   base.ma_long[2]        =  7;

   base.comission         =  0;

   return base;
  }

void Symbol::SetIdAndHash(Properties &properties)
  {
   string id = "id";

   ArrayConcatenate(id, properties.timeframes);
   ArrayConcatenate(id, properties.ma_short);
   ArrayConcatenate(id, properties.ma_long);
   ArrayConcatenate(id, properties.time_begin);
   ArrayConcatenate(id, properties.time_finish);
   ArrayConcatenate(id, properties.loss);
   ArrayConcatenate(id, properties.profit);

   StringReplace(id, "id_", "");

   properties.id   = id;
   properties.hash = (string)GetHashCode(id);
  }

     template<typename T>
void Symbol::ArrayConcatenate(string &id, T &array[])
  {
   for(int i = 0; i < ArraySize(array); i++) StringConcatenate(id, id, "_", (string)array[i]);
  }
}
