namespace Paibot
{
class Position
  {
private:
   uchar    state;
   double   symbol_factor,
            symbol_step,
            symbol_cost;
   string   positions_id;
   datetime time_opened,
            time_closed;
   double   price_opened,
            price_for_loss,
            price_for_profit,
            price_higher,
            price_lower;

   void     InitSettings(void);
   bool     TryToClose(MqlTick &tick, double &stats[], string &audit[], string &balance_chain, bool forced);
   bool     Close(MqlTick &tick, string side, double price_closed, double loss_higher, double balance, double &stats[], string &audit[], string &balance_chain);
   double   CalculateFinalValue(double price_difference);
   void     PrintAuditToLog(MqlTick &tick, double price_closed, double balance, double loss_higher, string side, double &stats[]);
   void     DumpAudit(MqlTick &tick, double price_closed, double balance, double loss_higher, string side, double &stats[], string &audit[]);
public:
            Position(void){ InitSettings(); };
           ~Position(void){};

   bool     Open(string _positions_id, int side, double price_to_open, double _price_for_loss, double _price_for_profit, int address_part0, int address_part1, double &stats[]);
   bool     OnTick(MqlTick &tick, double &stats[], string &audit[], string &balance_chain);
   bool     ForceToClose(MqlTick &tick, double &stats[], string &audit[], string &balance_chain);

   bool     IsClosed(void){ return state == 0; };
   bool     IsOpened(void){ return state == 1; };
  };

bool Position::Open(string _positions_id, int side, double price_to_open, double _price_for_loss, double _price_for_profit, int address_part0, int address_part1, double &stats[])
  {
   if(IsOpened()) return false;

   state = 1;

   positions_id     = _positions_id;
   time_opened      = TimeTradeServer();
   price_opened     = price_to_open;
   price_for_loss   = _price_for_loss;
   price_for_profit = _price_for_profit;
   price_higher     = price_to_open;
   price_lower      = price_to_open;

   stats[0] += 1; // count
   stats[3] += 1; // opened
   stats[4]  = MathMax(stats[3], stats[4]); // opened_max

   string address_position = (string)address_part0 + "." + (string)address_part1;

   book.PlaceOrders(address_position, price_for_loss, price_for_profit + (side * symbol_step));

   return true;
  }

bool Position::OnTick(MqlTick &tick, double &stats[], string &audit[], string &balance_chain)
  {
   if(IsClosed()) return false;

   price_higher = MathMax(tick.ask, price_higher);
   price_lower  = MathMin(tick.bid, price_lower);

   TryToClose(tick, stats, audit, balance_chain);

   return true;
  }

bool Position::ForceToClose(MqlTick &tick, double &stats[], string &audit[], string &balance_chain)
  {
   return TryToClose(tick, stats, audit, balance_chain, true);
  }

bool Position::TryToClose(MqlTick &tick, double &stats[], string &audit[], string &balance_chain, bool forced = false)
  {
   if(IsClosed()) return false;

   double price_ask  = tick.ask,
          price_last = tick.last,
          price_bid  = tick.bid;

   string side;
   double price_closed = 0,
          loss_higher  = 0,
          balance      = 0;

   if(price_opened > price_for_profit)
     {
      side = "Sell";

           if(price_last >= price_for_loss || forced)       price_closed = price_ask;
      else if(price_last <= price_for_profit - symbol_step) price_closed = price_for_profit;

      loss_higher = price_opened - price_higher;
      balance     = price_opened - price_closed;
     }

   else if(price_opened < price_for_profit)
     {
      side = "Buy";

           if(price_last <= price_for_loss || forced)       price_closed = price_bid;
      else if(price_last >= price_for_profit + symbol_step) price_closed = price_for_profit;

      loss_higher = price_lower  - price_opened;
      balance     = price_closed - price_opened;
     }

   if(price_closed > 0) return Close(tick, side, price_closed, loss_higher, balance, stats, audit, balance_chain);
   
   return false;
  }

bool Position::Close(MqlTick &tick, string side, double price_closed, double loss_higher, double balance, double &stats[], string &audit[], string &balance_chain)
  {
   if(IsClosed()) return false;

   state = 0;

   time_closed = TimeTradeServer();
   balance     = CalculateFinalValue(balance);
   loss_higher = MathMin(CalculateFinalValue(loss_higher), -symbol_cost);

   balance < 0 ? stats[1]++ : stats[2]++; // with_loss : with_profit

   stats[3] -= 1; // opened
   stats[6] += balance; // final_balance
   
   StringConcatenate(balance_chain, balance_chain, (string)stats[6] + "\t");

   // PrintAuditToLog(tick, price_closed, balance, loss_higher, side, stats);
   DumpAudit(tick, price_closed, balance, loss_higher, side, stats, audit);

   return true;
  }

void Position::InitSettings(void)
  {
   state = 0;

   symbol_factor = 10;
   symbol_step   = 0.5;
   symbol_cost   = 2.4;
  }

double Position::CalculateFinalValue(double price_difference)
  {
   return price_difference * symbol_factor - symbol_cost;
  }

void Position::PrintAuditToLog(MqlTick &tick, double price_closed, double balance, double loss_higher, string side, double &stats[])
  {
   Print(positions_id + ": " + side +
         " position opened at "      + DoubleToString(price_opened, 1) +
         " and closed at "           + DoubleToString(price_closed, 1) +
         " with a balance of R$ "    + DoubleToString(balance,      2) +
         " and a higher loss of R$ " + DoubleToString(loss_higher,  2) +
         ". Total of "               + DoubleToString(stats[0],     0) +
         " positions and "           + DoubleToString(stats[3],     0) +
         " currently opened with a"  +
         " partial balance of "      + DoubleToString(stats[6],     2) + " BRL." );
  }

void Position::DumpAudit(MqlTick &tick, double price_closed, double balance, double loss_higher, string side, double &stats[], string &audit[])
  {
   int    size      = ArraySize(audit);
   uint   time_diff = (uint)(time_closed - time_opened);
   string prices,
          audit_chain;

   StringConcatenate(prices, price_for_loss, "\t", price_opened, "\t", price_for_profit, "\t", price_closed, "\t",
      tick.bid, "\t", tick.last, "\t", tick.ask, "\t", balance, "\t", stats[6], "\t", loss_higher);

   StringReplace(prices, ".", ",");

   StringConcatenate(audit_chain, "invalid", "\t", time_opened, "\t",
      time_closed, "\t", time_diff, "\t", side, "\t", prices);

   ArrayResize(audit, size + 1);
   
   audit[size] = audit_chain;
  }
}
