#include <MyLibs\Paibot\PPosition.mqh>

class PPositions
  {
private:
   PPosition positions[];

   double    stats[6];

   int       GetNextPlace(void);
   void      CheckPositionsSize(void);
public:
             PPositions(void);
            ~PPositions(void){};

   bool      Open(int side, double price, double distance_to_loss, double distance_to_profit);
   bool      OnEachTick(MqlTick &tick);
   bool      CloseAll(double price);
  };

PPositions::PPositions(void)
  {
   ArrayResize(positions, 16);

   stats[0] = 0; // count
   stats[1] = 0; // with_loss
   stats[2] = 0; // with_profit
   stats[3] = 0; // opened
   stats[4] = 0; // opened_max
   stats[5] = 0; // final_balance
  }

bool PPositions::Open(int side, double price, double distance_to_loss, double distance_to_profit)
  {
   if((side != -1 && side != 1) || price == 0.0) return false;

   int next_place = GetNextPlace();

   if(next_place >= 0)
     {
      if(side == -1) positions[next_place].Open(price, price + distance_to_loss + 0.5, price - distance_to_profit - 0.5, stats);
      if(side ==  1) positions[next_place].Open(price, price - distance_to_loss - 0.5, price + distance_to_profit + 0.5, stats);

      return true;
     }

   return false;
  }

bool PPositions::OnEachTick(MqlTick &tick)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].OnEachTick(tick, stats);

   return true;
  }

bool PPositions::CloseAll(double price)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].ForceToClose(price, stats);

   Print("Positions");
   Print("| count         " + DoubleToString(stats[0], 0));
   Print("| with loss     " + DoubleToString(stats[1], 0) + " (" + DoubleToString(stats[1] / stats[0] * 100, 1) + "%)");
   Print("| with profit   " + DoubleToString(stats[2], 0) + " (" + DoubleToString(stats[2] / stats[0] * 100, 1) + "%)");
   Print("| opened        " + DoubleToString(stats[3], 0));
   Print("| opened max    " + DoubleToString(stats[4], 0));
   Print("| final balance " + DoubleToString(stats[5], 2) + " BRL");

   return true;
  }

int PPositions::GetNextPlace(void)
  {
   CheckPositionsSize();

   for(int i = 0; i < ArraySize(positions); i++) if(positions[i].IsClosed()) return i;

   return -1;
  }

void PPositions::CheckPositionsSize(void)
  {
   int size = ArraySize(positions);

   if(stats[3] >= size * 0.9) ArrayResize(positions, size * 2);
  }
