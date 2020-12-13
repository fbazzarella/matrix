#include <MyLibs\Paibot\Logger.mqh>
#include <MyLibs\Paibot\Position.mqh>

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
   int             GetNextPlace(void);
   void            CheckPositionsSize(void);
   void            SetPositionsSize(int size);
   void            AttachLoggerToPositions(int from, int to);
public:
                   PositionBucket(void);
                  ~PositionBucket(void){};

   void            SetProperties(string _id);
   void            OpenPosition(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part0, int address_part1);
   void            OnTick(MqlTick &tick, int address_part2);
   void            CloseAllPositions(MqlTick &tick);
  };

void PositionBucket::PositionBucket(void)
  {
   SetPositionsSize(1);
  }

void PositionBucket::SetProperties(string _id)
  {
   logger.SetParentId(id = _id);
  }

void PositionBucket::OpenPosition(int side, double price_to_open, double distance_to_loss, double distance_to_profit, int address_part0, int address_part1)
  {
   if(!CheckProperties() || (side != -1 && side != 1) || price_to_open == 0 || (!async && logger.GetValue(OPENED) == 1)) return;

   int next_place = GetNextPlace();

   positions[next_place].Open(side, price_to_open, distance_to_loss, distance_to_profit, address_part0, address_part1, next_place);
  }

void PositionBucket::OnTick(MqlTick &tick, int address_part2)
  {
   positions[address_part2].OnTick(tick);

   if(print_data_compiled) logger.PrintDataCompiled();
  }

void PositionBucket::CloseAllPositions(MqlTick &tick)
  {
   if(logger.GetValue(OPENED) == 0) return;

   logger.Increment(OPENED_ABORTED, logger.GetValue(OPENED));

   for(int i = 0; i < positions_size; i++) positions[i].ForceToClose(tick);
  }

bool PositionBucket::CheckProperties(void)
  {
   if(id == NULL || id == ""){ Print("ERROR: Bucket id not defined."); return false; };

   return true;
  }

int PositionBucket::GetNextPlace(void)
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
