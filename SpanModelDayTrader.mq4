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
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
struct SymbolInfo
  {
   string            sSymbol;
   int               iSignal;
   bool              IsSent;
  };
//+------------------------------------------------------------------+
//| 変数                                                          |
//+------------------------------------------------------------------+
SymbolInfo si[];
int SymbolCount=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//構造体初期化
   SymbolCount=ArraySize(Symbols);
   ArrayResize(si,SymbolCount);
   for(int i=0; i<SymbolCount; i++)
     {
      si[i].sSymbol=Symbols[i];
      si[i].iSignal=NOSIGNAL;
     }
//コメント初期化
   string sMessage=NULL;
   for(int i=0; i<SymbolCount; i++)
     {
      sMessage=sMessage+si[i].sSymbol+" "+"スパンモデルシグナル配信待機中"+rtnCode;
     }
   Comment(sMessage);
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
//配信制限
   if(iVolume(NULL,PERIOD_CURRENT,0)!=1) return;
//シグナル配信コメント
   string sMessage=NULL;
   for(int i=0; i<SymbolCount; i++)
     {
      //スパンモデルシグナル配信待機中
      if(si[i].iSignal!=NOSIGNAL)
        {
         sMessage=sMessage+si[i].sSymbol+" "+"スパンモデルシグナル配信待機中"+rtnCode;
        }
      //スパンモデルシグナル配信済み
      else
        {
         sMessage=sMessage+si[i].sSymbol+" "+"スパンモデルシグナル配信済み"+rtnCode;
        }
      Comment(sMessage);
     }
//スパンモデルシグナル点灯チェック
   for(int i=0; i<SymbolCount; i++)
     {
      CheckSpanModelSignal(si[i].sSymbol,si[i].iSignal,si[i].IsSent);
     }
//シグナル配信
   for(int i=0; i<SymbolCount; i++)
     {
      //シグナル未配信の場合
      if(!si[i].IsSent)
        {
         //シグナル配信
         SendSignal(si[i].sSymbol,si[i].iSignal,si[i].IsSent);
        }
     }
  }
//+------------------------------------------------------------------+
//| スパンモデルシグナルチェック                                             |
//+------------------------------------------------------------------+
void CheckSpanModelSignal(string inSymbol,int &ioSignal,bool &ioIsSent)
  {
//スパンモデルシグナルチェック
   double dPreBlueSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,3,-24);
   double dBlueSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,3,-25);
   double dPreRedSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,4,-24);
   double dRedSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,4,-25);
//買いシグナルのとき
   if(dPreBlueSpan<dPreRedSpan && dBlueSpan>=dRedSpan)
     {
      ioSignal=SIGNALBUY;
      ioIsSent=false;
     }
//売りシグナルのとき
   if(dPreBlueSpan>dPreRedSpan && dBlueSpan<=dRedSpan)
     {
      ioSignal=SIGNALSELL;
      ioIsSent=false;
     }
  }
//+------------------------------------------------------------------+
//| シグナル配信                                             |
//+------------------------------------------------------------------+
void SendSignal(string inSymbol,int inSignal,bool &ioIsSent)
  {
//同時刻スパンモデルシグナルチェック
   double dPreBlueSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,3,-24);
   double dBlueSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,3,-25);
   double dPreRedSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,4,-24);
   double dRedSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,4,-25);
//買いシグナルのとき
   if(dPreBlueSpan<dPreRedSpan && dBlueSpan>=dRedSpan)
     {
      return;
     }
//売りシグナルのとき
   if(dPreBlueSpan>dPreRedSpan && dBlueSpan<=dRedSpan)
     {
      return;
     }
//遅行スパンシグナル点灯チェック
   int iHighestBarNo=iHighest(inSymbol,PERIOD_CURRENT,MODE_CLOSE,27,2);
   double dHigh=iHigh(inSymbol,PERIOD_CURRENT,iHighestBarNo);
   int iLowestBarNo=iLowest(inSymbol,PERIOD_CURRENT,MODE_CLOSE,27,2);
   double dLow=iLow(inSymbol,PERIOD_CURRENT,iLowestBarNo);
   double dClose=iClose(inSymbol,PERIOD_CURRENT,1);
//スパンモデル買いシグナルが点灯中のとき
   if(inSignal==SIGNALBUY)
     {
      //買い方向にブレイク
      if(dHigh<dClose)
        {
         //シグナル配信
         string sMessage="【スパンモデル】遅行スパンブレイク（買）";
         sMessage=sMessage+rtnCode+"通貨："+inSymbol;
         SendNotification(sMessage);
         Print(sMessage);
         ioIsSent=true;
        }
     }
//スパンモデル売りシグナルが点灯中のとき
   if(inSignal==SIGNALSELL)
     {
      //売り方向にブレイク
      if(dLow>dClose)
        {
         //シグナル配信
         string sMessage="【スパンモデル】遅行スパンブレイク（売）";
         sMessage=sMessage+rtnCode+"通貨："+inSymbol;
         SendNotification(sMessage);
         Print(sMessage);
         ioIsSent=true;
        }
     }
  }
//+------------------------------------------------------------------+
