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
   Properties      none;
   Properties      SetProperties(string symbol, string parameters_order, string parameters_chain, string header_chain);
   void            SetParametersAndHeader(Properties &properties, string parameters_chain, string header_chain);
   bool            LoadSymbolData(string symbol, string &parameters[], string &header[]);
public:
                   Symbol(void){};
                  ~Symbol(void){};

   Properties      GetProperties(string symbol);
  };

Properties Symbol::GetProperties(string symbol)
  {
   string parameters[],
          header[];

   if(!LoadSymbolData(symbol, parameters, header)) return none;

   return SetProperties(symbol, parameters[1], parameters[2], header[2]);
  }

Properties Symbol::SetProperties(string symbol, string parameters_order, string parameters_chain, string header_chain)
  {
   Properties properties;

   SetParametersAndHeader(properties, parameters_chain, header_chain);

   properties.bound_begin  = (int)properties.header[0];
   properties.bound_finish = (int)properties.header[1];
   properties.tick_size    = properties.header[2];
   properties.multiplier   = properties.header[3];
   properties.comission    = properties.header[4];
   properties.close        = iClose(symbol, 0, 0);
   properties.label        = StringSubstr(symbol, 0, 3);
   properties.order        = parameters_order;

   StringToLower(properties.label);

   return properties;
  }

void Symbol::SetParametersAndHeader(Properties &properties, string parameters_chain, string header_chain)
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
  }

bool Symbol::LoadSymbolData(string symbol, string &parameters[], string &header[])
  {
   int handler = FileOpen("Matrix/_ParametersSets/" + symbol + ".csv", FILE_READ|FILE_TXT|FILE_COMMON|FILE_ANSI, ";");

   if(handler == -1) return false;

   bool success_parameters = ArrayFillFromFile(parameters, handler, "use"),
        success_header     = ArrayFillFromFile(header,     handler, "header");

   FileClose(handler);

   return success_parameters && success_header;
  }
}
