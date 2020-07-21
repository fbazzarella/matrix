class PPosition
  {
private:
   uchar  state;

   double price_opened,
          price_for_loss,
          price_for_profit,
          price_top,
          price_bottom,
          maximum_loss;

   bool   Close(double price_closed, double balance);
public:
          PPosition(void){ state = 0; };
         ~PPosition(void){};

   bool   Open(double open, double loss, double profit);
   bool   OnEachTick(MqlTick &tick);
   bool   TryToClose(double price, bool forced);

   bool   IsNotOpened(void){ return state == 0; };
   bool   IsOpened(void)   { return state == 1; };
   bool   IsClosed(void)   { return state == 2; };
  };

bool PPosition::Open(double open, double loss, double profit)
  {
   if(IsOpened()) return false;

   state = 1;

   price_opened     = open;
   price_for_loss   = loss;
   price_for_profit = profit;
   price_top        = 0;
   price_bottom     = 0;
   maximum_loss     = 0;

   positions.count     += 1;
   positions.opened    += 1;
   positions.opened_max = MathMax(positions.opened, positions.opened_max);

   return true;
  }

bool PPosition::OnEachTick(MqlTick &tick)
  {
   if(IsNotOpened() || IsClosed()) return false;

   double price_difference = tick.last - price_opened;

   price_top    = MathMax(price_difference, price_top);
   price_bottom = MathMin(price_difference, price_bottom);

   TryToClose(tick.last);

   return true;
  }

bool PPosition::TryToClose(double price, bool forced = false)
  {
   if(IsNotOpened() || IsClosed()) return false;

   double price_closed   = 0,
          balance        = 0;

   if(price_opened > price_for_profit)
     {
      maximum_loss = -price_top;

      if(forced || price == price_for_loss)
        {
         price_closed = price                - 0.5;
         balance      = price_opened - price + 0.5;
        }

      if(forced || price == price_for_profit)
        {
         price_closed = price                + 0.5;
         balance      = price_opened - price - 0.5;
        }
     }

   if(price_opened < price_for_profit)
     {
      maximum_loss = price_bottom;

      if(forced || price == price_for_loss)
        {
         price_closed = price                + 0.5;
         balance      = price - price_opened + 0.5;
        }

      if(forced || price == price_for_profit)
        {
         price_closed = price                - 0.5;
         balance      = price - price_opened - 0.5;
        }
     }

   if(balance != 0) return Close(price_closed, balance);
   
   return false;
  }

bool PPosition::Close(double price_closed, double balance)
  {
   state = 2;

   balance < 0 ? positions.with_loss++ : positions.with_profit++;

   balance      = ticks_to_money(balance);
   maximum_loss = MathMin(ticks_to_money(maximum_loss), balance);

   positions.opened        -= 1;
   positions.final_balance += balance;

   Print("Position opened at "      + DoubleToString(price_opened, 1)   +
         " and closed at "          + DoubleToString(price_closed, 1)   +
         " with a balance of R$ "   + DoubleToString(balance,      2)   + 
         " and a max loss of R$ "   + DoubleToString(maximum_loss, 2)   + 
         ". Total of "              + IntegerToString(positions.count)  +
         " positions and "          + IntegerToString(positions.opened) +
         " currently opened with a" +
         " partial balance of R$ "  + DoubleToString(positions.final_balance, 2) );

   return true;
  }
