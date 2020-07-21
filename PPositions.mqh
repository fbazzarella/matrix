#include <MyLibs\Paibot\PPosition.mqh>

class PPositions
  {
private:
   PPosition positions[10000];
public:
   uint      count,
             with_loss,
             with_profit,
             opened,
             opened_max;
   double    final_balance;

             PPositions(void);
            ~PPositions(void){};

   bool      Open(int side, double price);
   bool      OnEachTick(MqlTick &tick);
   bool      CloseAll(double price);
  };

PPositions::PPositions(void)
  {
   count         = 0;
   with_loss     = 0;
   with_profit   = 0;
   opened        = 0;
   opened_max    = 0;
   final_balance = 0;
  }

bool PPositions::Open(int side, double price)
  {
   if((side != -1 && side != 1) || count >= 10000) return false;

   for(int i = 0; i < ArraySize(positions); i++)
     {
      if(!positions[i].IsOpened())
        {
         if(side == -1) positions[i].Open(price, price + 50.5, price - 1);
         if(side ==  1) positions[i].Open(price, price - 50.5, price + 1);

         return true;
        }
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
   for(int i = 0; i < ArraySize(positions); i++) positions[i].TryToClose(price, true);

   Print("Positions count: "            + IntegerToString(count));
   Print("Positions with loss: "        + IntegerToString(with_loss));
   Print("Positions with profit: "      + IntegerToString(with_profit));
   Print("Positions opened: "           + IntegerToString(opened));
   Print("Positions opened max: "       + IntegerToString(opened_max));
   Print("Positions final balance: R$ " + DoubleToString(final_balance, 2));

   return true;
  }