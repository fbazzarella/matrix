datetime time_initialization = TimeTradeServer();
int      time_activity       = 0;

int GetSessionPeriod(int ilower, int ihigher, int _begin, int _finish)
  {
   string   slower   = (string)ilower,
            shigher0 = (string)ihigher,
            shigher1 = (string)(ihigher + 1),
            begin    = (_begin  < ilower  ? slower   : (string)_begin)  + ":00",
            finish   = (_finish > ihigher ? shigher0 : (string)_finish) + ":59";
   datetime now      = TimeTradeServer();
   int      period   = 0;

        if(now >= S2T("0:00")           && now <= S2T(begin))            period = 0;
   else if(now >  S2T(begin)            && now <= S2T(finish))           period = 1;
   else if(now >  S2T(finish)           && now <= S2T(shigher0 + ":59")) period = 2;
   else if(now >= S2T(shigher1 + ":00") && now <= S2T(shigher1 + ":29")) period = 3;
   else if(now >= S2T(shigher1 + ":30") && now <= S2T("23:59"))          period = 0;
   
   return period;
  }

datetime S2T(string hm)
  {
   MqlDateTime now;
   TimeTradeServer(now);

   string time;

   StringConcatenate(time, now.year, ".", now.mon, ".", now.day, " ", hm, ":00");

   return StringToTime(time);
  }

string T2S(datetime _time)
  {
   string time = TimeToString(_time, TIME_DATE|TIME_SECONDS);

   StringReplace(time, " ", "");
   StringReplace(time, ".", "");
   StringReplace(time, ":", "");

   return time;
  }
