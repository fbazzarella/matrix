namespace Paibot
{
class PositionBucket
  {
private:
   string          id;
   Logger          logger;
   Position        positions[];
   int             positions_size;

   bool            CheckProperties(void);
   int             GetPlaceNext(void);
   void            CheckPositionsSize(void);
   void            SetPositionsSize(int size);
   void            AttachLoggerToPositions(int from, int to);
public:
                   PositionBucket(void);
                  ~PositionBucket(void){};

   void            SetProperties(string _id);
   void            OpenPosition(int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void            CloseAllPositions(MqlTick &tick);
   void            DumpDataCompiled(int handler);
   void            DumpDataRaw(int handler);
  };

void PositionBucket::PositionBucket(void)
  {
   SetPositionsSize(1);
  }

void PositionBucket::SetProperties(string _id)
  {
   logger.SetParentId(id = _id);
  }

void PositionBucket::OpenPosition(int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if(!CheckProperties() || (side != -1 && side != 1) || price_to_open == 0 || (!async && logger.GetValue(OPENED) == 1)) return;

   positions[GetPlaceNext()].Open(side, price_to_open, distance_to_loss, distance_to_profit);

   if(print_data_compiled) logger.PrintDataCompiled();
  }

void PositionBucket::CloseAllPositions(MqlTick &tick)
  {
   if(logger.GetValue(OPENED) == 0) return;

   logger.Increment(OPENED_ABORTED, logger.GetValue(OPENED));

   for(int i = 0; i < positions_size; i++) positions[i].ForceToClose(tick);
  }

void PositionBucket::DumpDataCompiled(int handler)
  {
   logger.DumpDataCompiled(handler);
  }

void PositionBucket::DumpDataRaw(int handler)
  {
   logger.DumpDataRaw(handler);
  }

bool PositionBucket::CheckProperties(void)
  {
   if(id == NULL || id == ""){ Print("ERROR: Bucket id not defined."); return false; };

   return true;
  }

int PositionBucket::GetPlaceNext(void)
  {
   CheckPositionsSize();

   int i = 0; while(positions[i].IsOpened()) i++;

   return i;
  }

void PositionBucket::CheckPositionsSize(void)
  {
   if(async && logger.GetValue(OPENED) == positions_size) SetPositionsSize(positions_size * 2);
  }

void PositionBucket::SetPositionsSize(int size)
  {
   ArrayResize(positions, positions_size = size);

   AttachLoggerToPositions(0, positions_size);
  }

void PositionBucket::AttachLoggerToPositions(int from, int to)
  {
   for(int i = from; i < to; i++) positions[i].AttachLogger(GetPointer(logger));
  }
}
