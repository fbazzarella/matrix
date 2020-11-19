#include <MyLibs\Paibot\Order.mqh>

namespace Paibot
{
class BookPlace
  {
private:
   Order    orders[];
public:
            BookPlace(void){};
           ~BookPlace(void){};

   void     PlaceOrder(string address_position, int address_counterpart);
   void     OnTick(MqlTick &tick);
   void     RemoveOrder(string address_position);
  };

void BookPlace::PlaceOrder(string address_position, int address_counterpart)
  {
   int size = ArraySize(orders);

   ArrayResize(orders, size + 1);

   orders[size].SetAddressPosition(address_position);
   orders[size].SetAddressCounterpart(address_counterpart);
  }

void BookPlace::OnTick(MqlTick &tick)
  {
   while(ArraySize(orders) > 0)
     {
      orders[0].OnTick(tick);

      ArrayRemove(orders, 0, 1);
     }
  }

void BookPlace::RemoveOrder(string address_position)
  {
   for(int i = 0; i < ArraySize(orders); i++)
     {
      if(orders[i].GetAddressPosition() == address_position){ ArrayRemove(orders, i, 1); break; }
     }
  }
}
