namespace Paibot
{
class Order
  {
private:
   Position       *position;
   uchar           state;

   bool            IsClosed(void);
public:
                   Order(void);
                  ~Order(void){};

   void            AttachPosition(Position *_position, int i);
   void            OnTick(MqlTick &tick);
   void            Close(void);
  };

void Order::Order(void)
  {
   state = 1;
  }

void Order::AttachPosition(Position *_position, int i)
  {
   position = _position;

   position.AttachOrder(GetPointer(this), i);
  }

void Order::OnTick(MqlTick &tick)
  {
   if(IsClosed()) return;

   position.OnTick(tick);
  }

void Order::Close(void)
  {
   state = 0;
  }

bool Order::IsClosed(void)
  {
   return state == 0;
  }
}
