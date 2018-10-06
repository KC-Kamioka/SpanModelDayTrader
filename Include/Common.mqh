//+------------------------------------------------------------------+
//|                                                       Common.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
string rtnCode = "\r\n";
int Slippage = 100;
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
enum DEBUG_LEVEL
  {
   INFO,
   ERROR
  };
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
enum SIGNAL
  {
   NOSIGNAL,
   SIGNALBUY,
   SIGNALSELL
  };
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
string Symbols[]=
  {
   "USDJPY",
   "EURJPY",
   "EURUSD",
   "GBPJPY",
   "GBPUSD",
   "AUDJPY",
   "AUDUSD",
   "EURGBP",
   "EURAUD",
   "GBPAUD"
  };
//+------------------------------------------------------------------+
