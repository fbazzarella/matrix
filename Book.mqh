#include <MyLibs\Paibot\BookPlace.mqh>

namespace Paibot
{
class Book
  {
private:
   BookPlace book_places[];
   int       collection_size;
   double    price_base,
             price_last,
             tick_size;

   int       GetPlace(double price);
   void      CheckCollectionSize(int i);
   void      SetCollectionSize(int size);
public:
             Book(void){ SetCollectionSize(0); };
            ~Book(void){};

   void      ResetBook(void){ SetCollectionSize(0); };
   void      SetPriceBase(double price){ price_base = price_last = price; };
   void      SetTickSize(double size){ tick_size = size; };
   void      PlaceOrders(string address_position, double price_first, double price_second);
   void      RemoveOrder(int address_counterpart, string address_position);
   void      OnTick(MqlTick &tick);
  };

void Book::PlaceOrders(string address_position, double price_first, double price_second)
  {
   int place_first  = GetPlace(price_first),
       place_second = GetPlace(price_second);

   book_places[place_first].PlaceOrder(address_position, place_second);
   book_places[place_second].PlaceOrder(address_position, place_first);
  }

void Book::RemoveOrder(int address_counterpart, string address_position)
  {
   book_places[address_counterpart].RemoveOrder(address_position);
  }

void Book::OnTick(MqlTick &tick)
  {
   if(price_base == NULL || tick_size == NULL){ Print("ERROR: Base Price and/or Symbol Step not defined."); return; };

   if(price_last == tick.last || tick.last == 0) return;

   double higher = MathMax(price_last, tick.last),
          lower  = MathMin(price_last, tick.last);

   for(double p = lower; p <= higher; p += tick_size) if(p != price_last) book_places[GetPlace(p)].OnTick(tick);

   price_last = tick.last;
  }

int Book::GetPlace(double price)
  {
   int d = (int)(price * 100) - (int)(price_base * 100),
       i = MathAbs(d / (int)(tick_size * 100));
       i = d > 0 ? (i - 1) * 2 : (i * 2) + 1;
   
   CheckCollectionSize(i);

   return i;
  }

void Book::CheckCollectionSize(int i)
  {
   if(i >= collection_size) SetCollectionSize(++i);
  }

void Book::SetCollectionSize(int size)
  {
   ArrayResize(book_places, collection_size = size);
  }
}
