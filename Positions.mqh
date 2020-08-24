#include <MyLibs\Paibot\Position.mqh>

namespace Paibot
{
class Positions
  {
private:
   string   collection_id;

   Position positions[];
   double   stats[6]; // 0-count, 1-with_loss, 2-with_profit, 3-opened, 4-opened_max, 5-final_balance

   int      GetNextPlace(void);
   void     SetPositionsSize(void);
   void     SetStats(void);
public:       
            Positions(string id) : collection_id(id) { SetPositionsSize(); SetStats(); };
           ~Positions(void){};

   bool     Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void     OnEachTick(MqlTick &tick);
   bool     CloseAll(double price_to_close);
   void     PrintStatsToLog(void);
   void     PrintStatsToFile(uint handler);
  };

bool Positions::Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if((side != -1 && side != 1) || price_to_open == 0.0) return false;

   int next_place = GetNextPlace();

   if(next_place >= 0)
     {
      double price_for_loss   = side == -1 ? price_to_open + distance_to_loss   + 0.5 : price_to_open - distance_to_loss   - 0.5,
             price_for_profit = side == -1 ? price_to_open - distance_to_profit - 0.5 : price_to_open + distance_to_profit + 0.5;

      return positions[next_place].Open(collection_id, price_to_open, price_for_loss, price_for_profit, stats);
     }

   return false;
  }

void Positions::OnEachTick(MqlTick &tick)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].OnEachTick(tick, stats);
  }

bool Positions::CloseAll(double price_to_close)
  {
   int opened = (int)stats[3];

   for(int i = 0; i < ArraySize(positions); i++) positions[i].ForceToClose(price_to_close, stats);

   if(opened > 0) return true;

   return false;
  }

int Positions::GetNextPlace(void)
  {
   SetPositionsSize();

   for(int i = 0; i < ArraySize(positions); i++) if(positions[i].IsClosed()) return i;

   return -1;
  }

void Positions::SetPositionsSize(void)
  {
   int size = ArraySize(positions);

   if(size > 0)
     {
      if(stats[3] >= size * 0.9) ArrayResize(positions, size * 2);
     }
   else
     {
      ArrayResize(positions, 16);
     }
  }

void Positions::SetStats(void)
  {
   for(int i = 0; i < ArraySize(stats); i++) stats[i] = 0;
  }

void Positions::PrintStatsToLog(void)
  {
   if(stats[0] > 0)
     {
      Print("Position stats for '" + collection_id + "':");
      Print("| count         " + DoubleToString(stats[0], 0));
      Print("| with loss     " + DoubleToString(stats[1], 0) + " (" + DoubleToString(stats[1] / stats[0] * 100, 1) + "%)");
      Print("| with profit   " + DoubleToString(stats[2], 0) + " (" + DoubleToString(stats[2] / stats[0] * 100, 1) + "%)");
      Print("| opened        " + DoubleToString(stats[3], 0));
      Print("| opened max    " + DoubleToString(stats[4], 0));
      Print("| final balance " + DoubleToString(stats[5], 2) + " BRL");
      Print("");
     }
   else
     {
      Print("No positions opened for '" + collection_id + "'.");
     }
  }

void Positions::PrintStatsToFile(uint handler)
  {
   if(stats[0] > 0)
     {
      string balance = DoubleToString(stats[5], 2);

      StringReplace(balance, ".", ",");

      FileWrite(handler, collection_id, stats[0], stats[1], stats[2], stats[3], stats[4], balance);
     }
  }
}
