     template<typename T>
void ArrayFillFromString(T &array[], string &_string)
  {
   string values[];

   StringSplit(_string, StringGetCharacter("_", 0), values);

   ArrayConvertFromStringAndCopy(array, values);
  }

void ArrayConvertFromStringAndCopy(ENUM_TIMEFRAMES &dst_array[], string &src_array[])
  {
   int size = ArrayResize(dst_array, ArraySize(src_array));

   for(int i = 0; i < size; i++) dst_array[i] = (ENUM_TIMEFRAMES)src_array[i];
  }

void ArrayConvertFromStringAndCopy(int &dst_array[], string &src_array[])
  {
   int size = ArrayResize(dst_array, ArraySize(src_array));

   for(int i = 0; i < size; i++) dst_array[i] = (int)src_array[i];
  }

void ArrayConvertFromStringAndCopy(double &dst_array[], string &src_array[])
  {
   int size = ArrayResize(dst_array, ArraySize(src_array));

   for(int i = 0; i < size; i++) dst_array[i] = (double)src_array[i];
  }

void ArrayConvertFromStringAndCopy(string &dst_array[], string &src_array[])
  {
   ArrayCopy(dst_array, src_array);
  }

bool ArrayFillFromFile(string &array[], int handler, string search_term)
  {
   FileSeek(handler, 0, SEEK_SET);

   while(!FileIsEnding(handler))
     {
      StringSplit(FileReadString(handler), StringGetCharacter(";", 0), array);

      if(array[0] == search_term) return true;
     }

   return false;
  }
