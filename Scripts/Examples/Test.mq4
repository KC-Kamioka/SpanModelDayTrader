//+------------------------------------------------------------------+
//|                                                         Test.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   bool IsSelect=false;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      IsSelect=OrderSelect(i,SELECT_BY_POS);
      if(IsSelect) break;
     }
   double dCloseRate=0;
   int iDigits=(int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   string sTakeProfitMessage=NULL;
   double dPoint=MarketInfo(OrderSymbol(),MODE_POINT);
   double dAsk=MarketInfo(OrderSymbol(),MODE_ASK);
   double dOpenPrice=OrderOpenPrice()-200*dPoint;
   int iOpenBarNo=iBarShift(OrderSymbol(),PERIOD_M5,OrderOpenTime());
   double dMnus1Sigma=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,iOpenBarNo);
   double dMnus2Sigma=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,iOpenBarNo);
   double dMnus3Sigma=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,iOpenBarNo);
   double dSimpleMa=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,iOpenBarNo);
   double dPlus1Sigma=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,iOpenBarNo);
   double dPlus2Sigma=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,iOpenBarNo);
   double dPlus3Sigma=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,1,iOpenBarNo);
//ポジションオープン価格-10pips	がプラス2シグマより大きいとき
   if(dOpenPrice>dPlus2Sigma)
     {
      //利益確定はプラス2シグマライン
      sTakeProfitMessage="利益確定はプラス2シグマライン";
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,0);
     }
//ポジションオープン価格-10pips	がプラス1シグマより大きいとき
   else if(dOpenPrice>dPlus1Sigma)
     {
      //利益確定はプラス1シグマライン
      sTakeProfitMessage="利益確定はプラス1シグマライン";
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,0);
     }
//ポジションオープン価格-10pips	が移動平均線より大きいとき
   else if(dOpenPrice>dSimpleMa)
     {
      //利益確定は移動平均線
      sTakeProfitMessage="利益確定は移動平均線";
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,0);
     }

//ポジションオープン価格-10pips	がマイナス1シグマより大きいとき
   else if(dOpenPrice>dMnus1Sigma)
     {
      //利益確定はマイナス1シグマライン
      sTakeProfitMessage="利益確定はマイナス1シグマライン";
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,0);
     }
//ポジションオープン価格-10pips	がマイナス2シグマより大きいとき
   else if(dOpenPrice>dMnus2Sigma)
     {
      //利益確定はマイナス2シグマライン
      sTakeProfitMessage="利益確定はマイナス2シグマライン";
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,0);
     }
//ポジションオープン価格-10pips	がマイナス3シグマより大きいとき
   else
     {
      //利益確定はマイナス3シグマライン
      sTakeProfitMessage="利益確定はマイナス3シグマライン";
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,0);
     }
   Print(OrderSymbol()+" "+sTakeProfitMessage+":"+DoubleToString(NormalizeDouble(dCloseRate,iDigits)));
   Print("dAsk"+" "+DoubleToString(dAsk));
   Print("dOpenPrice"+" "+DoubleToString(dOpenPrice));
   Print("dCloseRate"+" "+DoubleToString(dCloseRate));
  }
//+------------------------------------------------------------------+
