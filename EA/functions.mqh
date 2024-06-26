#property copyright "Jakub Swadzba 2024"
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
CTrade pozycja; 
CPositionInfo pozycjaInfo;

#ifndef our_signals
#define our_signals
enum signals_combination
   {
      //if (MAsignalCheck()=="BUY")
      MA,
      //if (ADX_plus_minus_signalCheck()=="BUY")
      ADXPM,//ADXplus/minus
      //if (ADX_plus_minus_signalCheck()=="BUY" && MAsignalCheck() == "BUY")
      MA_ADXPM,
      //if (ADX_level_check(i_AdxLevel) && MAsignalCheck() == "BUY")
      MA_ADXLevel,
      //if (ADX_level_check(i_AdxLevel) && MAsignalCheck() == "BUY" && ADX_plus_minus_signalCheck()=="BUY")
      MA_ADXLevel_PM
   };
#endif


ulong ticket;
int uchwytADX;
int uchwytMA;
bool flagBE = true;
//+------------------------------------------------------------------+
//|                        Transaction EA
//+------------------------------------------------------------------+
double cenaAsk()//kupno
   {
      return SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   } 
double cenaBid()//sprzedaz
   {
      return SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
double priceNormalize(double cena)
   {
      return NormalizeDouble(cena, _Digits);
   }
bool otwarciePozycji(string typ, double wolumen , double sl, double tp)//wolumen = wielkosc pozycji
{ 
      
      pozycjaInfo.SelectByTicket(ticket);
      bool warunek = (pozycjaInfo.PositionType() == POSITION_TYPE_BUY && typ =="BUY" && ticket!= 0) ||
     (pozycjaInfo.PositionType() == POSITION_TYPE_SELL && typ =="SELL" && ticket!= 0) ;
      if (!warunek)
      {
            zamknieciePozycji();
            if (typ ==  "BUY")
            {
               if (!pozycja.PositionOpen(_Symbol, ORDER_TYPE_BUY, wolumen, priceNormalize(cenaAsk()), priceNormalize(sl), priceNormalize(tp)))
               {
                  Print("Blad otwarcia pozycji BUY");
                  return false;
               }
               else
                  {
                     ticket = pozycja.ResultOrder();
                     Print("Pozycja BUY otwarta pomyslnie", ticket);
                     return true;
                  
                  }
            }
            else if (typ == "SELL")
            {
               if (!pozycja.PositionOpen(_Symbol, ORDER_TYPE_SELL, wolumen, priceNormalize(cenaBid()), priceNormalize(sl), priceNormalize(tp)))
                  {
                     Print("Blad otwarcia pozycji SELL");
                     return false;
                  }
               else
                  {
                        ticket = pozycja.ResultOrder();
                        Print("Pozycja SELL otwarta pomyslnie ", ticket);
                        return true;
                  }
            }
       }


  
   return false;
}


bool zamknieciePozycji()
   {
      if (ticket !=0 )
         {
            if (!pozycja.PositionClose(ticket))
               {
                  Print("Blad zamykania pozycji ", ticket);
                  return false;
               }
            else 
               {
                  Print("Pozycja zamknieta: ", ticket);
                  ticket = 0;
                  flagBE = true; 
               }
         
         }
      return true;
   
   }
double convertPtsToPriceSL(string typ, int punkty)
   {
      if (punkty >0 && typ == "BUY") 
         {
            return cenaAsk() - (punkty * _Point);
         }
         
      else if (punkty >0 && typ == "SELL")
         {
            return cenaBid() + punkty*_Point;
         }
         
         
      return 0;
   }
double convertPtsToPriceTP(string typ, int punkty)
   {
      if (punkty >0 && typ == "BUY") 
         {
            return cenaAsk() + (punkty * _Point);
         }
         
      else if (punkty >0 && typ == "SELL")
         {
            return cenaBid() - punkty*_Point;
         }
         
         
      return 0;
   }
 
void setMN(ulong numer)
   {
      pozycja.SetExpertMagicNumber(numer);
   
   
   }

bool modyfikacjaPozycji(string typ,double sl, double tp)
{ 
   if (typ ==  "BUY")
   {
      if (!pozycja.PositionModify(ticket,priceNormalize(sl),priceNormalize(tp)))
      {
         Print("Blad modyfikacji pozycji BUY");
         return false;
      }
      
   }
   else if (typ == "SELL")
   {
      if (!pozycja.PositionModify(ticket,priceNormalize(sl),priceNormalize(tp)))
         {
            Print("Blad modyfikacji pozycji SELL");
            return false;
         }
      
   }

   Print("Pozycja zmodyfikowana pomyslnie ", ticket);
   return true;
}
   
   


//+------------------------------------------------------------------+
//|                        Transaction Control
//+------------------------------------------------------------------+

bool platformWork(string odGodz, string doGodz)
   {
//"09:00"
   if (Symbol()=="BTCUSDT"){return true;}
   else 
   {
   
      int odGodziny = (int)StringSubstr(odGodz, 0, 2);
      int odMinuty = (int)StringSubstr(odGodz, 3, 2);
      int doGodziny = (int)StringSubstr(doGodz, 0, 2);
      int doMinuty = (int)StringSubstr(odGodz, 3, 2);
   //Print("Od godziny: ", odGodziny, " od minuty: ", odMinuty," Do godziny: ", doGodziny, " Do minuty: ", doMinuty);
      datetime tc = TimeCurrent();
      //Print("Time: ", tc);
      //Print(TimeCurrent());
      long minute = (tc/(60))%60;
      long hour = (tc / (60*60))%24;
   
      MqlDateTime czas;
      TimeCurrent(czas);
   
      if((czas.day_of_week !=0 && czas.day_of_week != 6) && (hour >= odGodziny && hour < doGodziny))
        {
         //21:00 ---> Current time
         // Time set to 09:00 - 21:00
         if(hour == doGodziny && doMinuty == 0)
            return false;
         if(hour == doGodziny && minute >= doMinuty)
            return false;
         if(hour == odGodziny && minute <= odMinuty)
            return false;
         return true;
        }
   
      return false;
   }

  }
void resetTicket()
   {
      if(ticket != 0)
         {
            if (!PositionSelectByTicket(ticket))//boolean
               {
                  Print("ticket numer: ", ticket," zostal usuniety");
                  ticket = 0;
                  flagBE = true;
               }
         }
   }

bool wszystkieSygnaly(string typ, signals_combination rodzajSygnalu, int poziomADX)
   {
   
         if (typ == "BUY")
         {
         if (rodzajSygnalu == MA) 
            {
               return (MAsignalCheck() == "BUY");
               
            }
         else if (rodzajSygnalu == ADXPM) 
            {
               return (ADX_plus_minus_signalCheck() == "BUY");
              
            }
         
         else if (rodzajSygnalu == MA_ADXPM) 
            {
               return (ADX_plus_minus_signalCheck()=="BUY" && MAsignalCheck() == "BUY");
               
            }
         else if (rodzajSygnalu == MA_ADXLevel) 
            {
               return (ADX_level_check(poziomADX) && MAsignalCheck() == "BUY");
               
            }
         else if (rodzajSygnalu == MA_ADXLevel_PM)
            {
            
               return (ADX_level_check(poziomADX) && MAsignalCheck() == "BUY" && ADX_plus_minus_signalCheck()=="BUY");
            }
      
         }
   else if (typ == "SELL")
      {
         if (rodzajSygnalu == MA) 
            {
              
               return (MAsignalCheck() == "SELL");
            }
         else if (rodzajSygnalu == ADXPM) 
            {
               
               return (ADX_plus_minus_signalCheck() == "SELL");
            }
         
         else if (rodzajSygnalu == MA_ADXPM) 
            {
              
               return (ADX_plus_minus_signalCheck()=="SELL" && MAsignalCheck() == "SELL");
            }
         else if (rodzajSygnalu == MA_ADXLevel) 
            {
               
               return (ADX_level_check(poziomADX) && MAsignalCheck() == "SELL");
            }
         else if (rodzajSygnalu == MA_ADXLevel_PM)
            {
            
               return (ADX_level_check(poziomADX) && MAsignalCheck() == "SELL" && ADX_plus_minus_signalCheck()=="SELL");
            }
      
      
   }
            
      
   return false;
   }


//+------------------------------------------------------------------+
//|                        Signals and indicators
//+------------------------------------------------------------------+
bool newCandle()
   {
      static datetime timeOfLastCandle = D'1970.01.01';
      
      //Print("Wartosc iTime: ", iTime(_Symbol, PERIOD_CURRENT,0));
      if (timeOfLastCandle != iTime(_Symbol,PERIOD_CURRENT,0))
         {
            
            timeOfLastCandle = iTime(_Symbol,PERIOD_CURRENT,0);
            return true;
         }
      
      
      return false;
   }
   
void drawGraph(int numerSwiecy, string nazwa, ENUM_OBJECT objekt, color kolor, int wielkosc)
   {
      datetime osX = iTime(_Symbol, PERIOD_CURRENT,numerSwiecy);
      double osY = iHigh(_Symbol, PERIOD_CURRENT, numerSwiecy)+(1000 * _Point);
      ObjectDelete(0,nazwa);
      ObjectCreate(0,nazwa, objekt, 0,osX,osY);
      ObjectSetInteger(0,nazwa,OBJPROP_COLOR,kolor);
      ObjectSetInteger(0,nazwa,OBJPROP_WIDTH,wielkosc);
   
   }


bool startMA(int okresMA, ENUM_MA_METHOD metodaMA, ENUM_APPLIED_PRICE cenaMA)
   {
      uchwytMA = iMA(_Symbol,PERIOD_CURRENT,okresMA,0,metodaMA,cenaMA);
      if (uchwytMA == -1)
         {
            Print("Blad otwarcia indicatora MA");
            return false;
         }
      return true;
   }
   
void usunMA()
   {
      IndicatorRelease(uchwytMA); //Zwalanianie zasobów,usuwanie
   }
string MAsignalCheck()
   {
         double tablicaMA[]; //deklaracja tablicy
         ArraySetAsSeries(tablicaMA,true);
         CopyBuffer(uchwytMA,0,0,3,tablicaMA); //przenosi wartosci z bufora do tablicy
         //ArrayPrint(tablicaMA);
         
         if (tablicaMA[0]<iOpen(_Symbol,PERIOD_CURRENT,0))                          //iOpen -> funkcja dająca wartość otwarcia danej świecy
            {
               
               return "BUY";
            }
         else if(tablicaMA[0] > iOpen(_Symbol,PERIOD_CURRENT,0))
            {
               return "SELL";
            }
      return "NULL";
   }         
          
bool startADX(int okresADX)
   {
      uchwytADX = iADXWilder(_Symbol,PERIOD_CURRENT,okresADX);
      if (uchwytADX == -1)
         {
            Print("Blad otwarcia indicatora ADX Wilder");
            return false;
         }
      return true;
   }
void usunADX()
   {
      IndicatorRelease(uchwytADX); //Zwalanianie zasobów,usuwanie
   }   
string ADX_plus_minus_signalCheck()
   {
         //double tablicaMA[]; //deklaracja tablicy
         //double tablicaADX[];
         double tablicaDIplus[];
         double tablicaDIminus[];
         ArraySetAsSeries(tablicaDIplus,true);
         ArraySetAsSeries(tablicaDIminus,true);
         //ArraySetAsSeries(tablicaMA,true);
         CopyBuffer(uchwytADX,1,0,3,tablicaDIplus); //przenosi wartosci z bufora do tablicy
         CopyBuffer(uchwytADX,2,0,3,tablicaDIminus);
         //Print("Tablica DI +:");
         //ArrayPrint(tablicaDIplus);
         //Print("Tablica DI -:");
         //ArrayPrint(tablicaDIminus);
         //ArrayPrint(tablicaMA);
        
         if (tablicaDIplus[2] < tablicaDIminus[2] && tablicaDIplus[1] > tablicaDIminus[1])                          //iOpen -> funkcja dająca wartość otwarcia danej świecy
            {
               
               return "BUY";
            }
         else if(tablicaDIminus[2] < tablicaDIplus[2] && tablicaDIminus[1] > tablicaDIplus[1])
            {
               return "SELL";
            }
      return "NULL";
   }         
 
bool ADX_level_check(int poziomADX)
   {
         double tablicaADX[];
         ArraySetAsSeries(tablicaADX,true);
         CopyBuffer(uchwytADX,0,0,3,tablicaADX); //przenosi wartosci z bufora do tablicy
 
         if (tablicaADX[0] > poziomADX)   //iOpen -> funkcja dająca wartość otwarcia danej świecy
            {
               
               return true;
            }
        
            
      return false;
   }         

//+------------------------------------------------------------------+
//|                        Wallet management
//+------------------------------------------------------------------+
void breakEven(int punktyBE)
   {
      if(ticket>0 && flagBE == true && punktyBE > 0)
         {
            pozycjaInfo.SelectByTicket(ticket);
         if (pozycjaInfo.PositionType() == POSITION_TYPE_BUY && pozycjaInfo.PriceOpen() <(cenaAsk()-punktyBE*_Point))
               {
                  
                  modyfikacjaPozycji("BUY",pozycjaInfo.PriceOpen() + 20 * _Point,pozycjaInfo.TakeProfit());
                  flagBE = false;
                  Print("b/e set");
                  
               }
            if (pozycjaInfo.PositionType() == POSITION_TYPE_SELL && pozycjaInfo.PriceOpen() >(cenaBid()+punktyBE*_Point))
               {
                  modyfikacjaPozycji("SELL",pozycjaInfo.PriceOpen() - 20 * _Point,pozycjaInfo.TakeProfit());
                  flagBE = false;
                  Print("b/e set");
               }
          }
   
   }




//+------------------------------------------------------------------+
