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

   void            PlaceOrder(string address_position, int address_counterpart);
   void            OnTick(MqlTick &tick);
   void            RemoveOrder(string address_position);
  };

void OrderBucket::OrderBucket(void)
  {
   orders_size = 0;
  }

void OrderBucket::PlaceOrder(string address_position, int address_counterpart)
  {
   ArrayResize(orders, ++orders_size);

   orders[orders_size - 1].SetProperties(address_position, address_counterpart);
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

void OrderBucket::RemoveOrder(string address_position)
  {
   for(int i = 0; i < orders_size; i++)
     {
      if(orders[i].GetAddressPosition() == address_position)
        {
         ArrayRemove(orders, i, 1);

         orders_size--;
         
         break;
        }
     }
  }
}
