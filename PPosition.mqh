class PPosition
  {
protected:
   uchar   state;

   double  price_opened,
           price_for_loss,
           price_for_profit;

   bool    Close(double price_closed, double balance);
public:
           PPosition(void) { state = 0; };
          ~PPosition(void) {};

   bool    Open(double open, double loss, double profit);
   bool    OnEachTick(MqlTick &tick);
   bool    TryToClose(double last, bool forced);

   bool    IsNotOpened(void) { return state == 0; };
   bool    IsOpened(void)    { return state == 1; };
   bool    IsClosed(void)    { return state == 2; };
  };

bool PPosition::Open(double open, double loss, double profit)
  {
   if(IsOpened()) return false;

   state = 1;

   price_opened     = open;
   price_for_loss   = loss;
   price_for_profit = profit;

   positions_opened    += 1;
   positions_opened_max = MathMax(positions_opened_max, positions_opened);

   return true;
  }

bool PPosition::OnEachTick(MqlTick &tick)
  {
   if(IsNotOpened() || IsClosed()) return false;

   TryToClose(tick.last);

   return true;
  }

bool PPosition::TryToClose(double last, bool forced = false)
  {
   if(IsNotOpened() || IsClosed()) return false;

   double price_closed = 0,
          balance      = 0;

   if(price_opened > price_for_profit)
     {
      if(forced || last == price_for_loss)
        {
         price_closed = last                - 0.5;
         balance      = price_opened - last + 0.5;
        }

      if(forced || last == price_for_profit)
        {
         price_closed = last                + 0.5;
         balance      = price_opened - last - 0.5;
        }
     }

   if(price_opened < price_for_profit)
     {
      if(forced || last == price_for_loss)
        {
         price_closed = last                + 0.5;
         balance      = last - price_opened + 0.5;
        }

      if(forced || last == price_for_profit)
        {
         price_closed = last                - 0.5;
         balance      = last - price_opened - 0.5;
        }
     }

   if(balance != 0) return Close(price_closed, balance);
   
   return false;
  }

bool PPosition::Close(double price_closed, double balance)
  {
   state = 2;

   balance < 0 ? positions_with_loss++ : positions_with_profit++;

   positions_count         += 1;
   positions_opened        -= 1;
   positions_final_balance += balance = (balance * 10) - 1.7;

   Print("Position opened at "      + DoubleToString(price_opened, 1)   +
         " and closed at "          + DoubleToString(price_closed, 1)   +
         " with a balance of R$ "   + DoubleToString(balance,      2)   + 
         ". Total of "              + IntegerToString(positions_count)  +
         " positions and "          + IntegerToString(positions_opened) +
         " currently opened with a" +
         " partial balance of R$ "  + DoubleToString(positions_final_balance, 2) );

   return true;
  }
