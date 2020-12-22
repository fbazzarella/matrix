﻿namespace Paibot
{
class Opener
  {
private:
   ENUM_TIMEFRAMES timeframe;
   int             ma_short,
                   ma_long;
   uint            ma_short_handler,
                   ma_long_handler;
   int             begin_time,
                   finish_time;
   double          loss[],
                   profit[];
   MqlTick         tick;
   PositionBucket  buckets[];
   int             buckets_size,
                   tick_count;

   string          GetFileName(void);
   string          GetOpenerId(double loss, double profit);
   int             GetSideFromMA(void);
   double          GetPriceFromMASide(int side);
public:
                   Opener(void);
                  ~Opener(void){};

   void            OnInit(int handler_data_raw, ENUM_TIMEFRAMES _timeframe, int _begin_time, int _finish_time, int _ma_short, int _ma_long, uint _ma_short_handler, uint _ma_long_handler, double &_loss[], double &_profit[]);
   void            OnDeinit(int handler_data_compiled);
   void            OnTick(MqlTick &_tick);
                   template<typename Book>
   void            OnTimer(Properties &symbol_properties, Book &book);
  };

void Opener::Opener(void)
  {
   buckets_size = 0;
   tick_count   = 0;
  }

void Opener::OnInit(int handler_data_raw, ENUM_TIMEFRAMES _timeframe, int _begin_time, int _finish_time, int _ma_short, int _ma_long, uint _ma_short_handler, uint _ma_long_handler, double &_loss[], double &_profit[])
  {
   timeframe        = _timeframe;
   begin_time       = _begin_time;
   finish_time      = _finish_time;
   ma_short         = _ma_short;
   ma_long          = _ma_long;
   ma_short_handler = _ma_short_handler;
   ma_long_handler  = _ma_long_handler;

   ArrayCopy(loss,   _loss);
   ArrayCopy(profit, _profit);

   for(double __loss = loss[0]; __loss <= loss[1]; __loss += loss[2])
     {
      for(double __profit = profit[0]; __profit <= profit[1]; __profit += profit[2])
        {
         ArrayResize(buckets, ++buckets_size);

         buckets[buckets_size - 1].SetProperties(GetOpenerId(__loss, __profit), handler_data_raw);
        }
     }
  }

void Opener::OnDeinit(int handler_data_compiled)
  {
   for(int i = 0; i < buckets_size; i++)
     {
      buckets[i].CloseAllPositions(tick);

      if(dump_data_compiled) buckets[i].DumpDataCompiled(handler_data_compiled);
     }
  }

void Opener::OnTick(MqlTick &_tick)
  {
   tick = _tick;
   tick_count++;
  }

     template<typename Book>
void Opener::OnTimer(Properties &symbol_properties, Book &book)
  {
   MqlDateTime now;
   TimeTradeServer(now);

   int session_period = GetSessionPeriod(symbol_properties.bound_begin, symbol_properties.bound_finish, begin_time, finish_time);

   if(now.min % (int)timeframe == 0 && session_period == 1 && tick_count > 0)
     {
      int    i     = 0,
             side  = GetSideFromMA();
      double price = GetPriceFromMASide(side);

      for(double __loss = loss[0]; __loss <= loss[1]; __loss += loss[2])
        {
         for(double __profit = profit[0]; __profit <= profit[1]; __profit += profit[2])
           {
            buckets[i++].OpenPosition(symbol_properties, book, side, price, __loss, __profit);
           }
        }

      tick_count = 0;
     }

   else if(session_period == 3) for(int i = 0; i < buckets_size; i++) buckets[i].CloseAllPositions(tick);
  }

string Opener::GetOpenerId(double _loss, double _profit)
  {
   string opener_id,
          iformat = "%02i",
          dformat = "%07.2f";

   StringConcatenate(opener_id, StringFormat(iformat, timeframe), "_",
      StringFormat(iformat, begin_time), "_",StringFormat(iformat, finish_time), "_",
      StringFormat(iformat, ma_short), "_", StringFormat(iformat, ma_long), "_",
      StringFormat(dformat, _loss), "_", StringFormat(dformat, _profit));

   return opener_id;
  }

int Opener::GetSideFromMA(void)
  {
   double ma_short_buffer[],
          ma_long_buffer[];

   CopyBuffer(ma_short_handler, 0, 0, 2, ma_short_buffer);
   CopyBuffer(ma_long_handler,  0, 0, 2, ma_long_buffer);
   
   return ma_short_buffer[0] - ma_long_buffer[0] < ma_short_buffer[1] - ma_long_buffer[1] ? 1 : -1;
  }

double Opener::GetPriceFromMASide(int side)
  {
   double price = 0;

   if(tick.bid < tick.ask) price = side == -1 ? tick.bid : tick.ask;

   return price;
  }
}
