#include <MyLibs\Paibot\PPosition.mqh>

class PPositions
  {
private:
   PPosition positions[];

   int       GetNextPlace(void);
   void      CheckPositionsSize(void);
public:
   uint      count,
             with_loss,
             with_profit,
             opened,
             opened_max;
   double    final_balance;

             PPositions(void);
            ~PPositions(void){};

   bool      Open(int side, double price, double distance_to_loss, double distance_to_profit);
   bool      OnEachTick(MqlTick &tick);
   bool      CloseAll(double price);
  };

PPositions::PPositions(void)
  {
   ArrayResize(positions, 16);

   count         = 0;
   with_loss     = 0;
   with_profit   = 0;
   opened        = 0;
   opened_max    = 0;
   final_balance = 0;
  }

bool PPositions::Open(int side, double price, double distance_to_loss, double distance_to_profit)
  {
   if((side != -1 && side != 1) || price == 0.0) return false;

   int next_place = GetNextPlace();

   if(next_place >= 0)
     {
      if(side == -1) positions[next_place].Open(price, price + distance_to_loss + 0.5, price - distance_to_profit - 0.5);
      if(side ==  1) positions[next_place].Open(price, price - distance_to_loss - 0.5, price + distance_to_profit + 0.5);

      return true;
     }

   return false;
  }

bool PPositions::OnEachTick(MqlTick &tick)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].OnEachTick(tick);

   return true;
  }

bool PPositions::CloseAll(double price)
  {
   for(int i = 0; i < ArraySize(positions); i++) positions[i].ForceToClose(price);

   Print("Positions count: "            + IntegerToString(count));
   Print("Positions with loss: "        + IntegerToString(with_loss));
   Print("Positions with profit: "      + IntegerToString(with_profit));
   Print("Positions opened: "           + IntegerToString(opened));
   Print("Positions opened max: "       + IntegerToString(opened_max));
   Print("Positions final balance: R$ " + DoubleToString(final_balance, 2));

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

   if(opened >= size * 0.9) ArrayResize(positions, size * 2);
  }
