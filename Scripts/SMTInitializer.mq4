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
//�`���[�g���J��
   for(int i=0;i<ArraySize(OpenSymbol);i++)
     {
      //�`���[�g���J��
      lChartID=ChartOpen(OpenSymbol[i],PERIOD_M5);

      //�e���v���[�g�K�p
      ChartApplyTemplate(lChartID,SMTTEMPLATE);
     }   
  }
//+------------------------------------------------------------------+
