#property copyright "Jakub Swadzba 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"

#ifndef our_signals //checks if it ISN'T  already declared
#define our_signals
enum signals_combination
   {
      //if (MAsignalCheck()=="BUY")
      MA,
      //if (ADX_plus_minus_signalCheck()=="BUY")
      ADXPM,//ADXplus/minus
      //if (ADX_plus_minus_signalCheck()=="BUY" && MAsignalCheck() == "BUY")
      MA_ADXPM,
      //if (ADX_level_check(poziomADX) && MAsignalCheck() == "BUY")
      MA_ADXLevel,
      //if (ADX_level_check(poziomADX) && MAsignalCheck() == "BUY" && ADX_plus_minus_signalCheck()=="BUY")
      MA_ADXLevel_PM
   };
#endif
//Kombinacje sygnalow
sinput group "Kombinacje sygnalow"
input signals_combination i_rodzajSygnalu; //rodzaj sygnalu

//Identyfikacja EA
sinput group "Identity EA"
input ulong i_magicNumber = 2137;

//MA indicator
sinput group "indicator MA"
input int i_okresMA = 30; //ilosc swiec
input ENUM_MA_METHOD i_metodaMA = MODE_EMA; //metoda wyliczania MA
input ENUM_APPLIED_PRICE i_cenaMA = PRICE_WEIGHTED;

//ADX indicator
sinput group "indicator ADX"
input int i_okresADX = 21; //ilosc badanych swiec przez indykator
input int i_AdxLevel = 20; //declared if forgotten 
//Money managment
sinput group "Money Managment"
input int i_breakEvenPoints = 30000; //Amount of points we want to have b/e se
void breakEven(int punktyBE);
//Zmienne godzinowe (crypto useless)
sinput group "Godziny pracy EA";
input string i_odGodz = "09:00"; //Czas pracy od godziny:
input string i_doGodz = "21:00";//Czas pracy do godziny:
input bool i_praca_w_weekend = false;//Pracujemy w weekend
#include <EA\functions.mqh>
// Te bloczki są opcjonalne tak samo jak wywoływanie pustych funkcji 
//+------------------------------------------------------------------+
//|                        Transactions EA
//+------------------------------------------------------------------+
double cenaAsk();
double cenaBid();
double priceNormalize();
bool otwarciePozycji(string typ, double wolumen , double sl, double tp);
bool zamknieciePozycji();
double convertPtsToPriceSL(string typ, int punkty);
double convertPtsToPriceTP(string typ, int punkty);
void setMN(ulong numer);
double i_volume = 0.01;

//+------------------------------------------------------------------+
//|                        Transaction Control
//+------------------------------------------------------------------+
bool platformWork(string odGodz, string doGodz);
void resetTicket();
bool wszystkieSygnaly(string typ, signals_combination rodzajSygnalu, int poziomADX);
//+------------------------------------------------------------------+
//|                        Signals and indicators
//+------------------------------------------------------------------+
bool newCandle();
string numerEA = "123456";
void drawGraph(int numerSwiecy, string nazwa, ENUM_OBJECT objekt, color kolor, int wielkosc = 5);
bool startMA(int okresMA, ENUM_MA_METHOD metodaMA, ENUM_APPLIED_PRICE cenaMA);
void usunMA();
string MAsignalCheck();
bool startADX(int okresADX);
void usunADX();
string ADX_plus_minus_signalCheck();
bool ADX_level_check(int poziomADX);
//+------------------------------------------------------------------+
//|    OnInit  Uruchamia sie na poczatek dzialania EA                 
//+------------------------------------------------------------------+
int OnInit()
  {
   setMN(i_magicNumber);
   if (!startMA(i_okresMA,i_metodaMA,i_cenaMA))
      {
         return (INIT_FAILED);
      }
   if (!startADX(i_okresADX))
      {
         return (INIT_FAILED);
      }
    return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|  OnTick Dziala przy kazdej zmianie ceny (caly czas)              |
//+------------------------------------------------------------------+
void OnTick()
  {
   double tablicaMA[]; //deklaracja tablicy
         ArraySetAsSeries(tablicaMA,true);
         CopyBuffer(uchwytMA,0,0,3,tablicaMA); //przenosi wartosci z bufora do tablicy
         //ArrayPrint(tablicaMA);
   
   if(platformWork(i_odGodz, i_doGodz))
     {
         resetTicket();
         if (newCandle())
         {
            if (ADX_level_check(i_AdxLevel))//sprawdzam poziom ADX,  tj. czy jest powyzej zalozonego poziomu
            {
                          
               if (wszystkieSygnaly("BUY",i_rodzajSygnalu,i_AdxLevel))
                  {
                     otwarciePozycji("BUY",i_volume,0,0);
                     string postype = "BUY" + (string)iTime(_Symbol,PERIOD_CURRENT,0);
                     drawGraph(0,postype,OBJ_ARROW_CHECK,clrGreen,10);
                  }  
               
              else if (wszystkieSygnaly("SELL",i_rodzajSygnalu,i_AdxLevel))
                  {  
                     otwarciePozycji("SELL",i_volume,0,0);
                     string postype = "SELL" + (string)iTime(_Symbol,PERIOD_CURRENT,0);
                     drawGraph(0,postype,OBJ_ARROW_STOP,clrRed,10);
                  }
              }
         }  
        //breakEven(i_breakEvenPoints);
        
        
         
          
              
      }
   }
//+------------------------------------------------------------------+
//|    OnDeinit  Uruchamia sie pod koniec dzialania EA                                                            
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
      usunMA();
      usunADX();
  }
//+------------------------------------------------------------------+
