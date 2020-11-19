namespace Paibot
{
class Order
  {
private:
   string   address_position;
   int      address_counterpart;
public:
            Order(void){};
           ~Order(void){};

   void     SetAddressPosition(string _address_position){ address_position = _address_position; };
   void     SetAddressCounterpart(int _address_counterpart){ address_counterpart = _address_counterpart; };
   string   GetAddressPosition(void){ return address_position; };
   void     OnTick(MqlTick &tick);
  };

void Order::OnTick(MqlTick &tick)
  {
   string address_parts[];
   
   StringSplit(address_position, StringGetCharacter(".", 0), address_parts);

   positions[(int)address_parts[0]].OnTick(tick, (int)address_parts[1]);

   book.RemoveOrder(address_counterpart, address_position);
  }
}
