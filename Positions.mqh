#include <MyLibs\Paibot\Position.mqh>

namespace Paibot
{
class Positions
  {
private:
   Position positions[];
   string   collection_id;
   uint     audit_file_handler;
   double   stats[6]; // 0-count, 1-with_loss, 2-with_profit, 3-opened, 4-opened_max, 5-final_balance

   int      GetNextPlace(void);
   void     CheckCollectionSize(void);
   void     SetCollectionSize(int size);
   void     InitStats(void);
   void     OpenAuditFile(void);
   void     CloseAuditFile(void);
public:       
            Positions(void){ SetCollectionId("sample"); SetCollectionSize(16); InitStats(); OpenAuditFile(); };
           ~Positions(void){ CloseAuditFile(); };

   void     SetCollectionId(string _collection_id);
   bool     Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void     OnEachTick(MqlTick &tick);
   bool     CloseAll(double price_to_close);
   void     PrintStatsToLog(void);
   void     PrintStatsToFile(uint stats_file_handler);
  };

void Positions::SetCollectionId(string _collection_id)
  {
   collection_id = _collection_id;

   StringReplace(collection_id, " ", "_");
  }

bool Positions::Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if((side != -1 && side != 1) || price_to_open == 0.0) return false;

   double price_for_loss   = side == -1 ? price_to_open + distance_to_loss   + 0.5 : price_to_open - distance_to_loss   - 0.5,
          price_for_profit = side == -1 ? price_to_open - distance_to_profit - 0.5 : price_to_open + distance_to_profit + 0.5;

   return positions[GetNextPlace()].Open(collection_id, audit_file_handler, price_to_open, price_for_loss, price_for_profit, stats);
  }

void Positions::OnEachTick(MqlTick &tick)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].OnEachTick(tick, stats);
  }

bool Positions::CloseAll(double price_to_close)
  {
   if(stats[3] == 0) return false;

   for(int i = 0; i < ArraySize(positions); i++) positions[i].ForceToClose(price_to_close, stats);

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

   if(stats[3] >= size * 0.9) SetCollectionSize(size * 2);
  }

void Positions::SetCollectionSize(int size)
  {
   ArrayResize(positions, size);
  }

void Positions::InitStats(void)
  {
   for(int i = 0; i < ArraySize(stats); i++) stats[i] = 0;
  }

void Positions::OpenAuditFile(void)
  {
   audit_file_handler = FileOpen("audit_" + collection_id + ".csv", FILE_READ|FILE_WRITE|FILE_CSV, ";");
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
      Print("| count         " + DoubleToString(stats[0], 0));
      Print("| with loss     " + DoubleToString(stats[1], 0) + " (" + DoubleToString(stats[1] / stats[0] * 100, 1) + "%)");
      Print("| with profit   " + DoubleToString(stats[2], 0) + " (" + DoubleToString(stats[2] / stats[0] * 100, 1) + "%)");
      Print("| opened        " + DoubleToString(stats[3], 0));
      Print("| opened max    " + DoubleToString(stats[4], 0));
      Print("| final balance " + DoubleToString(stats[5], 2) + " BRL");
      Print("");
     }
   else Print("No positions opened for '" + collection_id + "'.");
  }

void Positions::PrintStatsToFile(uint stats_file_handler)
  {
   if(stats[0] > 0)
     {
      string balance = DoubleToString(stats[5], 2);

      StringReplace(balance, ".", ",");

      FileWrite(stats_file_handler, collection_id, stats[0], stats[1], stats[2], stats[3], stats[4], balance);
     }
  }
}
