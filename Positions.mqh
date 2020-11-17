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
            balance_partial;

   int      GetNextPlace(void);
   void     CheckCollectionSize(void);
   void     SetCollectionSize(int size);
   void     InitStats(void);
public:       
            Positions(void){ SetCollectionSize(1); SetAsync(false); InitStats(); };
           ~Positions(void){};

   void     SetId(string _id){ id = _id; StringReplace(id, " ", "_"); };
   void     SetAsync(bool _async){ async = _async; };
   bool     Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void     OnTick(MqlTick &tick);
   bool     CloseAll(MqlTick &tick);
   void     PrintStatsToLog(void);
   void     DumpAllReports();
  };

bool Positions::Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if(id == NULL || id == ""){ Print("ERROR: Collection id not defined."); return false; };

   if((side != -1 && side != 1) || price_to_open == 0) return false;

   if(!async && stats[3] == 1) return false;

   double price_for_loss   = side == -1 ? price_to_open + distance_to_loss   : price_to_open - distance_to_loss,
          price_for_profit = side == -1 ? price_to_open - distance_to_profit : price_to_open + distance_to_profit;

   return positions[GetNextPlace()].Open(id, price_to_open, price_for_loss, price_for_profit, stats);
  }

void Positions::OnTick(MqlTick &tick)
  {
   for(int i = 0; i < collection_size; i++) positions[i].OnTick(tick, stats, audit, balance_partial);
  }

bool Positions::CloseAll(MqlTick &tick)
  {
   if(stats[3] == 0) return false;

   stats[5] += stats[3]; // opened_aborted

   for(int i = 0; i < collection_size; i++) positions[i].ForceToClose(tick, stats, audit, balance_partial);

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

   balance_partial = "0\t";
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

void Positions::DumpAllReports()
  {
   if(stats[0] == 0) return;

   int    handler_stats = FileOpen("stats/" + id + ".csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t"),
          handler_audit = FileOpen("audit/" + id + ".csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");

   string id_tabulated  = id,
          profit_rate   = DoubleToString(stats[2] / stats[0], 3),
          balance_final = DoubleToString(stats[6], 2);

   StringReplace(id_tabulated,    "_", "\t");
   StringReplace(profit_rate,     ".", ",");
   StringReplace(balance_final,   ".", ",");
   StringReplace(balance_partial, ".", ",");

   FileWrite(handler_stats, "-invalid_row-", id_tabulated, id, stats[0], stats[1], stats[2], profit_rate, stats[4], stats[5], balance_final, balance_partial);

   for(int i = 0; i < ArraySize(audit); i++) FileWrite(handler_audit, audit[i]);

   FileClose(handler_audit);
   FileClose(handler_stats);
  }
}
