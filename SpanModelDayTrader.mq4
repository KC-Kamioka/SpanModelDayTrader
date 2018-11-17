//+------------------------------------------------------------------+
//|                                           SpanModelDayTrader.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| ライブラリ
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#include <Common.mqh>
int iSMSignal=NOSIGNAL;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Comment("");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//スパンモデルシグナル配信待機中
   if(iSMSignal!=NOSIGNAL)
     {
      Comment("スパンモデルシグナル配信待機中");
     }
//スパンモデルシグナル配信済み
   else
     {
      Comment("スパンモデルシグナル配信済み");
     }
//配信制限
   if(iVolume(OrderSymbol(),PERIOD_CURRENT,0)!=1) return;
//スパンモデルシグナル点灯チェック
   double dPreBlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,-24);
   double dBlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,-25);
   double dPreRedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,-24);
   double dRedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,-25);
//買いシグナルのとき
   if(dPreBlueSpan<dPreRedSpan && dBlueSpan>=dRedSpan)
     {
      iSMSignal=SIGNALBUY;
     }
//売りシグナルのとき
   if(dPreBlueSpan>dPreRedSpan && dBlueSpan<=dRedSpan)
     {
      iSMSignal=SIGNALSELL;
     }
//シグナル未点灯の場合は処理終了
   if(iSMSignal==NOSIGNAL) return;
//遅行スパンシグナル点灯チェック
   int iHighestBarNo=iHighest(NULL,PERIOD_CURRENT,MODE_CLOSE,27,2);
   double dHigh=High[iHighestBarNo];
   int iLowestBarNo=iLowest(NULL,PERIOD_CURRENT,MODE_CLOSE,27,2);
   double dLow=Low[iLowestBarNo];
   double dClose=iClose(NULL,PERIOD_CURRENT,1);
//スパンモデル買いシグナルが点灯中のとき
   if(iSMSignal==SIGNALBUY)
     {
      //買い方向にブレイク
      if(dHigh<dClose)
        {
         //シグナル配信
         string sMessage="【スパンモデル】遅行スパンブレイク（買）";
         sMessage=sMessage+rtnCode+"通貨："+Symbol();
         SendNotification(sMessage);
         Print(sMessage);
         iSMSignal=NOSIGNAL;
        }
     }
//スパンモデル売りシグナルが点灯中のとき
   if(iSMSignal==SIGNALSELL)
     {
      //売り方向にブレイク
      if(dLow>dClose)
        {
         //シグナル配信
         string sMessage="【スパンモデル】遅行スパンブレイク（売）";
         sMessage=sMessage+rtnCode+"通貨："+Symbol();
         SendNotification(sMessage);
         Print(sMessage);
         iSMSignal=NOSIGNAL;
        }
     }
  }
//+------------------------------------------------------------------+
