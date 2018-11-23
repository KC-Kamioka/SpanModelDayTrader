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
   datetime          dtSignalOn;
   bool              IsSent;
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
#define MSG002 "スパンモデルシグナル配信終了"
#define MSG003 "スパンモデルシグナル配信"
#define MSG004 "スーパーボリンジャーシグナル配信"
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
      si[i].IsSent=false;      //コメント初期化
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
      CheckSpanModelSignal(si[i].sSymbol,si[i].iSignal,si[i].dtSignalOn,si[i].IsSent);
      //シグナル未配信の場合
      if(!si[i].IsSent)
        {
         //スパンモデルシグナル配信中
         sMessage=sMessage+si[i].sSymbol+" "+MSG001+rtnCode;
         //シグナル配信
         SendSignal(si[i].sSymbol,si[i].iSignal,si[i].dtSignalOn,si[i].IsSent);
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
//| スーパーボリンジャーシグナル配信                                             |
//+------------------------------------------------------------------+
void SendSignal_SuperBolinger(string inSymbol)
  {
//配信制限
   if(iVolume(NULL,PERIOD_H1,0)!=1) return;
   double dClose=iClose(inSymbol,PERIOD_H1,1);
   double dPlus2Sigma = iBands(inSymbol,PERIOD_H1,21,2,0,PRICE_CLOSE,1,1);
   double dMnus2Sigma = iBands(inSymbol,PERIOD_H1,21,2,0,PRICE_CLOSE,2,1);
//終値がボリンジャーバンドのプラス２シグマラインを上回った場合
   if(dClose>dPlus2Sigma)
     {
      //シグナル配信
      string sMessage=MSG004;
      sMessage=sMessage+rtnCode+"通貨："+inSymbol;
      sMessage=sMessage+rtnCode+"プラス２シグマライン上回る";
      SendNotification(sMessage);
      Print(sMessage);
     }
//終値がボリンジャーバンドのマイナス２シグマラインを下回った場合
   if(dClose>dPlus2Sigma)
     {
      //シグナル配信
      string sMessage=MSG004;
      sMessage=sMessage+rtnCode+"通貨："+inSymbol;
      sMessage=sMessage+rtnCode+"マイナス２シグマライン下回る";
      SendNotification(sMessage);
      Print(sMessage);
     }
  }
//+------------------------------------------------------------------+
//| スパンモデルシグナルチェック                                             |
//+------------------------------------------------------------------+
void CheckSpanModelSignal(string inSymbol,int &ioSignal,datetime &ioTimeSignalOn,bool &ioIsSent)
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
      ioTimeSignalOn=iTime(inSymbol,PERIOD_CURRENT,1);
      ioIsSent=false;
     }
//売りシグナルのとき
   if(dPreBlueSpan>dPreRedSpan && dBlueSpan<=dRedSpan)
     {
      ioSignal=SIGNALSELL;
      ioTimeSignalOn=iTime(inSymbol,PERIOD_CURRENT,1);
      ioIsSent=false;
     }
  }
//+------------------------------------------------------------------+
//| シグナル配信                                             |
//+------------------------------------------------------------------+
void SendSignal(string inSymbol,int inSignal,datetime &ioTimeSignalOn,bool &ioIsSent)
  {
//シグナル点灯時のバーの位置取得
   int iSignalOnBarNo=iBarShift(inSymbol,PERIOD_CURRENT,ioTimeSignalOn);
//遅行スパンシグナル点灯チェック
   int iHighestBarNo=iHighest(inSymbol,PERIOD_CURRENT,MODE_HIGH,iSignalOnBarNo,2);
   double dHigh=iHigh(inSymbol,PERIOD_CURRENT,iHighestBarNo);
   int iLowestBarNo=iLowest(inSymbol,PERIOD_CURRENT,MODE_LOW,iSignalOnBarNo,2);
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
         //配信終了
         if(iSignalOnBarNo<26) ioIsSent=true;
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
         //配信終了
         if(iSignalOnBarNo<26) ioIsSent=true;
        }
     }
  }
//+------------------------------------------------------------------+
