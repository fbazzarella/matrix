#include <MyLibs\Paibot\PositionBucket.mqh>

namespace Paibot
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
                   session_period,
                   tick_count;
   string          format_double;

   string          GetFileName(void);
   string          GetTestId(double loss, double profit);
   int             GetSideFromMA(void);
   double          GetPriceFromMASide(int side);
public:
                   Opener(void);
                  ~Opener(void){};

   void            OnInit(ENUM_TIMEFRAMES _timeframe, int _begin_time, int _finish_time, int _ma_short, int _ma_long, uint _ma_short_handler, uint _ma_long_handler, double &_loss[], double &_profit[]);
   void            OnDeinit(void);
   void            OnTick(MqlTick &_tick);
   void            OnTick(MqlTick &_tick, int address_part0, int address_part1);
   void            OnTimer(int address_part0);
  };

void Opener::Opener(void)
  {
   buckets_size   = 0;
   session_period = 0;
   tick_count     = 0;
   format_double  = "%04.1f";
  }

void Opener::OnInit(ENUM_TIMEFRAMES _timeframe, int _begin_time, int _finish_time, int _ma_short, int _ma_long, uint _ma_short_handler, uint _ma_long_handler, double &_loss[], double &_profit[])
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

         buckets[buckets_size - 1].SetProperties(GetTestId(__loss, __profit), async);
        }
     }
  }

void Opener::OnDeinit(void)
  {
   int handler_file_stats = FileOpen("stats/" + GetFileName() + ".csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");

   for(int i = 0; i < buckets_size; i++)
     {
      buckets[i].CloseAllPositions(tick);
      // buckets[i].PrintAuditToFile();

      FileWrite(handler_file_stats, buckets[i].GetStats());
     }

   FileClose(handler_file_stats);
  }

void Opener::OnTick(MqlTick &_tick)
  {
   tick = _tick;
   tick_count++;
  }

void Opener::OnTick(MqlTick &_tick, int address_part1, int address_part2)
  {
   buckets[address_part1].OnTick(_tick, address_part2);
  }

void Opener::OnTimer(int address_part0)
  {
   MqlDateTime now;
   TimeTradeServer(now);

   session_period = GetSessionPeriod(begin_time, finish_time);

   if(now.min % (int)timeframe == 0 && session_period == 1 && tick_count > 0)
     {
      int    side  = GetSideFromMA();
      double price = GetPriceFromMASide(side);

      int i = 0;

      for(double __loss = loss[0]; __loss <= loss[1]; __loss += loss[2])
        {
         for(double __profit = profit[0]; __profit <= profit[1]; __profit += profit[2])
           {
            buckets[i].OpenPosition(side, price, __loss, __profit, address_part0, i);
            
            i++;
           }
        }

      tick_count = 0;
     }

   else if(session_period == 3) for(int i = 0; i < buckets_size; i++) buckets[i].CloseAllPositions(tick);
  }

string Opener::GetFileName(void)
  {
   string name;

   StringConcatenate(name, StringFormat(format_double, timeframe), "_",
      StringFormat(format_double, begin_time), "_", StringFormat(format_double, finish_time), "_",
      StringFormat(format_double, ma_short), "_", StringFormat(format_double, ma_long));

   return name;
  }

string Opener::GetTestId(double _loss, double _profit)
  {
   string id;

   StringConcatenate(id, GetFileName(), "_", StringFormat(format_double, _loss), "_", StringFormat(format_double, _profit));

   return id;
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
