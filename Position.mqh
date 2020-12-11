namespace Paibot
{
class Position
  {
private:
   Logger         *logger;
   uchar           state;
   double          symbol_factor,
                   symbol_step,
                   symbol_cost;
   datetime        time_opened,
                   time_closed;
   double          price_opened,
                   price_for_loss,
                   price_for_profit;

   void            TryToClose(MqlTick &tick, bool forced);
   void            Close(MqlTick &tick, string side, double price_closed, double balance);
public:
                   Position(void);
                  ~Position(void){};

   void            AttachLogger(Logger *_logger);
   bool            IsOpened(void);
   bool            IsClosed(void);
   void            Open(int side, double price_to_open, double _price_for_loss, double _price_for_profit, int address_part0, int address_part1, int address_part2);
   void            OnTick(MqlTick &tick);
   void            ForceToClose(MqlTick &tick);
  };

void Position::Position(void)
  {
   state = 0;

   symbol_factor = 10;
   symbol_step   = 0.5;
   symbol_cost   = 2.4;
  }

void Position::AttachLogger(Logger *_logger)
  {
   logger = _logger;
  }

bool Position::IsOpened(void)
  {
   return state == 1;
  }

bool Position::IsClosed(void)
  {
   return state == 0;
  }

void Position::Open(int side, double price_to_open, double _price_for_loss, double _price_for_profit, int address_part0, int address_part1, int address_part2)
  {
   if(IsOpened()) return;

   state = 1;

   time_opened      = TimeTradeServer();
   price_opened     = price_to_open;
   price_for_loss   = _price_for_loss;
   price_for_profit = _price_for_profit;

   logger.Increment(0, 1);
   logger.Increment(3, 1);
   logger.KeepMax(4, logger.GetValue(3));

   string address_position = (string)address_part0 + "." + (string)address_part1 + "." + (string)address_part2;

   book.PlaceOrders(address_position, price_for_loss, price_for_profit + (side * symbol_step));
  }

void Position::OnTick(MqlTick &tick)
  {
   if(IsClosed()) return;

   TryToClose(tick);
  }

void Position::ForceToClose(MqlTick &tick)
  {
   TryToClose(tick, true);
  }

void Position::TryToClose(MqlTick &tick, bool forced = false)
  {
   if(IsClosed()) return;

   double price_ask  = tick.ask,
          price_last = tick.last,
          price_bid  = tick.bid;

   string side;
   double price_closed = 0,
          balance      = 0;

   if(price_opened > price_for_profit)
     {
      side = "Sell";

           if(price_last >= price_for_loss || forced)       price_closed = price_ask;
      else if(price_last <= price_for_profit - symbol_step) price_closed = price_for_profit;

      balance = price_opened - price_closed;
     }

   else if(price_opened < price_for_profit)
     {
      side = "Buy";

           if(price_last <= price_for_loss || forced)       price_closed = price_bid;
      else if(price_last >= price_for_profit + symbol_step) price_closed = price_for_profit;

      balance = price_closed - price_opened;
     }

   if(price_closed > 0) Close(tick, side, price_closed, balance);
  }

void Position::Close(MqlTick &tick, string side, double price_closed, double balance)
  {
   if(IsClosed()) return;

   state = 0;

   time_closed  = TimeTradeServer();
   balance     *= symbol_factor;
   balance     -= symbol_cost;

   logger.Increment(3, -1);
   logger.Increment(balance < 0 ? 1 : 2, 1);
   logger.AddBalance(balance);
   
   logger.Audit();
  }
}
