enum ENUM_LOGGER_KEY
  {
   COUNT          = 0,
   WITH_LOSS      = 1,
   WITH_PROFIT    = 2,
   OPENED         = 3,
   OPENED_MAX     = 4,
   OPENED_ABORTED = 5,
   BALANCE_FINAL  = 6
  };

namespace Paibot
{
class Logger
  {
private:
   string          parent_id;
   double          stats[7];
   string          balance_chain;
public:
                   Logger(void);
                  ~Logger(void){};

   void            SetParentId(string _parent_id);
   double          GetValue(ENUM_LOGGER_KEY key);
   void            Increment(ENUM_LOGGER_KEY key, double value);
   void            KeepMax(ENUM_LOGGER_KEY key, double value);
   void            AddBalance(double balance);
   void            Audit(void);
  };

void Logger::Logger(void)
  {
   for(int i = 0; i < ArraySize(stats); i++) stats[i] = 0;

   balance_chain = "0\t";
  }

void Logger::SetParentId(string _parent_id)
  {
   parent_id = _parent_id;
  }

double Logger::GetValue(ENUM_LOGGER_KEY key)
  {
   return stats[key];
  }

void Logger::Increment(ENUM_LOGGER_KEY key, double value)
  {
   stats[key] += value;
  }

void Logger::KeepMax(ENUM_LOGGER_KEY key, double value)
  {
   stats[key] = MathMax(stats[key], value);
  }

void Logger::AddBalance(double balance)
  {
   StringConcatenate(balance_chain, balance_chain, (string)balance + "\t");

   stats[6] += balance;
  }

void Logger::Audit(void)
  {
   
  }
}
