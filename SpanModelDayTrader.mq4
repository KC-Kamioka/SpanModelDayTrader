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
   Comment("");
   InitGlobals();
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
   if(TestMode)
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
     }

//オーダー情報取得
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

//コメント表示
   Comment(OutMessage);

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
// 損切り(スパンモデル)
//+------------------------------------------------------------------
string LossCut_SpanModel(int iTicketNo)
  {
//オーダー情報取得
   bool IsSelect=OrderSelect(iTicketNo,SELECT_BY_TICKET);
   if(!IsSelect) return NULL;

   string OutMessage=NULL;
   bool CloseFlg=false;
   string sLossCutMessage="青色スパン";
   int iDigits=(int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   double dPreRedSpan=iIchimoku(OrderSymbol(),PERIOD_CURRENT,9,26,52,3,-24);
   double dRedSpan=iIchimoku(OrderSymbol(),PERIOD_CURRENT,9,26,52,3,-25);
   double dPreClose=iClose(OrderSymbol(),PERIOD_CURRENT,2);
   double dClose=iClose(OrderSymbol(),PERIOD_CURRENT,1);

//損切待機
   int iOpenBarNo=iBarShift(OrderSymbol(),PERIOD_CURRENT,OrderOpenTime());
   if(iOpenBarNo<5) return "損切待機中";

//買いポジションの場合
   if(OrderType()==OP_BUY)
     {
      //ポジションクローズ判定
      if(dPreRedSpan<dPreClose && dRedSpan>=dClose) CloseFlg=true;
     }

//売りポジションの場合
   if(OrderType()==OP_SELL)
     {
      //ポジションクローズ判定
      if(dPreRedSpan>dPreClose && dRedSpan<=dClose) CloseFlg=true;
     }
   OutMessage="損切"+" "+DoubleToString(NormalizeDouble(dRedSpan,iDigits))+"（"+sLossCutMessage+"）";

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
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,1,0);
      if(dBid>dCloseRate && dCloseRate>=OrderOpenPrice()) CloseFlg=true;
     }

//売りポジションの場合
   if(OrderType()==OP_SELL)
     {
      //利益確定はマイナス3シグマライン
      sTakeProfitMessage="マイナス3シグマライン";
      double dAsk=MarketInfo(OrderSymbol(),MODE_ASK);
      dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,0);
      if(dAsk<dCloseRate) CloseFlg=true;
     }
   OutMessage="利確"+" "+DoubleToString(NormalizeDouble(dCloseRate,iDigits))+"（"+sTakeProfitMessage+"）";

//ポジションクローズ
   if(CloseFlg==true)
     {
      //ポジション検索再開
      IsSearchPosition_Magic1=true;
      ClosePosition(iTicketNo);
      Print(OutMessage);
      InitGlobals();
     }
   return OutMessage;
  }
//+------------------------------------------------------------------+
// 全ポジションクローズ
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
