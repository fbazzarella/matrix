namespace Paibot
{
class Logger
  {
private:
   string          parent_id;
   double          stats[7]; // 0-count, 1-with_loss, 2-with_profit, 3-opened, 4-opened_max, 5-opened_aborted, 6-balance_final
   string          balance_chain;
public:
                   Logger(void);
                  ~Logger(void){};

   void            SetParentId(string _parent_id);
   double          GetValue(int i);
   void            Increment(int i, double value);
   void            KeepMax(int i, double value);
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

double Logger::GetValue(int i)
  {
   return stats[i];
  }

void Logger::Increment(int i, double value)
  {
   stats[i] += value;
  }

void Logger::KeepMax(int i, double value)
  {
   stats[i] = MathMax(stats[i], value);
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
