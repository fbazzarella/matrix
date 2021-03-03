struct Properties
  {
   ENUM_TIMEFRAMES timeframes[];
   int             ma_short[],
                   ma_long[],
                   time_begin[],
                   time_finish[];
   double          loss[],
                   profit[],
                   header[];
   string          daysoff[];
   int             bound_begin,
                   bound_finish;
   double          tick_size,
                   multiplier,
                   comission,
                   close;
   string          label,
                   order;
  };

namespace Matrix
{
class Symbol
  {
private:
   bool            AdjustTimeframes(void);
   void            SetProperties(string symbol, string parameters_order, string parameters_chain, string header_chain, string daysoff_chain);
   void            ParseSymbolData(string parameters_chain, string header_chain, string daysoff_chain);
   bool            LoadSymbolData(string symbol, string &parameters[], string &header[], string &daysoff[]);
public:
   Properties      properties;

                   Symbol(void){};
                  ~Symbol(void){};

   bool            OnInit(string symbol);
   bool            IsTodayADayOff(void);
  };

bool Symbol::OnInit(string symbol)
  {
   string parameters[],
          header[],
          daysoff[];

   if(!LoadSymbolData(_Symbol, parameters, header, daysoff)){ Print("ERROR: Please check the Symbol used."); return false; };

   SetProperties(_Symbol, parameters[1], parameters[2], header[2], daysoff[2]);

   if(!AdjustTimeframes()){ Print("ERROR: Please check the Parameters Set numbers."); return false; };

   return true;
  }

bool Symbol::IsTodayADayOff(void)
  {
   for(int i = 0; i < ArraySize(properties.daysoff); i++) if(properties.daysoff[i] == Today2S()) return true;

   return false;
  }

bool Symbol::AdjustTimeframes(void)
  {
   int n    = matrix_global_parameters_set_n,
       of   = matrix_global_parameters_set_of,
       size = ArraySize(properties.timeframes);

   if(n <= 0 || n > of || of <= 0 || of > size) return false;

   int _timeframes[],
       _size,
       _i;

   for(int i = 0; i <= size; i += of)
     {
      _i = i + n - 1;

      if(_i < size)
        {
         _size = ArraySize(_timeframes);

         ArrayResize(_timeframes, _size + 1);
         ArrayFill  (_timeframes, _size, 1, properties.timeframes[_i]);
        };
      }

   ArrayFree(properties.timeframes);
   ArrayCopy(properties.timeframes, _timeframes);

   return true;
  }

void Symbol::SetProperties(string symbol, string parameters_order, string parameters_chain, string header_chain, string daysoff_chain)
  {
   ParseSymbolData(parameters_chain, header_chain, daysoff_chain);

   properties.bound_begin  = (int)properties.header[0];
   properties.bound_finish = (int)properties.header[1];
   properties.tick_size    = properties.header[2];
   properties.multiplier   = properties.header[3];
   properties.comission    = properties.header[4];
   properties.close        = iClose(symbol, 0, 0);
   properties.label        = StringSubstr(symbol, 0, 3);
   properties.order        = parameters_order;

   StringToLower(properties.label);
  }

void Symbol::ParseSymbolData(string parameters_chain, string header_chain, string daysoff_chain)
  {
   string parameters[];
   
   StringSplit(parameters_chain, StringGetCharacter("#", 0), parameters);

   ArrayFillFromString(properties.timeframes,  parameters[0]);
   ArrayFillFromString(properties.ma_short,    parameters[1]);
   ArrayFillFromString(properties.ma_long,     parameters[2]);
   ArrayFillFromString(properties.time_begin,  parameters[3]);
   ArrayFillFromString(properties.time_finish, parameters[4]);
   ArrayFillFromString(properties.loss,        parameters[5]);
   ArrayFillFromString(properties.profit,      parameters[6]);
   ArrayFillFromString(properties.header,      header_chain);
   ArrayFillFromString(properties.daysoff,     daysoff_chain);
  }

bool Symbol::LoadSymbolData(string symbol, string &parameters[], string &header[], string &daysoff[])
  {
   int handler = FileOpen("Matrix/Symbols/" + symbol + ".csv", FILE_SHARE_READ|FILE_TXT|FILE_COMMON|FILE_ANSI, ";");

   if(handler == -1) return false;

   bool success_parameters = ArrayFillFromFile(parameters, handler, "use"),
        success_header     = ArrayFillFromFile(header,     handler, "header"),
        success_daysoff    = ArrayFillFromFile(daysoff,    handler, "daysoff");

   FileClose(handler);

   return success_parameters && success_header && success_daysoff;
  }
}
