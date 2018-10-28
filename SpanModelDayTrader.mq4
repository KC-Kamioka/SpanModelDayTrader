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
//| グローバル変数
//+------------------------------------------------------------------+
bool IsSearchPosition_Magic1=false;
extern bool TestMode=false;
extern bool TestType_BUYLIMIT=true;
extern datetime TestDatetime=D'2018.10.01 00:00';
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
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
   string OutMessage=NULL;
   int glbMagicNo1=1001;

//テストモード
   if(TestMode) TestOrder();

//オーダー受付
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      bool IsSelect=OrderSelect(i,SELECT_BY_POS);
      if(IsSelect)
        {
         //指値注文の場合、キャンセル
         if(OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)
           {
            //指値注文キャンセル
            bool IsDelete=OrderDelete(OrderTicket());
            if(!IsDelete)
              {
               ErrorHandle();
               return;
              }
            IsSearchPosition_Magic1=true;
           }
         break;
        }
     }

//チャート制御
   ChartControl();

//ポジション情報取得
   int iTiketNo_Magic1=GetTicketNo(glbMagicNo1);
   string sMessage1=OrderSymbol()+" "+(string)glbMagicNo1;

//金曜のPM23:00に取引終了
   if(DayOfWeek()>4 && TimeHour(TimeCurrent())>22)
     {
      ClosePosition(iTiketNo_Magic1);
      Comment("取引終了");
      InitGlobals();
      return;
     }

//ポジションがある場合、ポジション検索を終了
   if(iTiketNo_Magic1!=-1) IsSearchPosition_Magic1=false;

//ポジション保持中の場合
   if(iTiketNo_Magic1!=-1)
     {
      //トレーリングストップ
      OutMessage=OutMessage+sMessage1+" "+TrailingStop(iTiketNo_Magic1,50)+rtnCode;
      //損切り
      OutMessage=OutMessage+sMessage1+" "+LossCut_SpanModel(iTiketNo_Magic1)+rtnCode;
      //利益確定
      OutMessage=OutMessage+sMessage1+" "+TakeProfit(iTiketNo_Magic1)+rtnCode;;
     }

//ポジション検索
   if(IsSearchPosition_Magic1)
     {
      if(iTiketNo_Magic1==-1)
        {
         OutMessage=OutMessage+sMessage1+" "+"ポジション待機中"+rtnCode;
         double dPlus1Sigma=iBands(OrderSymbol(),PERIOD_CURRENT,21,1,0,PRICE_CLOSE,1,0);
         double dMnus1Sigma=iBands(OrderSymbol(),PERIOD_CURRENT,21,1,0,PRICE_CLOSE,2,0);
         ChangeOrderPrice(dPlus1Sigma,dMnus1Sigma,glbMagicNo1);
        }
     }

//スパンモデルシグナル配信
   if(TimeHour(TimeLocal())<18) return;
   if(iTiketNo_Magic1!=-1) return;
   Comment("スパンモデルシグナル配信中");
   if(iVolume(OrderSymbol(),PERIOD_CURRENT,0)!=1) return;
   SpanModelSignalDistribute(Symbol());

//コメント表示
   Comment(OutMessage);
  }
//+------------------------------------------------------------------+
// トレーリングストップ
//+------------------------------------------------------------------+
string TrailingStop(int inTicketNo,int inPoint)
  {
//オーダー情報取得
   bool IsSelect=OrderSelect(inTicketNo,SELECT_BY_TICKET);
   if(!IsSelect) return NULL;

   int iDigits=(int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   double dAsk=MarketInfo(OrderSymbol(),MODE_ASK);
   double dBid=MarketInfo(OrderSymbol(),MODE_BID);
   double dPoint=MarketInfo(OrderSymbol(),MODE_POINT);
   double tr_stop=0;

//トレーリングストップ
   if(OrderType()==OP_BUY)
     {
      tr_stop=dBid-inPoint*dPoint;
      if(NormalizeDouble(OrderStopLoss(),iDigits)<NormalizeDouble(tr_stop,iDigits))
        {
         bool IsModified=OrderModify(OrderTicket(),OrderOpenPrice(),tr_stop,OrderTakeProfit(),0,Red);
         if(!IsModified)
           {
            ErrorHandle();
            return NULL;
           }
        }
     }
   if(OrderType()==OP_SELL)
     {
      tr_stop=dAsk+inPoint*dPoint;
      if(NormalizeDouble(OrderStopLoss(),iDigits)>NormalizeDouble(tr_stop,iDigits) || OrderStopLoss()==0)
        {
         bool IsModified=OrderModify(OrderTicket(),OrderOpenPrice(),tr_stop,OrderTakeProfit(),0,Red);
         if(!IsModified)
           {
            ErrorHandle();
            return NULL;
           }
        }
     }
   return "トレーリングストップ"+" "+DoubleToString(NormalizeDouble(OrderStopLoss(),iDigits));;
  }
//+------------------------------------------------------------------+
// スパンモデルシグナル配信
//+------------------------------------------------------------------+
void SpanModelSignalDistribute(string inSymbol)
  {
   int iDigits=(int)MarketInfo(inSymbol,MODE_DIGITS);
   double dPreBlueSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,3,-24);
   double dBlueSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,3,-25);
   double dPreRedSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,4,-24);
   double dRedSpan=iIchimoku(inSymbol,PERIOD_CURRENT,9,26,52,4,-25);
   double dClose=iClose(inSymbol,PERIOD_CURRENT,1);

//買いシグナルのとき
   if(dPreBlueSpan<dPreRedSpan && dBlueSpan>=dRedSpan)
     {
      string sMessage="【買】スパンモデルシグナル点灯";
      sMessage = sMessage + rtnCode + "通貨：" + inSymbol;
      sMessage = sMessage + rtnCode + "終値：" + DoubleToString(NormalizeDouble(dClose,iDigits));
      sMessage = sMessage + rtnCode + "赤色スパン：" + DoubleToString(NormalizeDouble(dRedSpan,iDigits));
      SendNotification(sMessage);
     }
//売りシグナルのとき
   if(dPreBlueSpan>dPreRedSpan && dBlueSpan<=dRedSpan)
     {
      string sMessage="【売】スパンモデルシグナル点灯";
      sMessage = sMessage + rtnCode + "通貨：" + inSymbol;
      sMessage = sMessage + rtnCode + "終値：" + DoubleToString(NormalizeDouble(dClose,iDigits));
      sMessage = sMessage + rtnCode + "赤色スパン：" + DoubleToString(NormalizeDouble(dRedSpan,iDigits));
      SendNotification(sMessage);
     }
  }
//+------------------------------------------------------------------+
// チャート制御
//+------------------------------------------------------------------+
void ChartControl()
  {

//注文履歴取得
   bool IsSelect=OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY);
   if(!IsSelect) ErrorHandle();

//別通貨ペアが開いている場合
   if(ChartSymbol(ChartID())!=OrderSymbol())
     {
      //通貨ペア変更
      ChartSetSymbolPeriod(ChartID(),OrderSymbol(),PERIOD_CURRENT);
     }
   return;
  }
//+------------------------------------------------------------------+
// 遅行スパンブレイクチェック
//+------------------------------------------------------------------+
void CheckSBChikoSpanBreak()
  {
   if(TimeHour(TimeLocal())<18) return;
   if(iVolume(NULL,PERIOD_H1,0)!=1) return;
   for(int i=0; i<ArraySize(Symbols); i++)
     {
      //一つ前の遅行スパン
      double dPreChikoSpan=iClose(Symbols[i],PERIOD_H1,2);
      //遅行スパン
      double dChikoSpan=iClose(Symbols[i],PERIOD_H1,1);
      //一つ前の高値
      int iPreHighestBarNo=iHighest(Symbols[i],PERIOD_H1,MODE_HIGH,22,3);
      double dPreHighest=iHigh(Symbols[i],PERIOD_H1,iPreHighestBarNo);
      //高値
      int iHighestBarNo=iHighest(Symbols[i],PERIOD_H1,MODE_HIGH,21,2);
      double dHighest=iHigh(Symbols[i],PERIOD_H1,iHighestBarNo);
      //一つ前の安値
      int iPreLowestBarNo=iLowest(Symbols[i],PERIOD_H1,MODE_LOW,22,3);
      double dPreLowest=iLow(Symbols[i],PERIOD_H1,iPreLowestBarNo);
      //安値
      int iLowestBarNo=iLowest(Symbols[i],PERIOD_H1,MODE_LOW,21,2);
      double dLowest=iLow(Symbols[i],PERIOD_H1,iLowestBarNo);

      //高値の方向にブレイクした場合
      if(dPreChikoSpan<=iPreHighestBarNo && dChikoSpan>iHighestBarNo)
        {
         SendNotification("遅行スパンブレイク"+rtnCode+
                          "通貨:"+Symbols[i]+rtnCode+
                          "方向:上昇");
        }
      //安値の方向にブレイクした場合
      if(dPreChikoSpan>=iPreLowestBarNo && dChikoSpan<iLowestBarNo)
        {
         SendNotification("遅行スパンブレイク"+rtnCode+
                          "通貨:"+Symbols[i]+rtnCode+
                          "方向:下降");
        }
     }
  }
//+------------------------------------------------------------------+
// テスト注文
//+------------------------------------------------------------------+
void TestOrder()
  {
   if(TestDatetime==TimeLocal())
     {
      double dAsk=MarketInfo(NULL,MODE_ASK);
      double dBid=MarketInfo(NULL,MODE_BID);
      double dPoint=MarketInfo(NULL,MODE_POINT);
      int rtnTicketNo=0;
      if(TestType_BUYLIMIT)
        {
         rtnTicketNo=OrderSend(NULL,OP_BUYLIMIT,0.5,dAsk,10,dBid-1000*dPoint,0,NULL,0,0,clrNONE);
        }
      else
        {
         rtnTicketNo=OrderSend(NULL,OP_SELLLIMIT,0.5,dBid,10,dAsk+1000*dPoint,0,NULL,0,0,clrNONE);
        }
      if(rtnTicketNo==-1) ErrorHandle();
     }
   return;
  }
//+------------------------------------------------------------------+
// チケット番号取得
//+------------------------------------------------------------------+
int GetTicketNo(int inMagicNo)
  {
   int iRtn=-1;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      bool IsSelect=OrderSelect(i,SELECT_BY_POS);
      if(!IsSelect) continue;
      if(OrderMagicNumber()==inMagicNo)
        {
         iRtn=OrderTicket();
         break;
        }
     }
   return iRtn;
  }
//+------------------------------------------------------------------+
// グローバル変数初期化
//+------------------------------------------------------------------+
void InitGlobals()
  {
   IsSearchPosition_Magic1=false;
  }
//+------------------------------------------------------------------+
// 損切り(スパンモデル)
//+------------------------------------------------------------------
string LossCut_SpanModel(int iTicketNo)
  {
//オーダー情報取得
   bool IsSelect=OrderSelect(iTicketNo,SELECT_BY_TICKET);
   if(!IsSelect) return NULL;

   string OutMessage=NULL;
   bool CloseFlg=false;
   double dPreSpan=0;
   double dSpan=0;
   string sLossCutMessage=NULL;
   int iDigits=(int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   int iOpenBarNo=iBarShift(OrderSymbol(),PERIOD_CURRENT,OrderOpenTime());
   double dPreClose=iClose(OrderSymbol(),PERIOD_CURRENT,2);
   double dClose=iClose(OrderSymbol(),PERIOD_CURRENT,1);

//損切待機
   if(iOpenBarNo<6) return "損切待機中";

//青色スパンで損切
   if(iOpenBarNo>52)
     {
      sLossCutMessage="青色スパン";
      dPreSpan=iIchimoku(OrderSymbol(),PERIOD_CURRENT,9,26,52,3,-24);
      dSpan=iIchimoku(OrderSymbol(),PERIOD_CURRENT,9,26,52,3,-25);
     }
//赤色スパンで損切
   else
     {
      sLossCutMessage="赤色スパン";
      dPreSpan=iIchimoku(OrderSymbol(),PERIOD_CURRENT,9,26,52,4,-24);
      dSpan=iIchimoku(OrderSymbol(),PERIOD_CURRENT,9,26,52,4,-25);
     }

//買いポジションの場合
   if(OrderType()==OP_BUY)
     {
      //ポジションクローズ判定
      if(dPreSpan<dPreClose && dSpan>=dClose)
        {
         CloseFlg=true;
        }
     }

//売りポジションの場合
   if(OrderType()==OP_SELL)
     {
      //ポジションクローズ判定
      if(dPreSpan>dPreClose && dSpan<=dClose)
        {
         CloseFlg=true;
        }
     }
   OutMessage="損切"+" "+DoubleToString(NormalizeDouble(dSpan,iDigits))+"（"+sLossCutMessage+"）";

//ポジションクローズ
   if(CloseFlg==true)
     {
      ClosePosition(iTicketNo);
      Print(OutMessage);
      InitGlobals();
     }
   return OutMessage;
  }
//+------------------------------------------------------------------+
// 利益確定
//+------------------------------------------------------------------+
string TakeProfit(int iTicketNo)
  {
//オーダー情報取得
   bool IsSelect=OrderSelect(iTicketNo,SELECT_BY_TICKET);
   if(!IsSelect) return NULL;

   string OutMessage=NULL;
   bool CloseFlg=false;
   double dCloseRate=0;
   string sTakeProfitMessage=NULL;
   int iDigits=(int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   double dPoint=MarketInfo(OrderSymbol(),MODE_POINT);

//利確待機
   int iOpenBarNo_M5=iBarShift(OrderSymbol(),PERIOD_CURRENT,OrderOpenTime());
   if(iOpenBarNo_M5<5) return "利確待機中";

//買いポジションの場合
   if(OrderType()==OP_BUY)
     {
      //利益確定はプラス3シグマライン
      sTakeProfitMessage="プラス3シグマライン";
      double dBid=MarketInfo(OrderSymbol(),MODE_BID);
      dCloseRate=iBands(OrderSymbol(),PERIOD_CURRENT,21,3,0,PRICE_CLOSE,1,0);
      if(dBid>dCloseRate && dCloseRate>=OrderOpenPrice()) CloseFlg=true;
     }

//売りポジションの場合
   if(OrderType()==OP_SELL)
     {
      //利益確定はマイナス3シグマライン
      sTakeProfitMessage="マイナス3シグマライン";
      double dAsk=MarketInfo(OrderSymbol(),MODE_ASK);
      dCloseRate=iBands(OrderSymbol(),PERIOD_CURRENT,21,3,0,PRICE_CLOSE,2,0);
      if(dAsk<dCloseRate) CloseFlg=true;
     }
   OutMessage="利確"+" "+DoubleToString(NormalizeDouble(dCloseRate,iDigits))+"（"+sTakeProfitMessage+"）";

//ポジションクローズ
   if(CloseFlg==true)
     {
      ClosePosition(iTicketNo);
      Print(OutMessage);
     }
   return OutMessage;
  }
//+------------------------------------------------------------------+
// ポジションクローズ
//+------------------------------------------------------------------+
void ClosePosition(int iTicketNo)
  {
//オーダー情報取得
   bool IsSelect=OrderSelect(iTicketNo,SELECT_BY_TICKET);
   if(!IsSelect) return;
   bool IsClosed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),Slippage,clrMagenta);
   if(!IsClosed)
     {
      ErrorHandle();
      return;
     }
  }
//+------------------------------------------------------------------+
// 指値変更
//+------------------------------------------------------------------+
void ChangeOrderPrice(double inBuyPrice,double inSellPrice,int inMagicNo)
  {

//注文履歴取得
   bool IsSelect=OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY);
   if(!IsSelect) ErrorHandle();

   double dAsk=MarketInfo(OrderSymbol(),MODE_ASK);
   double dBid=MarketInfo(OrderSymbol(),MODE_BID);
   double dPoint=MarketInfo(OrderSymbol(),MODE_POINT);
//買い注文の場合
   if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT)
     {
      if(dAsk<inBuyPrice)
        {
         int rtnTicketNo=OrderSend(OrderSymbol(),OP_BUY,OrderLots(),dAsk,10,dBid-1000*dPoint,0,NULL,inMagicNo,0,clrBlue);
         if(rtnTicketNo==-1)
           {
            ErrorHandle();
            return;
           }
        }
     }
//売り注文の場合
   if(OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT)
     {
      if(dBid>inSellPrice)
        {
         int rtnTicketNo=OrderSend(OrderSymbol(),OP_SELL,OrderLots(),dBid,10,dAsk+1000*dPoint,0,NULL,inMagicNo,0,clrRed);
         if(rtnTicketNo==-1)
           {
            ErrorHandle();
            return;
           }
        }
     }
  }
//+------------------------------------------------------------------+
// エラーハンドラ
//+------------------------------------------------------------------+
void ErrorHandle()
  {
   int iErrCode=GetLastError();
   string sErrorDescription=ErrorDescription(iErrCode)+"("+IntegerToString(iErrCode)+")";
   SendNotification(sErrorDescription);
   InitGlobals();
  }
//+------------------------------------------------------------------+
