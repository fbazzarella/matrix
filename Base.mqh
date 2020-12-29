#include "Helpers/Environment.mqh";
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
   ENUM_TIMEFRAMES timeframes[];
   int             ma_short[],
                   ma_long[];
   int             time_begin[],
                   time_finish[];
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
   void            PrintComment(string message);
public:
                   Base(void);
                  ~Base(void){};

   bool            OnInit(void);
   void            OnDeinit(void);
   void            OnTick(void);
   void            OnTimer(void);
  };

void Base::Base(void)
  {
   openers_size = 0;
  }

bool Base::OnInit(void)
  {
   symbol_properties = symbol.GetProperties(_Symbol);

   if(!CheckSymbolProperties()) return false;

   ArrayCopy(timeframes,  symbol_properties.timeframes);
   ArrayCopy(ma_short,    symbol_properties.ma_short);
   ArrayCopy(ma_long,     symbol_properties.ma_long);
   ArrayCopy(time_begin,  symbol_properties.time_begin);
   ArrayCopy(time_finish, symbol_properties.time_finish);
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

   Print((string)matrix_global_parameters_count + " total parameters.");

   return true;
  }

void Base::OnDeinit(void)
  {
   int handler_data_compiled = GetFileHandler("compiled");

   for(int i = 0; i < openers_size; i++) openers[i].OnDeinit(handler_data_compiled);

   FileClose(handler_data_compiled);
   FileClose(handler_data_raw);

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
      for(int i = 0; i < openers_size; i++) openers[i].OnTimer(symbol_properties, book);

      int bound_begin    = symbol_properties.bound_begin,
          bound_finish   = symbol_properties.bound_finish,
          session_period = GetSessionPeriod(bound_begin, bound_finish, bound_begin, bound_finish);

      matrix_global_time_activity_flag = session_period == 1 || session_period == 2;
      
      if(session_period == 3) book.Reset();
     }

   if(matrix_global_time_activity_flag) PrintComment("Last activity " + (string)matrix_global_time_activity_count++ + " seconds ago.");
   else PrintComment("There is no activity.");
  }

bool Base::CheckSymbolProperties(void)
  {
   if(symbol_properties.close == 0){ Print("ERROR: Please check the Symbol used."); return false; };

   return true;
  }

int Base::GetFileHandler(string _path)
  {
   string mode  = MQLInfoInteger(MQL_TESTER) ? "tester" : "demo",
          label = symbol_properties.label,
          path  = mode + "/" + label + "/" + _path + "/",
          name  = label + "_" + T2S(matrix_global_time_initialization) + ".csv";

   return FileOpen(path + name, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");
  }

void Base::PrintComment(string message)
  {
   Comment((string)matrix_global_parameters_count + " total parameters. " + message);
  }
}
