#include <MyLibs\Paibot\TimeHelper.mqh>
#include <MyLibs\Paibot\Symbol.mqh>
#include <MyLibs\Paibot\Logger.mqh>
#include <MyLibs\Paibot\Position.mqh>
#include <MyLibs\Paibot\PositionBucket.mqh>
#include <MyLibs\Paibot\Opener.mqh>
#include <MyLibs\Paibot\Order.mqh>
#include <MyLibs\Paibot\OrderBucket.mqh>
#include <MyLibs\Paibot\Book.mqh>

namespace Paibot
{
class Base
  {
private:
   static ENUM_TIMEFRAMES timeframes[];
   static int      ma_short[],
                   ma_long[];
   int             begin_time[],
                   finish_time[];
   double          loss[],
                   profit[];

   Symbol          symbol;
   Properties      symbol_properties;
   Book            book;
   Opener          openers[];
   int             openers_size,
                   handler_data_raw;

   bool            CheckSymbolProperties(void);
   int             GetFileHandler(string _path);
public:
                   Base(void);
                  ~Base(void){};

   bool            OnInit(void);
   void            OnDeinit(void);
   void            OnTick(void);
   void            OnTimer(void);
  };

ENUM_TIMEFRAMES Base::timeframes[] = { PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4, PERIOD_M5, PERIOD_M6,
                                       PERIOD_M10, PERIOD_M12, PERIOD_M15, PERIOD_M20, PERIOD_M30 };
int             Base::ma_short[]   = {  7,  7, 7 },
                Base::ma_long[]    = { 21, 21, 7 };

void Base::Base(void)
  {
   openers_size = 0;
  }

bool Base::OnInit(void)
  {
   symbol_properties = symbol.GetProperties(_Symbol);

   if(!CheckSymbolProperties()) return false;

   ArrayCopy(begin_time,  symbol_properties.begin_time);
   ArrayCopy(finish_time, symbol_properties.finish_time);
   ArrayCopy(loss,        symbol_properties.loss);
   ArrayCopy(profit,      symbol_properties.profit);

   book.SetProperties(symbol_properties.close, symbol_properties.tick_size);

   handler_data_raw = GetFileHandler("raw");

   for(int i = 0; i < ArraySize(timeframes); i++)
     {
      for(int _ma_short = ma_short[0]; _ma_short <= ma_short[1]; _ma_short += ma_short[2])
        {
         for(int _ma_long = ma_long[0]; _ma_long <= ma_long[1]; _ma_long += ma_long[2])
           {
            if(_ma_short >= _ma_long) continue;

            uint ma_short_handler = iMA(_Symbol, timeframes[i], _ma_short, 0, MODE_EMA, PRICE_CLOSE),
                 ma_long_handler  = iMA(_Symbol, timeframes[i], _ma_long,  0, MODE_EMA, PRICE_CLOSE);

            for(int _begin_time = begin_time[0]; _begin_time <= begin_time[1]; _begin_time += begin_time[2])
              {
               for(int _finish_time = finish_time[0]; _finish_time <= finish_time[1]; _finish_time += finish_time[2])
                 {
                  if(_begin_time > _finish_time) continue;

                  ArrayResize(openers, ++openers_size);

                  openers[openers_size - 1].OnInit(handler_data_raw, timeframes[i], _begin_time, _finish_time, _ma_short, _ma_long, ma_short_handler, ma_long_handler, loss, profit);
                 }
              }
           }
        }
     }

   return true;
  }

void Base::OnDeinit(void)
  {
   FileClose(handler_data_raw);

   int handler_data_compiled = GetFileHandler("compiled");

   for(int i = 0; i < openers_size; i++) openers[i].OnDeinit(handler_data_compiled);

   FileClose(handler_data_compiled);
  }

void Base::OnTick(void)
  {
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);

   book.OnTick(tick);

   for(int i = 0; i < openers_size; i++) openers[i].OnTick(tick);
  }

void Base::OnTimer(void)
  {
   MqlDateTime now;
   TimeTradeServer(now);

   if(now.sec == 0)
     {
      for(int i = 0; i < openers_size; i++) openers[i].OnTimer(symbol_properties, book);

      int bound_begin  = symbol_properties.bound_begin,
          bound_finish = symbol_properties.bound_finish;

      if(GetSessionPeriod(bound_begin, bound_finish, bound_begin, bound_finish) == 3) book.Reset();
     }
  }

bool Base::CheckSymbolProperties(void)
  {
   if(symbol_properties.close == 0){ Print("ERROR: Please check the Symbol used."); return false; };

   return true;
  }

int Base::GetFileHandler(string _path)
  {
   string terminal = MQLInfoInteger(MQL_TESTER) ? "tester" : "simulator",
          path     = terminal + "/" + symbol_properties.label + "/" + _path + "/",
          name     = symbol_properties.label + "_" + T2S(time_initialization) + ".csv";

   return FileOpen(path + name, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");
  }
}
