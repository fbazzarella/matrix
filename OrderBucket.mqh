namespace Paibot
{
class OrderBucket
  {
private:
   Order           orders[];
   int             orders_size;
public:
                   OrderBucket(void);
                  ~OrderBucket(void){};

   void            PlaceOrder(Position *position, int i);
   void            OnTick(MqlTick &tick);
  };

void OrderBucket::OrderBucket(void)
  {
   orders_size = 0;
  }

void OrderBucket::PlaceOrder(Position *position, int i)
  {
   ArrayResize(orders, ++orders_size);

   orders[orders_size - 1].AttachPosition(position, i);
  }

void OrderBucket::OnTick(MqlTick &tick)
  {
   while(orders_size > 0)
     {
      orders[0].OnTick(tick);

      ArrayRemove(orders, 0, 1);

      orders_size--;
     }
  }
}
