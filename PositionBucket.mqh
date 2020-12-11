#include <MyLibs\Paibot\Position.mqh>

namespace Paibot
{
class PositionBucket
  {
private:
   Position        positions[];
   int             positions_size;
   string          id;
   bool            async;
   double          stats[7]; // 0-count, 1-with_loss, 2-with_profit, 3-opened, 4-opened_max, 5-opened_aborted, 6-balance_final
   string          audit[],
                   balance_chain;

   int             GetNextPlace(void);
   void            CheckPositionsSize(void);
   void            SetPositionsSize(int size);
public:
                   PositionBucket(void);
                  ~PositionBucket(void){};

   void            SetProperties(string _id, bool _async);
   bool            OpenPosition(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part0, int address_part1);
   void            OnTick(MqlTick &tick, int address_part2);
   bool            CloseAllPositions(MqlTick &tick);
   string          GetStats(void);
   void            PrintAuditToFile(void);
   void            PrintStatsToLog(void);
  };

void PositionBucket::PositionBucket(void)
  {
   SetPositionsSize(1);

   for(int i = 0; i < ArraySize(stats); i++) stats[i] = 0;

   balance_chain = "0\t";
  }

void PositionBucket::SetProperties(string _id, bool _async)
  {
   id    = _id;
   async = _async;
  }

bool PositionBucket::OpenPosition(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part0, int address_part1)
  {
   if(id == NULL || id == ""){ Print("ERROR: Bucket id not defined."); return false; };

   if((side != -1 && side != 1) || price_to_open == 0) return false;

   if(!async && stats[3] == 1) return false;

   int next_place = GetNextPlace();

   double price_for_loss   = side == -1 ? price_to_open + distance_to_loss   : price_to_open - distance_to_loss,
          price_for_profit = side == -1 ? price_to_open - distance_to_profit : price_to_open + distance_to_profit;

   return positions[next_place].Open(id, side, price_to_open, price_for_loss, price_for_profit, address_part0, address_part1, next_place, stats);
  }

void PositionBucket::OnTick(MqlTick &tick, int address_part2)
  {
   for(int i = 0; i < positions_size; i++) positions[address_part2].OnTick(tick, stats, audit, balance_chain);
  }

bool PositionBucket::CloseAllPositions(MqlTick &tick)
  {
   if(stats[3] == 0) return false;

   stats[5] += stats[3]; // opened_aborted

   for(int i = 0; i < positions_size; i++) positions[i].ForceToClose(tick, stats, audit, balance_chain);

   return true;
  }

int PositionBucket::GetNextPlace(void)
  {
   CheckPositionsSize();

   int i = 0; while(positions[i].IsOpened()) i++;

   return i;
  }

void PositionBucket::CheckPositionsSize(void)
  {
   if(async && stats[3] == positions_size) SetPositionsSize(positions_size * 2);
  }

void PositionBucket::SetPositionsSize(int size)
  {
   ArrayResize(positions, positions_size = size);
  }

string PositionBucket::GetStats(void)
  {
   string id_tabulated = id,
          profit_rate  = "0",
          prices,
          stats_chain;

   StringReplace(id_tabulated, "_", "\t");

   if(stats[0] > 0) profit_rate = DoubleToString(stats[2] / stats[0], 3);

   StringConcatenate(prices, profit_rate, "\t",
      DoubleToString(stats[6], 2), "\t", balance_chain);

   StringReplace(prices, ".", ",");

   StringConcatenate(stats_chain, "invalid", "\t", id_tabulated, "\t", id, "\t",
      DoubleToString(stats[0], 0), "\t", DoubleToString(stats[1], 0), "\t",
      DoubleToString(stats[2], 0), "\t", DoubleToString(stats[4], 0), "\t",
      DoubleToString(stats[5], 0), "\t", prices);

   return stats_chain;
  }

void PositionBucket::PrintAuditToFile(void)
  {
   int handler_file_audit = FileOpen("audit/" + id + ".csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");

   FileWrite(handler_file_audit, "invalid", "Time Opened", "Time Closed", "Time Diff", "Side", "Price for Loss",
      "Price Opened", "Price for Profit", "Price Closed", "Bid", "Last", "Ask", "Balance", "Final Balance", "Higher Loss (!)");

   for(int i = 0; i < ArraySize(audit); i++) FileWrite(handler_file_audit, audit[i]);

   FileClose(handler_file_audit);
  }

void PositionBucket::PrintStatsToLog(void)
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
