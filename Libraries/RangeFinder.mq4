//+------------------------------------------------------------------+
//|                                                  RangeFinder.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Common.mqh>
//+------------------------------------------------------------------+
//| レンジの通貨ペア取得                                                 |
//+------------------------------------------------------------------+
void GetRangeBreakSymbols(int UpperChartPeriod,string &CheckSymbols[],int &TradeSignals[]) export
  {
//始値でのみチェックする
if(iVolume(NULL,UpperChartPeriod,0)<1) return;
//初期化
   ArrayFree(CheckSymbols);
   ArrayFree(TradeSignals);

//レンジブレイク検索
   int nASize=ArraySize(Symbols);
   for(int i=0;i<nASize-1;i++)
     {
      bool IsRange=RangeFind(Symbols(i),UpperChartPeriod);
      if(IsRange)
        {
         //レンジブレイクした通貨ペアとシグナルを格納
         int DelayedSpanSignal=GetSignalDelayedSpanBreak(Symbols(i),1);
         if(DelayedSpanSignal!=NOSIGNAL)
         {
         int nChkRange=ArraySize(CheckSymbols);
         ArrayResize(CheckSymbols,nChkRange+1);
         ArrayResize(TradeSignals,nChkRange+1);
         CheckSymbols[nChkRange]=Symbols[i];
         TradeSignals[nChkRange]=DelayedSpanSignal;
         }
        }
     }
  }
//+------------------------------------------------------------------+
//| レンジ検索                                                         |
//+------------------------------------------------------------------+
bool RangeFind(string sSymbol,int UpperChartPeriod)
  {
   Print("【大局観】レンジ検索開始");

//遅行スパンクロスチェック
   int nBarNo=1;
   do
     {
      //遅行スパンがローソク足の高値と安値の間にあるとき
      double HighPrice=iLow(sSymbol,UpperChartPeriod,nBarNo+21);
      double LowPrice=iHigh(sSymbol,UpperChartPeriod,nBarNo+21);
      double Candle=iClose(sSymbol,UpperChartPeriod,nBarNo);
      if(HighPrice>=Candle && LowPrice<=Candle)
        {
         Print(TimeToString(iTime(sSymbol,UpperChartPeriod,nBarNo))+" "+
               "["+sSymbol+"]"+" "+
               "遅行スパンクロス");
         DelayedSpanSignal=NOSIGNAL;
        }
      nBarNo=nBarNo+1;
     }
   while(DelayedSpanSignal!=NOSIGNAL);

//遅行スパンシグナル点灯チェック
   do
     {
      DelayedSpanSignal=GetSignalDelayedSpanBreak(sSymbol,nBarNo);
      nBarNo=nBarNo-1;
     }
   while(nBarNo>1 && DelayedSpanSignal==NOSIGNAL);

//遅行スパンシグナル消灯
   Print("【大局観】レンジ検索終了");
   bool IsRange=false;
   if(DelayedSpanSignal==NOSIGNAL) IsRange=true;
   return IsRange;
  }
//+------------------------------------------------------------------+
//| 遅行スパンブレイクシグナル取得                                        |
//+------------------------------------------------------------------+
int GetSignalDelayedSpanBreak(string sSymbol,int nBarNo) export
  {
//遅行スパンブレイク判定（上昇）
   int HighestBarNo=iHighest(sSymbol,UpperChartPeriod,MODE_CLOSE,21,nBarNo+1);
   double PreHighestRate=iHigh(sSymbol,UpperChartPeriod,HighestBarNo+1);
   double HighestRate=iHigh(sSymbol,UpperChartPeriod,HighestBarNo);
   if(HighestRate<iClose(sSymbol,UpperChartPeriod,nBarNo))
     {
      Print(TimeToString(iTime(sSymbol,UpperChartPeriod,nBarNo))+" "+"遅行スパン買いシグナル点灯");
      return SIGNALBUY;
     }

//遅行スパンブレイク判定（下降）
   int LowestBarNo=iLowest(sSymbol,UpperChartPeriod,MODE_CLOSE,21,nBarNo+1);
   double PreLowestRate=iLow(sSymbol,UpperChartPeriod,LowestBarNo+1);
   double LowestRate=iLow(sSymbol,UpperChartPeriod,LowestBarNo);
   if(LowestRate>iClose(sSymbol,UpperChartPeriod,nBarNo))
     {
      Print(TimeToString(iTime(sSymbol,UpperChartPeriod,nBarNo))+" "+"遅行スパン売りシグナル点灯");
      return SIGNALSELL;
     }
   return NOSIGNAL;
  }
//+------------------------------------------------------------------+
