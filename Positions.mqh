#include <MyLibs\Paibot\Position.mqh>

namespace Paibot
{
class Positions
  {
private:
   Position positions[];
   int      collection_size;
   string   id;
   bool     async;
   double   stats[7]; // 0-count, 1-with_loss, 2-with_profit, 3-opened, 4-opened_max, 5-opened_aborted, 6-balance_final
   string   audit[],
            balance_chain;

   int      GetNextPlace(void);
   void     CheckCollectionSize(void);
   void     SetCollectionSize(int size);
   void     InitStats(void);
public:       
            Positions(void){ SetCollectionSize(1); SetAsync(false); InitStats(); };
           ~Positions(void){};

   void     SetId(string _id){ id = _id; StringReplace(id, " ", "_"); };
   void     SetAsync(bool _async){ async = _async; };
   bool     Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part1);
   void     OnTick(MqlTick &tick, int address_part2);
   bool     CloseAll(MqlTick &tick);
   string   GetStats(void);
   void     PrintStatsToLog(void);
  };

bool Positions::Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part1)
  {
   if(id == NULL || id == ""){ Print("ERROR: Collection id not defined."); return false; };

   if((side != -1 && side != 1) || price_to_open == 0) return false;

   if(!async && stats[3] == 1) return false;

   int next_place = GetNextPlace();

   double price_for_loss   = side == -1 ? price_to_open + distance_to_loss   : price_to_open - distance_to_loss,
          price_for_profit = side == -1 ? price_to_open - distance_to_profit : price_to_open + distance_to_profit;

   return positions[next_place].Open(id, side, price_to_open, price_for_loss, price_for_profit, address_part1, next_place, stats);
  }

void Positions::OnTick(MqlTick &tick, int address_part2)
  {
   for(int i = 0; i < collection_size; i++) positions[address_part2].OnTick(tick, stats, audit, balance_chain);
  }

bool Positions::CloseAll(MqlTick &tick)
  {
   if(stats[3] == 0) return false;

   stats[5] += stats[3]; // opened_aborted

   for(int i = 0; i < collection_size; i++) positions[i].ForceToClose(tick, stats, audit, balance_chain);

   return true;
  }

int Positions::GetNextPlace(void)
  {
   CheckCollectionSize();

   int i = 0; while(positions[i].IsOpened()) i++;

   return i;
  }

void Positions::CheckCollectionSize(void)
  {
   int size = collection_size;

   if(async && stats[3] == size) SetCollectionSize(size * 2);
  }

void Positions::SetCollectionSize(int size)
  {
   ArrayResize(positions, collection_size = size);
  }

void Positions::InitStats(void)
  {
   for(int i = 0; i < ArraySize(stats); i++) stats[i] = 0;

   balance_chain = "0\t";
  }

string Positions::GetStats(void)
  {
   string id_tabulated  = id,
          profit_rate   = DoubleToString(stats[2] / stats[0], 3),
          balance_final = DoubleToString(stats[6], 2),
          stats_chain   = "invalid";

   StringReplace(id_tabulated,  "_", "\t");
   StringReplace(profit_rate,   ".", ",");
   StringReplace(balance_final, ".", ",");
   StringReplace(balance_chain, ".", ",");

   StringConcatenate(stats_chain, stats_chain, "\t", id_tabulated, "\t", id, "\t",
      DoubleToString(stats[0], 0), "\t", DoubleToString(stats[1], 0), "\t",
      DoubleToString(stats[2], 0), "\t", profit_rate, "\t", DoubleToString(stats[4], 0), "\t",
      DoubleToString(stats[5], 0), "\t", balance_final, "\t", balance_chain);

   return stats_chain;
  }

void Positions::PrintStatsToLog(void)
  {
   if(stats[0] > 0)
     {
      Print("Position stats for '" + id + "':");
      Print("| count          " + DoubleToString(stats[0], 0));
      Print("| with loss      " + DoubleToString(stats[1], 0) + " (" + DoubleToString(stats[1] / stats[0] * 100, 1) + "%)");
      Print("| with profit    " + DoubleToString(stats[2], 0) + " (" + DoubleToString(stats[2] / stats[0] * 100, 1) + "%)");
      Print("| opened         " + DoubleToString(stats[3], 0));
      Print("| opened max     " + DoubleToString(stats[4], 0));
      Print("| opened aborted " + DoubleToString(stats[5], 0));
      Print("| final balance  " + DoubleToString(stats[6], 2) + " BRL");
      Print("");
      Print("");
      Print("");
      Print("");
     }
   
   else
     {
      Print("No positions opened for '" + id + "'.");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
      Print("");
     }
  }
}
