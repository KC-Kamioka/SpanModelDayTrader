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
   int               iSendCount;
  };
string Symbols[]=
  {
   "USDJPY",
   "EURJPY",
   "EURUSD",
   "GBPJPY",
   "AUDJPY",
  };
//+------------------------------------------------------------------+
//| 定数                                                          |
//+------------------------------------------------------------------+
#define MSG001 "スパンモデルシグナル配信中"
#define MSG002 "スパンモデルシグナル配信済み"
#define MSG003 "スパンモデルシグナル配信"
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
   string sMessage=NULL;
   for(int i=0; i<SymbolCount; i++)
     {
      //通貨ペア格納
      si[i].sSymbol=Symbols[i];
      //スパンモデルシグナル初期化
      double dBlueSpan=iIchimoku(Symbols[i],PERIOD_CURRENT,9,26,52,3,-25);
      double dRedSpan=iIchimoku(Symbols[i],PERIOD_CURRENT,9,26,52,4,-25);
      //買いシグナルのとき
      if(dBlueSpan>dRedSpan) si[i].iSignal=SIGNALBUY;
      //売りシグナルのとき
      else if(dBlueSpan<dRedSpan) si[i].iSignal=SIGNALSELL;
      //上記以外
      else si[i].iSignal=NOSIGNAL;
      //配信数初期化
      si[i].iSendCount=0;
      //コメント初期化
      sMessage=sMessage+Symbols[i]+" "+MSG001+rtnCode;
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
      //スパンモデルシグナル点灯チェック
      CheckSpanModelSignal(si[i].sSymbol,si[i].iSignal,si[i].iSendCount);
      //シグナル配信数が３回未満の場合
      if(si[i].iSendCount<3)
        {
        //スパンモデルシグナル配信中
         sMessage=sMessage+si[i].sSymbol+" "+MSG001+rtnCode;
        //シグナル配信
         SendSignal(si[i].sSymbol,si[i].iSignal,si[i].iSendCount);
        }
      else
        {
        //スパンモデルシグナル配信済み
         sMessage=sMessage+si[i].sSymbol+" "+MSG002+rtnCode;
        }
      Comment(sMessage);
     }
  }
//+------------------------------------------------------------------+
//| スパンモデルシグナルチェック                                             |
//+------------------------------------------------------------------+
void CheckSpanModelSignal(string sSymbol,int &ioSignal,int &ioSendCount)
  {
//スパンモデルシグナルチェック
   double dPreBlueSpan=iIchimoku(sSymbol,PERIOD_CURRENT,9,26,52,3,-24);
   double dBlueSpan=iIchimoku(sSymbol,PERIOD_CURRENT,9,26,52,3,-25);
   double dPreRedSpan=iIchimoku(sSymbol,PERIOD_CURRENT,9,26,52,4,-24);
   double dRedSpan=iIchimoku(sSymbol,PERIOD_CURRENT,9,26,52,4,-25);
//買いシグナルのとき
   if(dPreBlueSpan<dPreRedSpan && dBlueSpan>=dRedSpan)
     {
      ioSignal=SIGNALBUY;
      ioSendCount=0;
     }
//売りシグナルのとき
   if(dPreBlueSpan>dPreRedSpan && dBlueSpan<=dRedSpan)
     {
      ioSignal=SIGNALSELL;
      ioSendCount=0;
     }
  }
//+------------------------------------------------------------------+
//| シグナル配信                                             |
//+------------------------------------------------------------------+
void SendSignal(string inSymbol,int inSignal,int &ioSendCount)
  {
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
         string sMessage=MSG003;
         sMessage=sMessage+rtnCode+"通貨："+inSymbol;
         sMessage=sMessage+rtnCode+"方向：買";
         SendNotification(sMessage);
         Print(sMessage);
         ioSendCount=ioSendCount+1;
        }
     }
//スパンモデル売りシグナルが点灯中のとき
   if(inSignal==SIGNALSELL)
     {
      //売り方向にブレイク
      if(dLow>dClose)
        {
         //シグナル配信
         string sMessage=MSG003;
         sMessage=sMessage+rtnCode+"通貨："+inSymbol;
         sMessage=sMessage+rtnCode+"方向：売";
         SendNotification(sMessage);
         Print(sMessage);
         ioSendCount=ioSendCount+1;
        }
     }
  }
//+------------------------------------------------------------------+
