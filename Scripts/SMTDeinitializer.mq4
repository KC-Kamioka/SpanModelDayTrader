//+------------------------------------------------------------------+
//|                                             SMTDeinitializer.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
long lChartID=0;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//ポジションクローズ
   for(int i=0; i<OrdersTotal(); i++)
     {
      bool bSelected=OrderSelect(i,SELECT_BY_POS);
         bool Closed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,Magenta);
     }
     
//現在表示中のチャートを閉じる
   lChartID=ChartFirst();
   while(lChartID>0)
     {
      //現在のチャートの場合
      if(lChartID==ChartID())
        {
         //次のチャートをセット
         lChartID=ChartNext(lChartID);
        }
      else
        {
         //チャートを閉じる
         ChartClose(lChartID);

         //次のチャートをセット
         lChartID=ChartNext(lChartID);
        }
     }   
  }
//+------------------------------------------------------------------+
