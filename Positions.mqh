#include <MyLibs\Paibot\Position.mqh>

namespace Paibot
{
class Positions
  {
private:
   Position positions[];
   string   collection_id;
   bool     collection_async;
   int      audit_file_handler;
   double   stats[7]; // 0-count, 1-with_loss, 2-with_profit, 3-opened, 4-opened_max, 5-opened_aborted, 6-final_balance
   string   partial_balances;

   int      GetNextPlace(void);
   void     CheckCollectionSize(void);
   void     SetCollectionSize(int size);
   void     InitStats(void);
   void     OpenAuditFile(void);
   void     CloseAuditFile(void);
public:       
            Positions(void){ SetCollectionSize(1); SetCollectionAsync(false); InitStats(); };
           ~Positions(void){ CloseAuditFile(); };

   void     SetCollectionId(string _collection_id);
   void     SetCollectionAsync(bool _collection_async);
   bool     Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void     OnTick(MqlTick &tick);
   bool     CloseAll(MqlTick &tick);
   void     PrintStatsToLog(void);
   void     PrintStatsToFile(uint stats_file_handler);
  };

void Positions::SetCollectionId(string _collection_id)
  {
   collection_id = _collection_id;

   StringReplace(collection_id, " ", "_");

   OpenAuditFile();
  }

void Positions::SetCollectionAsync(bool _collection_async)
  {
   collection_async = _collection_async;
  }

bool Positions::Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if(collection_id == NULL || collection_id == ""){ Print("ERROR: Collection id not defined."); return false; };

   if((side != -1 && side != 1) || price_to_open == 0) return false;

   if(!collection_async && stats[3] == 1) return false;

   double price_for_loss   = side == -1 ? price_to_open + distance_to_loss   : price_to_open - distance_to_loss,
          price_for_profit = side == -1 ? price_to_open - distance_to_profit : price_to_open + distance_to_profit;

   return positions[GetNextPlace()].Open(collection_id, audit_file_handler, price_to_open, price_for_loss, price_for_profit, stats);
  }

void Positions::OnTick(MqlTick &tick)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].OnTick(tick, stats, partial_balances);
  }

bool Positions::CloseAll(MqlTick &tick)
  {
   if(stats[3] == 0) return false;

   stats[5] += stats[3]; // opened_aborted

   for(int i = 0; i < ArraySize(positions); i++) positions[i].ForceToClose(tick, stats, partial_balances);

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
   int size = ArraySize(positions);

   if(collection_async && stats[3] == size) SetCollectionSize(size * 2);
  }

void Positions::SetCollectionSize(int size)
  {
   ArrayResize(positions, size);
  }

void Positions::InitStats(void)
  {
   for(int i = 0; i < ArraySize(stats); i++) stats[i] = 0;

   partial_balances = "0\t";
  }

void Positions::OpenAuditFile(void)
  {
   audit_file_handler = FileOpen("audit/" + collection_id + "_audit.csv", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, "\t");
   FileSeek(audit_file_handler, 0, SEEK_END);
  }

void Positions::CloseAuditFile(void)
  {
   FileClose(audit_file_handler);
  }

void Positions::PrintStatsToLog(void)
  {
   if(stats[0] > 0)
     {
      Print("Position stats for '" + collection_id + "':");
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
      Print("No positions opened for '" + collection_id + "'.");
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

void Positions::PrintStatsToFile(uint stats_file_handler)
  {
   if(stats[0] > 0)
     {
      string profit_rate   = DoubleToString(stats[2] / stats[0], 3);
      string final_balance = DoubleToString(stats[6], 2);

      StringReplace(profit_rate,      ".", ",");
      StringReplace(final_balance,    ".", ",");
      StringReplace(partial_balances, ".", ",");

      FileWrite(stats_file_handler, collection_id, stats[0], stats[1], stats[2], profit_rate, stats[4], stats[5], final_balance, partial_balances);
     }
  }
}
