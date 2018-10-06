//+------------------------------------------------------------------+
//|                                               SMTInitializer.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <SMT0000.mqh>
long lChartID=0;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//チャートを開く
   for(int i=0;i<ArraySize(OpenSymbol);i++)
     {
      //チャートを開く
      lChartID=ChartOpen(OpenSymbol[i],PERIOD_M5);

      //テンプレート適用
      ChartApplyTemplate(lChartID,SMTTEMPLATE);
     }   
  }
//+------------------------------------------------------------------+
