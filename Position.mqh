namespace Paibot
{
class Position
  {
private:
   Logger         *logger;
   void           *orders[2];
   uchar           state;
   Properties      symbol;
   datetime        time_opened,
                   time_closed;
   double          price_opened,
                   price_for_loss,
                   price_for_profit;

   void            TryToClose(MqlTick &tick, bool forced);
   void            Close(MqlTick &tick, string side, double price_closed, double balance);
   void            CloseOrders(void);
public:
                   Position(void);
                  ~Position(void){};

   void            AttachLogger(Logger *_logger);
                   template<typename Order>
   void            AttachOrder(Order *order, int i);
   bool            IsOpened(void);
   bool            IsClosed(void);
                   template<typename Book>
   void            Open(Properties &symbol_properties, Book &book, int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void            OnTick(MqlTick &tick);
   void            ForceToClose(MqlTick &tick);
  };

void Position::Position(void)
  {
   state = 0;
  }

void Position::AttachLogger(Logger *_logger)
  {
   logger = _logger;
  }

     template<typename Order>
void Position::AttachOrder(Order *order, int i)
  {
   orders[i] = order;
  }

bool Position::IsOpened(void)
  {
   return state == 1;
  }

bool Position::IsClosed(void)
  {
   return state == 0;
  }

     template<typename Book>
void Position::Open(Properties &symbol_properties, Book &book, int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if(IsOpened()) return;

   state            = 1;
   symbol           = symbol_properties;
   time_opened      = TimeTradeServer();
   price_opened     = price_to_open;
   price_for_loss   = price_to_open - (side * distance_to_loss);
   price_for_profit = price_to_open + (side * distance_to_profit);

   logger.Increment(COUNT, 1);
   logger.Increment(OPENED, 1);
   logger.KeepMax(OPENED_MAX, logger.GetValue(OPENED));

   book.PlaceOrders(price_for_loss, price_for_profit + (side * symbol.tick_size), GetPointer(this));
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

           if(price_last >= price_for_loss || forced)            price_closed = tick.ask;
      else if(price_last <= price_for_profit - symbol.tick_size) price_closed = price_for_profit;

      balance = price_opened - price_closed;
     }

   else if(price_opened < price_for_profit)
     {
      side = "Buy";

           if(price_last <= price_for_loss || forced)            price_closed = tick.bid;
      else if(price_last >= price_for_profit + symbol.tick_size) price_closed = price_for_profit;

      balance = price_closed - price_opened;
     }

   if(price_closed > 0) Close(tick, side, price_closed, balance);
  }

void Position::Close(MqlTick &tick, string side, double price_closed, double balance)
  {
   if(IsClosed()) return;

   CloseOrders();

   state        = 0;
   time_closed  = TimeTradeServer();
   balance     *= symbol.multiplier;
   balance     -= symbol.trade_cost;

   logger.Increment(OPENED, -1);
   logger.Increment(balance < 0 ? WITH_LOSS : WITH_PROFIT, 1);
   logger.AddBalance(balance);
   
   if(print_data_raw) logger.PrintDataRaw(tick, side, price_closed, balance, time_closed, time_opened, price_opened, price_for_loss, price_for_profit);
   if(dump_data_raw)  logger.AddDataRaw(tick, side, price_closed, balance, time_closed, time_opened, price_opened, price_for_loss, price_for_profit);
  }

void Position::CloseOrders(void)
  {
   for(int i = 0; i < ArraySize(orders); i++)
     {
      Order *order = orders[i];
      order.Close();
     }
  }
}
