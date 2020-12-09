#include <MyLibs\Paibot\Positions.mqh>

namespace Paibot
{
class Main
  {
private:
   ENUM_TIMEFRAMES timeframe;
   int       init_time,
             end_time,
             ma_short,
             ma_long;
   double    loss_first,
             loss_last,
             loss_step,
             profit_first,
             profit_last,
             profit_step;

   Positions positions[];
   int       collection_size,
             session_period,
             tick_count;
   string    format_double;
   uint      handler_ma_short,
             handler_ma_long;

   string    GetFileName(void);
   string    GetTestId(double loss, double profit);
   int       GetSideFromEMA(void);
   double    GetPriceFromEMASide(int side);
public:
             Main(void);
            ~Main(void){};

   void      OnInit(ENUM_TIMEFRAMES _timeframe, int _init_time, int _end_time, int _ma_short, int _ma_long);
   void      OnDeinit(void);
   void      OnTick(void){ tick_count++; };
   void      OnTick(MqlTick &tick, int address_part0, int address_part1);
   void      OnTimer(int address_part0);
  };

void Main::Main(void)
  {
   loss_first     = 5;
   loss_last      = 95;
   loss_step      = 5;

   profit_first   = 5;
   profit_last    = 95;
   profit_step    = 5;

   collection_size = 0;
   session_period = 0;
   tick_count     = 0;
   format_double  = "%04.1f";
  }

void Main::OnInit(ENUM_TIMEFRAMES _timeframe, int _init_time, int _end_time, int _ma_short, int _ma_long)
  {
   timeframe = _timeframe;
   init_time = _init_time;
   end_time  = _end_time;
   ma_short  = _ma_short;
   ma_long   = _ma_long;

   handler_ma_short = iMA(_Symbol, timeframe, ma_short, 0, MODE_EMA, PRICE_CLOSE);
   handler_ma_long  = iMA(_Symbol, timeframe, ma_long,  0, MODE_EMA, PRICE_CLOSE);

   for(double loss = loss_first; loss <= loss_last; loss += loss_step)
     {
      for(double profit = profit_first; profit <= profit_last; profit += profit_step)
        {
         ArrayResize(positions, ++collection_size);

         positions[collection_size - 1].SetId(GetTestId(loss, profit));
         positions[collection_size - 1].SetAsync(async);
        }
     }
  }

void Main::OnDeinit(void)
  {
   int handler_file_stats = FileOpen("stats/" + GetFileName() + ".csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");

   for(int i = 0; i < collection_size; i++)
     {
      positions[i].CloseAll(tick_last);
      // positions[i].PrintAuditToFile();

      FileWrite(handler_file_stats, positions[i].GetStats());
     }

   FileClose(handler_file_stats);
  }

void Main::OnTick(MqlTick &tick, int address_part1, int address_part2)
  {
   positions[address_part1].OnTick(tick, address_part2);
  }

void Main::OnTimer(int address_part0)
  {
   session_period = GetSessionPeriod(init_time, end_time);

   if(now.min % (int)timeframe == 0 && session_period == 1 && tick_count > 0)
     {
      int    _side  = GetSideFromEMA();
      double _price = GetPriceFromEMASide(_side);

      int i = 0;

      for(double loss = loss_first; loss <= loss_last; loss += loss_step)
        {
         for(double profit = profit_first; profit <= profit_last; profit += profit_step)
           {
            positions[i].Open(_side, _price, loss, profit, address_part0, i); i++;
           }
        }

      tick_count = 0;
     }

   else if(session_period == 3) for(int i = 0; i < collection_size; i++) positions[i].CloseAll(tick_last);
  }

string Main::GetFileName(void)
  {
   string name;

   StringConcatenate(name, StringFormat(format_double, timeframe), "_",
      StringFormat(format_double, init_time), "_", StringFormat(format_double, end_time), "_",
      StringFormat(format_double, ma_short), "_", StringFormat(format_double, ma_long));

   return name;
  }

string Main::GetTestId(double loss, double profit)
  {
   string id;

   StringConcatenate(id, GetFileName(), "_", StringFormat(format_double, loss), "_", StringFormat(format_double, profit));

   return id;
  }

int Main::GetSideFromEMA(void)
  {
   double buffer_ma_short[],
          buffer_ma_long[];

   CopyBuffer(handler_ma_short, 0, 0, 2, buffer_ma_short);
   CopyBuffer(handler_ma_long,  0, 0, 2, buffer_ma_long);
   
   return buffer_ma_short[0] - buffer_ma_long[0] < buffer_ma_short[1] - buffer_ma_long[1] ? 1 : -1;
  }

double Main::GetPriceFromEMASide(int side)
  {
   double price = 0;

   if(tick_last.bid < tick_last.ask) price = side == -1 ? tick_last.bid : tick_last.ask;

   return price;
  }
}
