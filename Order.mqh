namespace Paibot
{
class Order
  {
private:
   string          address_position;
   int             address_counterpart;
public:
                   Order(void){};
                  ~Order(void){};

   void            SetProperties(string _address_position, int _address_counterpart);
   string          GetAddressPosition(void);
   void            OnTick(MqlTick &tick);
  };

void Order::SetProperties(string _address_position, int _address_counterpart)
  {
   address_position    = _address_position;
   address_counterpart = _address_counterpart;
  }

string Order::GetAddressPosition(void)
  {
   return address_position;
  }

void Order::OnTick(MqlTick &tick)
  {
   string address_parts[];
   
   StringSplit(address_position, StringGetCharacter(".", 0), address_parts);

   openers[(int)address_parts[0]].OnTick(tick, (int)address_parts[1], (int)address_parts[2]);
   
   book.RemoveOrder(address_counterpart, address_position);
  }
}
