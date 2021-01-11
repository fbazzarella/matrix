int GetSideFromMA(uint _ma_short_handler, uint _ma_long_handler)
  {
   double ma_short_buffer[],
          ma_long_buffer[];

   CopyBuffer(_ma_short_handler, 0, 0, 2, ma_short_buffer);
   CopyBuffer(_ma_long_handler,  0, 0, 2, ma_long_buffer);
   
   return ma_short_buffer[0] - ma_long_buffer[0] < ma_short_buffer[1] - ma_long_buffer[1] ? 1 : -1;
  }

double GetPriceFromMASide(int side, MqlTick &_tick)
  {
   double price = 0;

   if(_tick.bid < _tick.ask) price = side == -1 ? _tick.bid : _tick.ask;

   return price;
  }
