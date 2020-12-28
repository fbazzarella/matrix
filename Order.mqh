namespace Matrix
{
class Order
  {
private:
   Position       *position;
   int             counterpart;
   uchar           state;

public:
                   Order(void);
                  ~Order(void){};

   void            AttachPosition(Position *_position, int i);
   bool            IsClosed(void);
   bool            OnTick(MqlTick &tick);
   void            Close(void);
  };

void Order::Order(void)
  {
   state = 1;
  }

void Order::AttachPosition(Position *_position, int i)
  {
   position    = _position;
   counterpart = i == 0 ? 1 : 0;

   position.AttachOrder(GetPointer(this), i);
  }

bool Order::IsClosed(void)
  {
   return state == 0;
  }

bool Order::OnTick(MqlTick &tick)
  {
   if(IsClosed()) return true;

   return position.OnTick(tick, counterpart);
  }

void Order::Close(void)
  {
   state = 0;
  }
}
