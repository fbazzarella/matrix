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
   void            Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part0, int address_part1, int address_part2);
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

void Position::Open(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part0, int address_part1, int address_part2)
  {
   if(IsOpened()) return;

   state = 1;

   time_opened      = TimeTradeServer();
   price_opened     = price_to_open;
   price_for_loss   = price_to_open - (side * distance_to_loss);
   price_for_profit = price_to_open + (side * distance_to_profit);

   logger.Increment(COUNT, 1);
   logger.Increment(OPENED, 1);
   logger.KeepMax(OPENED_MAX, logger.GetValue(OPENED));

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
   if(IsClosed()) return;

   TryToClose(tick, true);
  }

void Position::TryToClose(MqlTick &tick, bool forced = false)
  {
   if(IsClosed()) return;

   string side;
   double price_last   = tick.last,
          price_closed = 0,
          balance      = 0;

   if(price_opened > price_for_profit)
     {
      side = "Sell";

           if(price_last >= price_for_loss || forced)       price_closed = tick.ask;
      else if(price_last <= price_for_profit - symbol_step) price_closed = price_for_profit;

      balance = price_opened - price_closed;
     }

   else if(price_opened < price_for_profit)
     {
      side = "Buy";

           if(price_last <= price_for_loss || forced)       price_closed = tick.bid;
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

   logger.Increment(OPENED, -1);
   logger.Increment(balance < 0 ? WITH_LOSS : WITH_PROFIT, 1);
   logger.AddBalance(balance);
   
   if(print_data_raw) logger.PrintDataRaw(tick, side, price_closed, balance, time_closed, time_opened, price_opened, price_for_loss, price_for_profit);
   if(dump_data_raw)  logger.AddDataRaw(tick, side, price_closed, balance, time_closed, time_opened, price_opened, price_for_loss, price_for_profit);
  }
}
