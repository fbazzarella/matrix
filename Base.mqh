#include "Helpers/Array.mqh";
#include "Helpers/Environment.mqh";
#include "Helpers/MovingAverage.mqh";
#include "Helpers/Time.mqh";
#include "Symbol.mqh";
#include "Logger.mqh";
#include "Position.mqh";
#include "PositionBucket.mqh";
#include "Opener.mqh";
#include "Order.mqh";
#include "OrderBucket.mqh";
#include "Book.mqh";

namespace Matrix
{
class Base
  {
private:
   bool            symbol_dayoff;
   string          commit_hash;

   ENUM_TIMEFRAMES timeframes[];
   int             ma_short[],
                   ma_long[];
   int             time_begin[],
                   time_finish[];
   double          loss[],
                   profit[];

   Symbol          symbol;
   Book            book;
   Opener          openers[];
   int             openers_size,
                   handler_data_raw;

   int             GetFileHandler(string type);
   void            PrintComment(string message);
public:
                   Base(string _commit_hash);
                  ~Base(void){};

   bool            OnInit(void);
   void            OnDeinit(void);
   void            OnTick(void);
   void            OnTimer(void);
  };

void Base::Base(string _commit_hash)
  {
   symbol_dayoff = false;
   commit_hash   = _commit_hash;
   openers_size  = 0;
  }

bool Base::OnInit(void)
  {
   if(!symbol.OnInit(_Symbol)) return false;

   ArrayCopy(timeframes,  symbol.properties.timeframes);
   ArrayCopy(ma_short,    symbol.properties.ma_short);
   ArrayCopy(ma_long,     symbol.properties.ma_long);
   ArrayCopy(time_begin,  symbol.properties.time_begin);
   ArrayCopy(time_finish, symbol.properties.time_finish);
   ArrayCopy(loss,        symbol.properties.loss);
   ArrayCopy(profit,      symbol.properties.profit);

   book.SetProperties(symbol.properties.close, symbol.properties.tick_size);

   handler_data_raw = matrix_global_dump_data_raw ? GetFileHandler("raw") : -1;

   for(int i = 0; i < ArraySize(timeframes); i++)
     {
      for(int _ma_short = ma_short[0]; _ma_short <= ma_short[1]; _ma_short += ma_short[2])
        {
         for(int _ma_long = ma_long[0]; _ma_long <= ma_long[1]; _ma_long += ma_long[2])
           {
            if(_ma_short >= _ma_long) continue;

            uint ma_short_handler = iMA(_Symbol, timeframes[i], _ma_short, 0, MODE_EMA, PRICE_CLOSE),
                 ma_long_handler  = iMA(_Symbol, timeframes[i], _ma_long,  0, MODE_EMA, PRICE_CLOSE);

            for(int _time_begin = time_begin[0]; _time_begin <= time_begin[1]; _time_begin += time_begin[2])
              {
               for(int _time_finish = time_finish[0]; _time_finish <= time_finish[1]; _time_finish += time_finish[2])
                 {
                  if(_time_begin > _time_finish) continue;

                  ArrayResize(openers, ++openers_size);

                  openers[openers_size - 1].OnInit(handler_data_raw, timeframes[i], _ma_short, _ma_long, ma_short_handler, ma_long_handler, _time_begin, _time_finish, loss, profit);
                 }
              }
           }
        }
     }

   Print((string)matrix_global_parameters_count + " total parameters and ", (string)(int)(TimeTradeServer() - matrix_global_time_initialization), " seconds to initialize.");

   return true;
  }

void Base::OnDeinit(void)
  {
   int handler_data_compiled = matrix_global_dump_data_compiled ? GetFileHandler("compiled") : -1;

   for(int i = 0; i < openers_size; i++) openers[i].OnDeinit(handler_data_compiled);

   if(matrix_global_dump_data_compiled) FileClose(handler_data_compiled);
   if(matrix_global_dump_data_raw)      FileClose(handler_data_raw);

   PrintComment("Matrix removed.");
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
      if(now.hour == 8 && now.min == 0) symbol_dayoff = symbol.IsTodayADayOff();

      if(!symbol_dayoff)
        {
         for(int i = 0; i < openers_size; i++) openers[i].OnTimer(symbol.properties, book);

         int bound_begin    = symbol.properties.bound_begin,
             bound_finish   = symbol.properties.bound_finish,
             session_period = GetSessionPeriod(bound_begin, bound_finish, bound_begin, bound_finish);

         matrix_global_time_activity_flag = session_period == 1 || session_period == 2;
         
         if(session_period == 3) book.Reset();
        }
     }

   if(matrix_global_time_activity_flag) PrintComment("Last activity " + (string)matrix_global_time_activity_count++ + " seconds ago.");
   else                                 PrintComment("There is no activity.");
  }

int Base::GetFileHandler(string type)
  {
   bool   tester = MQLInfoInteger(MQL_TESTER);
   int    flag   = tester ? TIME_DATE : TIME_DATE|TIME_SECONDS;
   string mode   = tester ? "tester" : "demo",
          label  = symbol.properties.label,
          order  = symbol.properties.order,
          dates  = T2S(matrix_global_time_initialization, flag),
          set_n  = (string)matrix_global_parameters_set_n,
          set_of = (string)matrix_global_parameters_set_of,
          set    = set_n + "of" + set_of;
   
   if(type == "compiled") StringConcatenate(dates, dates, "_", T2S(TimeTradeServer(), flag, true));

   return FileOpen("Matrix/" + (matrix_global_execution_group != "" ? matrix_global_execution_group + "/" : "")
                   + mode + "_" + label + "_" + type + "_" + dates + order + "_" + set + "_" + commit_hash
                   + ".csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");
  }

void Base::PrintComment(string message)
  {
   Comment((string)matrix_global_parameters_count + " total parameters. " + message);
  }
}
