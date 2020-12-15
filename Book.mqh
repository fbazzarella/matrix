namespace Paibot
{
class Book
  {
private:
   OrderBucket     buckets[];
   int             buckets_size;
   double          price_base,
                   price_last_prev,
                   tick_size;

   bool            CheckProperties(void);
   int             GetPlace(double price);
   void            CheckBucketsSize(int i);
   void            SetBucketsSize(int size);
public:
                   Book(void);
                  ~Book(void){};

   void            SetProperties(double _price_base, double _tick_size);
   void            PlaceOrders(double price_first, double price_second, Position *position);
   void            OnTick(MqlTick &tick);
   void            Reset(void);
  };

void Book::Book(void)
  {
   SetBucketsSize(0);
  }

void Book::SetProperties(double _price_base, double _tick_size)
  {
   price_base = price_last_prev = _price_base;
   tick_size  = _tick_size;
  }

void Book::PlaceOrders(double price_first, double price_second, Position *position)
  {
   if(!CheckProperties()) return;

   buckets[GetPlace(price_first)].PlaceOrder(position, 0);
   buckets[GetPlace(price_second)].PlaceOrder(position, 1);
  }

void Book::OnTick(MqlTick &tick)
  {
   if(!CheckProperties() || price_last_prev == tick.last || tick.last == 0) return;

   double higher = MathMax(price_last_prev, tick.last),
          lower  = MathMin(price_last_prev, tick.last);

   for(double p = lower; p <= higher; p += tick_size) if(p != price_last_prev) buckets[GetPlace(p)].OnTick(tick);

   price_last_prev = tick.last;
  }

void Book::Reset(void)
  {
   if(!CheckProperties()) return;

   SetBucketsSize(0);
  }

bool Book::CheckProperties(void)
  {
   if(price_base == NULL || tick_size == NULL){ Print("ERROR: Base Price and/or Tick Size not defined."); return false; };

   return true;
  }

int Book::GetPlace(double price)
  {
   int d = (int)(price * 100) - (int)(price_base * 100),
       i = MathAbs(d / (int)(tick_size * 100));
       i = d > 0 ? (i - 1) * 2 : (i * 2) + 1;
   
   CheckBucketsSize(i);

   return i;
  }

void Book::CheckBucketsSize(int i)
  {
   if(i >= buckets_size) SetBucketsSize(++i);
  }

void Book::SetBucketsSize(int size)
  {
   ArrayResize(buckets, buckets_size = size);
  }
}
