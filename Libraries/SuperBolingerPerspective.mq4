//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Common.mqh>
#define COM0000    "シグナル継続数"
#define COM0001    "レンジ相場"
#define COM0002    "緩やかな上昇トレンド"
#define COM0003    "本格的上昇トレンド"
#define COM0004    "調整反落局面"
#define COM0012    "緩やかな下落トレンド"
#define COM0013    "本格的下落トレンド"
#define COM0014    "反転上昇局面"
int gblUpperChartPeriod;
//+------------------------------------------------------------------+
//| 大局観取得                                                      |
//+------------------------------------------------------------------+
int GetSignalPerspective(int UpperChartPeriod) export
  {
   Print("【大局観】シグナルチェック開始");
   gblUpperChartPeriod=UpperChartPeriod;
   int DelayedSpanSignal=NOSIGNAL;
   int iRtnTradeSignal=NOSIGNAL;
   string sMessage=NULL;

//現在の遅行スパンシグナル取得
   double HighestRate=iHigh(NULL,gblUpperChartPeriod,21);
   double LowestRate=iLow(NULL,gblUpperChartPeriod,21);
//遅行スパンが高値より上にある時
   if(HighestRate<iClose(NULL,gblUpperChartPeriod,1))
     {
      DelayedSpanSignal=SIGNALBUY;
     }
//遅行スパンが安値より下にある時
   if(LowestRate>iClose(NULL,gblUpperChartPeriod,1))
     {
      DelayedSpanSignal=SIGNALSELL;
     }

//遅行スパンシグナル消灯中の場合
   if(DelayedSpanSignal==NOSIGNAL)
     {
      //レンジ相場
      Print(COM0001);
      Comment(COM0001);
      return NOSIGNAL;
     }

//遅行スパン交差チェック
   int nBarNo=1;
   double Candle=0;
   do
     {
      //買いシグナル点灯中
      if(DelayedSpanSignal==SIGNALBUY)
        {
         //遅行スパンがローソク足を下回った場合
         Candle=iLow(NULL,gblUpperChartPeriod,nBarNo+21);
         if(iClose(NULL,gblUpperChartPeriod,nBarNo)<Candle)
           {
            Print(TimeToString(iTime(NULL,gblUpperChartPeriod,nBarNo))+" "+"遅行スパンクロス（上抜け）");
            DelayedSpanSignal=NOSIGNAL;
           }
        }
      //売りシグナル点灯中
      if(DelayedSpanSignal==SIGNALSELL)
        {
         //遅行スパンがローソク足を上回った場合
         Candle=iHigh(NULL,gblUpperChartPeriod,nBarNo+21);
         if(iClose(NULL,gblUpperChartPeriod,nBarNo)>Candle)
           {
            Print(TimeToString(iTime(NULL,gblUpperChartPeriod,nBarNo))+" "+"遅行スパンクロス（下抜け）");
            DelayedSpanSignal=NOSIGNAL;
           }
        }
      nBarNo=nBarNo+1;
     }
   while(DelayedSpanSignal!=NOSIGNAL);

//遅行スパンシグナル点灯チェック
   do
     {
      //シグナル消灯中
      if(DelayedSpanSignal==NOSIGNAL)
        {
         DelayedSpanSignal=GetSignalDelayedSpanBreak(nBarNo);
        }
      nBarNo=nBarNo-1;
     }
   while(nBarNo>0 && DelayedSpanSignal==NOSIGNAL);

//遅行スパンシグナル消灯チェック
   int SignalCount=0;
   do
     {
      double CloseRate=iClose(NULL,gblUpperChartPeriod,nBarNo);
      double SimpleMA=iBands(NULL,gblUpperChartPeriod,21,0,0,PRICE_CLOSE,0,nBarNo);
      double Plus1Sigma=iBands(NULL,gblUpperChartPeriod,21,1,0,PRICE_CLOSE,1,nBarNo);
      double Plus2Sigma=iBands(NULL,gblUpperChartPeriod,21,2,0,PRICE_CLOSE,1,nBarNo);
      double Plus3Sigma=iBands(NULL,gblUpperChartPeriod,21,3,0,PRICE_CLOSE,1,nBarNo);
      double Mnus1Sigma=iBands(NULL,gblUpperChartPeriod,21,1,0,PRICE_CLOSE,2,nBarNo);
      double Mnus2Sigma=iBands(NULL,gblUpperChartPeriod,21,2,0,PRICE_CLOSE,2,nBarNo);
      double Mnus3Sigma=iBands(NULL,gblUpperChartPeriod,21,3,0,PRICE_CLOSE,2,nBarNo);

      //遅行スパン買いシグナル点灯中
      if(DelayedSpanSignal==SIGNALBUY)
        {
         //終値がプラス1シグマラインより大きく、プラス2シグマライン以下の場合
         if(CloseRate>Plus1Sigma && CloseRate<=Plus2Sigma)
           {
            //緩やかな上昇トレンド
            sMessage=COM0002;
            iRtnTradeSignal=SIGNALBUY;
           }
         //終値がプラス2シグマラインより大きい場合
         if(CloseRate>Plus2Sigma)
           {
            //本格的上昇トレンド
            sMessage=COM0003;
            iRtnTradeSignal=SIGNALBUY;
           }
         //終値がプラス1シグマライン以下で、移動平均線より大きい場合
         if(CloseRate<=Plus1Sigma && CloseRate>SimpleMA)
           {
            //プラス3シグマラインが下向きに転換
            double PrePlus3Sigma=iBands(NULL,gblUpperChartPeriod,21,3,0,PRICE_CLOSE,1,nBarNo+1);
            if(PrePlus3Sigma>Plus3Sigma)
              {
               //シグナル継続数が9回を上回った場合
               if(SignalCount>9)
                 {
                  //調整反落局面
                  sMessage=COM0004;
                  iRtnTradeSignal=SIGNALSELL;
                 }
               //シグナル継続数が9回未満の場合
               else
                 {
                  //緩やかな上昇トレンド
                  sMessage=COM0002;
                  iRtnTradeSignal=SIGNALBUY;
                 }
              }
            else
              {
               //緩やかな上昇トレンド
               sMessage=COM0002;
               iRtnTradeSignal=SIGNALBUY;
              }
           }
         //終値が移動平均線以下の場合
         if(CloseRate<=SimpleMA)
           {
            //調整反落局面
            sMessage=COM0004;
            iRtnTradeSignal=SIGNALSELL;
           }
        }

      //遅行スパン売りシグナル点灯中
      if(DelayedSpanSignal==SIGNALSELL)
        {
         //終値がマイナス1シグマラインより小さく、マイナス2シグマライン以上の場合
         if(CloseRate<Mnus1Sigma && CloseRate>=Mnus2Sigma)
           {
            //緩やかな下降トレンド
            sMessage=COM0012;
            iRtnTradeSignal=SIGNALSELL;
           }
         //終値がマイナス2シグマラインより小さい場合
         if(CloseRate<Mnus2Sigma)
           {
            //本格的下降トレンド
            sMessage=COM0013;
            iRtnTradeSignal=SIGNALSELL;
           }
         //終値がマイナス1シグマライン以上で、移動平均線より小さい場合
         if(CloseRate>=Mnus1Sigma && CloseRate<SimpleMA)
           {
            //マイナス3シグマラインが上向きに転換
            double PreMnus3Sigma=iBands(NULL,gblUpperChartPeriod,21,3,0,PRICE_CLOSE,1,nBarNo+1);
            if(PreMnus3Sigma<Mnus3Sigma)
              {
               //シグナル継続数が9回を上回った場合
               if(SignalCount>9)
                 {
                  //反転上昇局面
                  sMessage=COM0014;
                  iRtnTradeSignal=SIGNALBUY;
                 }
               //シグナル継続数が9回未満の場合
               else
                 {
                  //緩やかな下降トレンド
                  sMessage=COM0012;
                  iRtnTradeSignal=SIGNALSELL;
                 }
              }
            else
              {
               //緩やかな下降トレンド
               sMessage=COM0012;
               iRtnTradeSignal=SIGNALSELL;
              }
           }
         //終値が移動平均線以上の場合
         if(CloseRate>=SimpleMA)
           {
            //反転上昇局面
            sMessage=COM0014;
            iRtnTradeSignal=SIGNALSELL;
           }
        }
      //シグナル点灯中
      if(DelayedSpanSignal!=NOSIGNAL)
        {
         //シグナル継続数カウントアップ
         SignalCount=SignalCount+1;
        }
      nBarNo=nBarNo-1;
     }
   while(nBarNo>0);

//遅行スパンシグナル消灯中の場合
   if(DelayedSpanSignal==NOSIGNAL)
     {
      //レンジ相場
      Print(COM0001);
      Comment(COM0001);
      return NOSIGNAL;
     }

   sMessage=sMessage+"("+COM0000+":["+IntegerToString(SignalCount)+"])";
   Print(sMessage);
   Comment(sMessage);
   Print("【大局観】シグナルチェック終了");
   return iRtnTradeSignal;
  }
//+------------------------------------------------------------------+
//| 大局観取得                                                      |
//+------------------------------------------------------------------+
int GetSignalDelayedSpanBreak(int nBarNo) export
  {
//遅行スパンブレイク判定（上昇）
   int HighestBarNo=iHighest(NULL,gblUpperChartPeriod,MODE_CLOSE,21,nBarNo+1);
   double PreHighestRate=iHigh(NULL,gblUpperChartPeriod,HighestBarNo+1);
   double HighestRate=iHigh(NULL,gblUpperChartPeriod,HighestBarNo);
   if(HighestRate<iClose(NULL,gblUpperChartPeriod,nBarNo))
     {
      Print(TimeToString(iTime(NULL,gblUpperChartPeriod,nBarNo))+" "+"遅行スパン買いシグナル点灯");
      return SIGNALBUY;
     }

//遅行スパンブレイク判定（下降）
   int LowestBarNo=iLowest(NULL,gblUpperChartPeriod,MODE_CLOSE,21,nBarNo+1);
   double PreLowestRate=iLow(NULL,gblUpperChartPeriod,LowestBarNo+1);
   double LowestRate=iLow(NULL,gblUpperChartPeriod,LowestBarNo);
   if(LowestRate>iClose(NULL,gblUpperChartPeriod,nBarNo))
     {
      Print(TimeToString(iTime(NULL,gblUpperChartPeriod,nBarNo))+" "+"遅行スパン売りシグナル点灯");
      return SIGNALSELL;
     }
   return NOSIGNAL;
  }
//+------------------------------------------------------------------+
