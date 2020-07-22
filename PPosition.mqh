class PPosition
  {
private:
   uchar  state;

   double price_opened,
          price_for_loss,
          price_for_profit,
          price_higher,
          price_lower;

   bool   Close(double price_closed, double balance, double loss_higher, string side);
   double CalculateFinalValue(double value);
public:
          PPosition(void){ state = 0; };
         ~PPosition(void){};

   bool   Open(double open, double loss, double profit);
   bool   OnEachTick(MqlTick &tick);
   bool   TryToClose(double price, bool forced);

   bool   IsClosed(void){ return state == 0; };
   bool   IsOpened(void){ return state == 1; };
  };

bool PPosition::Open(double open, double loss, double profit)
  {
   if(IsOpened()) return false;

   state = 1;

   price_opened     = open;
   price_for_loss   = loss;
   price_for_profit = profit;
   price_higher     = open;
   price_lower      = open;

   positions.count     += 1;
   positions.opened    += 1;
   positions.opened_max = MathMax(positions.opened, positions.opened_max);

   return true;
  }

bool PPosition::OnEachTick(MqlTick &tick)
  {
   if(IsClosed()) return false;

   price_higher = MathMax(tick.last, price_higher);
   price_lower  = MathMin(tick.last, price_lower);

   TryToClose(tick.last);

   return true;
  }

bool PPosition::TryToClose(double price, bool forced = false)
  {
   if(IsClosed()) return false;

   double price_closed = 0,
          balance      = 0,
          loss_higher  = 0;
   string side;

   if(price_opened > price_for_profit)
     {
      if((forced && price >= price_opened) || price == price_for_loss)
        {
         price_closed = price                - 0.5;
         balance      = price_opened - price + 0.5;
        }

      else if((forced && price < price_opened) || price == price_for_profit)
        {
         price_closed = price                + 0.5;
         balance      = price_opened - price - 0.5;
        }

      loss_higher = price_opened - price_higher + 0.5;
      side        = "Sell";
     }

   else if(price_opened < price_for_profit)
     {
      if((forced && price <= price_opened) || price == price_for_loss)
        {
         price_closed = price                + 0.5;
         balance      = price - price_opened + 0.5;
        }

      else if((forced && price > price_opened) || price == price_for_profit)
        {
         price_closed = price                - 0.5;
         balance      = price - price_opened - 0.5;
        }

      loss_higher = price_lower - price_opened + 0.5;
      side        = "Buy";
     }

   if(price_closed != 0) return Close(price_closed, balance, loss_higher, side);
   
   return false;
  }

bool PPosition::Close(double price_closed, double balance, double loss_higher, string side)
  {
   if(IsClosed()) return false;

   state = 0;

   balance     = CalculateFinalValue(balance);
   loss_higher = MathMin(CalculateFinalValue(loss_higher), -1.7);

   balance < 0 ? positions.with_loss++ : positions.with_profit++;

   positions.opened        -= 1;
   positions.final_balance += balance;

   Print(side + " position opened at " + DoubleToString(price_opened, 1)   +
         " and closed at "             + DoubleToString(price_closed, 1)   +
         " with a balance of R$ "      + DoubleToString(balance,      2)   +
         " and a higher loss of R$ "   + DoubleToString(loss_higher,  2)   +
         ". Total of "                 + IntegerToString(positions.count)  +
         " positions and "             + IntegerToString(positions.opened) +
         " currently opened with a"    +
         " partial balance of R$ "     + DoubleToString(positions.final_balance, 2) );

   return true;
  }

double PPosition::CalculateFinalValue(double value)
  {
   return value * 10 - 1.7;
  }
