namespace Paibot
{
class Position
  {
private:
   uchar    state;
   double   exchange_tax;
   string   collection_id;
   uint     audit_file_handler;
   datetime time_opened,
            time_closed;
   double   price_opened,
            price_for_loss,
            price_for_profit,
            price_higher,
            price_lower;

   bool     TryToClose(double price_to_close, double &stats[], bool forced);
   bool     Close(double price_closed, double balance, double loss_higher, string side, double &stats[]);
   double   CalculateFinalValue(double value);
   void     PrintAuditToLog(double price_closed, double balance, double loss_higher, string side, double &stats[]);
   void     PrintAuditToFile(double price_closed, double balance, double loss_higher, string side);
public:
            Position(void){ state = 0; exchange_tax = 2.28; };
           ~Position(void){};

   bool     Open(string _collection_id, uint _audit_file_handler, double price_to_open,
                 double _price_for_loss, double _price_for_profit, double &stats[]);
   bool     OnEachTick(MqlTick &tick, double &stats[]);
   bool     ForceToClose(double price_to_close, double &stats[]);

   bool     IsClosed(void){ return state == 0; };
   bool     IsOpened(void){ return state == 1; };
  };

bool Position::Open(string _collection_id, uint _audit_file_handler, double price_to_open,
                    double _price_for_loss, double _price_for_profit, double &stats[])
  {
   if(IsOpened()) return false;

   state = 1;

   collection_id      = _collection_id;
   audit_file_handler = _audit_file_handler;

   time_opened      = TimeTradeServer();
   price_opened     = price_to_open;
   price_for_loss   = _price_for_loss;
   price_for_profit = _price_for_profit;
   price_higher     = price_to_open;
   price_lower      = price_to_open;

   stats[0] += 1; // count
   stats[3] += 1; // opened
   stats[4]  = MathMax(stats[3], stats[4]); // opened_max

   return true;
  }

bool Position::OnEachTick(MqlTick &tick, double &stats[])
  {
   if(IsClosed()) return false;

   price_higher = MathMax(tick.last, price_higher);
   price_lower  = MathMin(tick.last, price_lower);

   TryToClose(tick.last, stats);

   return true;
  }

bool Position::ForceToClose(double price_to_close, double &stats[])
  {
   return TryToClose(price_to_close, stats, true);
  }

bool Position::TryToClose(double price_to_close, double &stats[], bool forced = false)
  {
   if(IsClosed()) return false;

   double price_closed = 0,
          balance      = 0,
          loss_higher  = 0;

   string side;

   if(price_opened > price_for_profit)
     {
      if((forced && price_to_close >= price_opened) || price_to_close == price_for_loss)
        {
         price_closed = price_to_close                - 0.5;
         balance      = price_opened - price_to_close + 0.5;
        }

      else if((forced && price_to_close < price_opened) || price_to_close == price_for_profit)
        {
         price_closed = price_to_close                + 0.5;
         balance      = price_opened - price_to_close - 0.5;
        }

      loss_higher = price_opened - price_higher + 0.5;
      side        = "Sell";
     }

   else if(price_opened < price_for_profit)
     {
      if((forced && price_to_close <= price_opened) || price_to_close == price_for_loss)
        {
         price_closed = price_to_close                + 0.5;
         balance      = price_to_close - price_opened + 0.5;
        }

      else if((forced && price_to_close > price_opened) || price_to_close == price_for_profit)
        {
         price_closed = price_to_close                - 0.5;
         balance      = price_to_close - price_opened - 0.5;
        }

      loss_higher = price_lower - price_opened + 0.5;
      side        = "Buy";
     }

   if(price_closed != 0) return Close(price_closed, balance, loss_higher, side, stats);
   
   return false;
  }

bool Position::Close(double price_closed, double balance, double loss_higher, string side, double &stats[])
  {
   if(IsClosed()) return false;

   state = 0;

   time_closed = TimeTradeServer();
   balance     = CalculateFinalValue(balance);
   loss_higher = MathMin(CalculateFinalValue(loss_higher), -exchange_tax);

   balance < 0 ? stats[1]++ : stats[2]++; // with_loss : with_profit

   stats[3] -= 1; // opened
   stats[5] += balance; // final_balance

   PrintAuditToLog(price_closed, balance, loss_higher, side, stats);
   PrintAuditToFile(price_closed, balance, loss_higher, side);

   return true;
  }

double Position::CalculateFinalValue(double value)
  {
   return value * 10 - exchange_tax;
  }

void Position::PrintAuditToLog(double price_closed, double balance, double loss_higher, string side, double &stats[])
  {
   // Print(collection_id + ": " + side +
   //       " position opened at "      + DoubleToString(price_opened, 1) +
   //       " and closed at "           + DoubleToString(price_closed, 1) +
   //       " with a balance of R$ "    + DoubleToString(balance,      2) +
   //       " and a higher loss of R$ " + DoubleToString(loss_higher,  2) +
   //       ". Total of "               + DoubleToString(stats[0],     0) +
   //       " positions and "           + DoubleToString(stats[3],     0) +
   //       " currently opened with a"  +
   //       " partial balance of "      + DoubleToString(stats[5],     2) + " BRL." );

   Print(collection_id + ": Total of " + DoubleToString(stats[0], 0) +
         " positions being "           + DoubleToString(stats[3], 0) +
         " currently opened. "         + DoubleToString(stats[2] / stats[0] * 100, 1) +
         "% with profit and a"         +
         " partial balance of "        + DoubleToString(stats[5],     2) + " BRL." );
  }

void Position::PrintAuditToFile(double price_closed, double balance, double loss_higher, string side)
  {
   uint   time_difference = (uint)(time_closed - time_opened);
   string _price_opened   = DoubleToString(price_opened, 2),
          _price_closed   = DoubleToString(price_closed, 2),
          _balance        = DoubleToString(balance,      2),
          _loss_higher    = DoubleToString(loss_higher,  2);

   StringReplace(_price_opened, ".", ",");
   StringReplace(_price_closed, ".", ",");
   StringReplace(_balance,      ".", ",");
   StringReplace(_loss_higher,  ".", ",");

   FileWrite(audit_file_handler, collection_id, time_opened, time_closed, time_difference,
             side, _price_opened, _price_closed, _balance, _loss_higher);
  }
}
