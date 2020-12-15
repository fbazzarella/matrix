int GetSessionPeriod(int _begin = 10, int _finish = 15)
  {
   string   begin  = (string)_begin  + ":00",
            finish = (string)_finish + ":59";
   datetime now    = TimeTradeServer();
   int      period = 0;

        if(now >= S2T("0:00")  && now <= S2T(begin))   period = 0;
   else if(now >  S2T(begin)   && now <= S2T(finish))  period = 1;
   else if(now >  S2T(finish)  && now <= S2T("16:59")) period = 2;
   else if(now >= S2T("17:00") && now <= S2T("17:29")) period = 3;
   else if(now >= S2T("17:30") && now <= S2T("23:59")) period = 4;
   
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
