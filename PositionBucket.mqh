namespace Matrix
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

   void            SetProperties(string _id, int handler_data_raw);
                   template<typename Book>
   void            OpenPosition(Properties &symbol_properties, Book &book, int side, double price_to_open, double distance_to_loss, double distance_to_profit);
   void            CloseAllPositions(MqlTick &tick, int handler_data_compiled);
  };

void PositionBucket::PositionBucket(void)
  {
   SetPositionsSize(1);
  }

void PositionBucket::SetProperties(string _id, int handler_data_raw)
  {
   logger.SetProperties(id = _id, handler_data_raw);
  }

     template<typename Book>
void PositionBucket::OpenPosition(Properties &symbol_properties, Book &book, int side, double price_to_open, double distance_to_loss, double distance_to_profit)
  {
   if(!CheckProperties() || (side != -1 && side != 1) || price_to_open == 0 || (!matrix_global_async && logger.GetValue(OPENED) == 1)) return;

   positions[GetPlaceNext()].Open(symbol_properties, book, side, price_to_open, distance_to_loss, distance_to_profit);
  }

void PositionBucket::CloseAllPositions(MqlTick &tick, int handler_data_compiled)
  {
   if(logger.GetValue(OPENED) == 0) return;

   logger.Increment(OPENED_ABORTED, logger.GetValue(OPENED));

   for(int i = 0; i < positions_size; i++) positions[i].ForceToClose(tick);

   if(matrix_global_dump_data_compiled) logger.DumpDataCompiled(handler_data_compiled);
  }

bool PositionBucket::CheckProperties(void)
  {
   if(id == NULL || id == ""){ Print("ERROR: Bucket id isn't defined."); return false; };

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
   if(matrix_global_async && logger.GetValue(OPENED) == positions_size) SetPositionsSize(positions_size * 2);
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
