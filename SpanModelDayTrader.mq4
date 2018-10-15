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
bool IsSearchPosition_Magic2=false;
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
   int glbMagicNo2=1002;

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
            IsSearchPosition_Magic2=true;
           }
         break;
        }
     }

//ポジション情報取得
   int iTiketNo_Magic1=GetTicketNo(glbMagicNo1);
   int iTiketNo_Magic2=GetTicketNo(glbMagicNo2);
   string sMessage1=OrderSymbol()+" "+(string)glbMagicNo1;
   string sMessage2=OrderSymbol()+" "+(string)glbMagicNo2;

//金曜のPM23:00に取引終了
   if(DayOfWeek()>4 && TimeHour(TimeCurrent())>22)
     {
      ClosePosition(iTiketNo_Magic1);
      ClosePosition(iTiketNo_Magic2);
      Comment("取引終了");
      InitGlobals();
      return;
     }

//ポジションがある場合、ポジション検索を終了
   if(iTiketNo_Magic1!=-1) IsSearchPosition_Magic1=false;
   if(iTiketNo_Magic2!=-1) IsSearchPosition_Magic2=false;

//ポジション保持中の場合
   if(iTiketNo_Magic1!=-1)
     {
      //損切り
      OutMessage=OutMessage+sMessage1+" "+LossCut(iTiketNo_Magic1)+rtnCode;
      //利益確定
      OutMessage=OutMessage+sMessage1+" "+TakeProfit(iTiketNo_Magic1)+rtnCode;;
     }
   if(iTiketNo_Magic2!=-1)
     {
      //損切り
      OutMessage=OutMessage+sMessage2+" "+LossCut(iTiketNo_Magic2)+rtnCode;
      //利益確定
      OutMessage=OutMessage+sMessage2+" "+TakeProfit(iTiketNo_Magic2)+rtnCode;;
     }

//ポジション検索
   if(IsSearchPosition_Magic1)
     {
      if(iTiketNo_Magic1==-1)
        {
         OutMessage=OutMessage+sMessage1+" "+"ポジション待機中"+rtnCode;
         double dPlus1Sigma=iBands(OrderSymbol(),PERIOD_M5,21,1,0,PRICE_CLOSE,1,0);
         double dMnus1Sigma=iBands(OrderSymbol(),PERIOD_M5,21,1,0,PRICE_CLOSE,2,0);
         ChangeOrderPrice(dPlus1Sigma,dMnus1Sigma,glbMagicNo1);
        }
     }
   if(IsSearchPosition_Magic2)
     {
      if(iTiketNo_Magic2==-1)
        {
         OutMessage=OutMessage+sMessage2+" "+"ポジション待機中"+rtnCode;
         double dBlueSpan=iIchimoku(OrderSymbol(),PERIOD_M5,9,26,52,3,-26);
         ChangeOrderPrice(dBlueSpan,dBlueSpan,glbMagicNo2);
        }
     }

//コメント表示
   Comment(OutMessage);

//スパンモデルシグナル配信
   if(TimeHour(TimeLocal())<18) return;
   if(iTiketNo_Magic1!=-1) return;
   if(iTiketNo_Magic2!=-1) return;
   Comment("スパンモデルシグナル配信中");
   if(iVolume(OrderSymbol(),PERIOD_M5,0)!=1) return;
   for(int i=0; i<ArraySize(Symbols); i++)
     {
      //スパンモデルシグナル配信
      SpanModelSignalDistribute(Symbols[i]);
     }
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
   IsSearchPosition_Magic2=false;
  }
//+------------------------------------------------------------------+
// スパンモデルシグナル配信
//+------------------------------------------------------------------+
void SpanModelSignalDistribute(string inSymbol)
  {
   int iDigits=(int)MarketInfo(inSymbol,MODE_DIGITS);
   double dPreBlueSpan=iIchimoku(inSymbol,PERIOD_M5,9,26,52,3,-24);
   double dBlueSpan=iIchimoku(inSymbol,PERIOD_M5,9,26,52,3,-25);
   double dPreRedSpan=iIchimoku(inSymbol,PERIOD_M5,9,26,52,4,-24);
   double dRedSpan=iIchimoku(inSymbol,PERIOD_M5,9,26,52,4,-25);
   double dClose=iClose(inSymbol,PERIOD_M5,1);

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
// 損切り
//+------------------------------------------------------------------+
string LossCut(int iTicketNo)
  {
//オーダー情報取得
   bool IsSelect=OrderSelect(iTicketNo,SELECT_BY_TICKET);
   if(!IsSelect) return NULL;

   string OutMessage=NULL;
   bool CloseFlg=false;
   double dCloseRate=0;
   string sLossCutMessage=NULL;
   int iDigits=(int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   double dPoint=MarketInfo(OrderSymbol(),MODE_POINT);
   int iOpenBarNo=iBarShift(OrderSymbol(),PERIOD_H1,OrderOpenTime())+1;
   double dSimpleMa=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,iOpenBarNo);
   double dPlus1Sigma=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,iOpenBarNo);
   double dPlus2Sigma=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,iOpenBarNo);
   double dPlus3Sigma=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,1,iOpenBarNo);
   double dMnus1Sigma=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,iOpenBarNo);
   double dMnus2Sigma=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,iOpenBarNo);
   double dMnus3Sigma=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,iOpenBarNo);
   double dOpenPrice=iClose(OrderSymbol(),PERIOD_H1,iOpenBarNo);

//買いポジションの場合
   if(OrderType()==OP_BUY)
     {
//      double dOpenPrice=OrderOpenPrice()-100*dPoint;

      //ポジションオープン価格-10pips	がプラス2シグマより大きいとき
      if(dOpenPrice>dPlus2Sigma)
        {
         //損切りはプラス1シグマライン
         sLossCutMessage="プラス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,1);
        }
      //ポジションオープン価格-10pips	がプラス1シグマより大きいとき
      else if(dOpenPrice>dPlus1Sigma)
        {
         //損切りは移動平均線
         sLossCutMessage="移動平均線";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,1);
        }
      //ポジションオープン価格-10pips	が移動平均線より大きいとき
      else if(dOpenPrice>dSimpleMa)
        {
         //損切りはマイナス1シグマライン
         sLossCutMessage="マイナス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,1);
        }
      //ポジションオープン価格-10pips	がマイナス1シグマより大きいとき
      else if(dOpenPrice>dMnus1Sigma)
        {
         //損切りはマイナス2シグマライン
         sLossCutMessage="マイナス2シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,1);
        }
      //ポジションオープン価格-10pips	がマイナス2シグマより大きいとき
      else
        {
         //損切りはマイナス3シグマライン
         sLossCutMessage="マイナス3シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,1);
        }
      if(iClose(OrderSymbol(),PERIOD_H1,1)<dCloseRate) CloseFlg=true;
     }

//売りポジションの場合
   if(OrderType()==OP_SELL)
     {
//      double dOpenPrice=OrderOpenPrice()+100*dPoint;

      //ポジションオープン価格+10pips	がマイナス2シグマ未満のとき
      if(dOpenPrice<dMnus2Sigma)
        {
         //損切りはマイナス1シグマライン
         sLossCutMessage="マイナス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,1);
        }
      //ポジションオープン価格+10pips	がマイナス1シグマ未満のとき
      else if(dOpenPrice<dMnus1Sigma)
        {
         //損切りは移動平均線
         sLossCutMessage="移動平均線";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,1);
        }
      //ポジションオープン価格+10pips	が移動平均線未満のとき
      else if(dOpenPrice<dSimpleMa)
        {
         //損切りはプラス1シグマライン
         sLossCutMessage="プラス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,1);
        }
      //ポジションオープン価格+10pips	がプラス1シグマ未満のとき
      else if(dOpenPrice<dPlus1Sigma)
        {
         //損切りはプラス2シグマライン
         sLossCutMessage="プラス2シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,1);
        }
      //ポジションオープン価格+10pips	がプラス2シグマ未満のとき
      else
        {
         //損切りはプラス3シグマライン
         sLossCutMessage="プラス3シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,1,1);
        }
      if(iClose(OrderSymbol(),PERIOD_H1,1)>dCloseRate && dCloseRate>=OrderOpenPrice()) CloseFlg=true;
     }
   OutMessage="損切"+" "+DoubleToString(NormalizeDouble(dCloseRate,iDigits))+"（"+sLossCutMessage+"）";

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
   int iOpenBarNo=iBarShift(OrderSymbol(),PERIOD_H1,OrderOpenTime());
   double dSimpleMa=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,iOpenBarNo);
   double dPlus1Sigma=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,iOpenBarNo);
   double dPlus2Sigma=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,iOpenBarNo);
   double dPlus3Sigma=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,1,iOpenBarNo);
   double dMnus1Sigma=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,iOpenBarNo);
   double dMnus2Sigma=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,iOpenBarNo);
   double dMnus3Sigma=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,iOpenBarNo);

//買いポジションの場合
   if(OrderType()==OP_BUY)
     {
      double dBid=MarketInfo(OrderSymbol(),MODE_BID);
      double dOpenPrice=OrderOpenPrice()+100*dPoint;

      //ポジションオープン価格+10pips	がマイナス2シグマ未満のとき
      if(dOpenPrice<dMnus2Sigma)
        {
         //利益確定はマイナス2シグマライン
         sTakeProfitMessage="マイナス2シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,0);
        }
      //ポジションオープン価格+10pips	がマイナス1シグマ未満のとき
      else if(dOpenPrice<dMnus1Sigma)
        {
         //利益確定はマイナス1シグマライン
         sTakeProfitMessage="マイナス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,0);
        }
      //ポジションオープン価格+10pips	が移動平均線未満のとき
      else if(dOpenPrice<dSimpleMa)
        {
         //利益確定は移動平均線
         sTakeProfitMessage="移動平均線";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,0);
        }
      //ポジションオープン価格+10pips	がプラス1シグマ未満のとき
      else if(dOpenPrice<dPlus1Sigma)
        {
         //利益確定はプラス1シグマライン
         sTakeProfitMessage="プラス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,0);
        }
      //ポジションオープン価格+10pips	がプラス2シグマ未満のとき
      else if(dOpenPrice<dPlus2Sigma)
        {
         //利益確定はプラス2シグマライン
         sTakeProfitMessage="プラス2シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,0);
        }
      //ポジションオープン価格+10pips	がプラス3シグマ未満のとき
      else
        {
         //利益確定はプラス3シグマライン
         sTakeProfitMessage="プラス3シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,1,0);
        }
      if(dBid>dCloseRate && dCloseRate>=OrderOpenPrice()) CloseFlg=true;
     }

//売りポジションの場合
   if(OrderType()==OP_SELL)
     {
      double dAsk=MarketInfo(OrderSymbol(),MODE_ASK);
      double dOpenPrice=OrderOpenPrice()-100*dPoint;

      //ポジションオープン価格-10pips	がプラス2シグマより大きいとき
      if(dOpenPrice>dPlus2Sigma)
        {
         //利益確定はプラス2シグマライン
         sTakeProfitMessage="プラス2シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,1,0);
        }
      //ポジションオープン価格-10pips	がプラス1シグマより大きいとき
      else if(dOpenPrice>dPlus1Sigma)
        {
         //利益確定はプラス1シグマライン
         sTakeProfitMessage="プラス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,1,0);
        }
      //ポジションオープン価格-10pips	が移動平均線より大きいとき
      else if(dOpenPrice>dSimpleMa)
        {
         //利益確定は移動平均線
         sTakeProfitMessage="移動平均線";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,0,0,PRICE_CLOSE,0,0);
        }

      //ポジションオープン価格-10pips	がマイナス1シグマより大きいとき
      else if(dOpenPrice>dMnus1Sigma)
        {
         //利益確定はマイナス1シグマライン
         sTakeProfitMessage="マイナス1シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,1,0,PRICE_CLOSE,2,0);
        }
      //ポジションオープン価格-10pips	がマイナス2シグマより大きいとき
      else if(dOpenPrice>dMnus2Sigma)
        {
         //利益確定はマイナス2シグマライン
         sTakeProfitMessage="マイナス2シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,2,0,PRICE_CLOSE,2,0);
        }
      //ポジションオープン価格-10pips	がマイナス3シグマより大きいとき
      else
        {
         //利益確定はマイナス3シグマライン
         sTakeProfitMessage="マイナス3シグマライン";
         dCloseRate=iBands(OrderSymbol(),PERIOD_H1,21,3,0,PRICE_CLOSE,2,0);
        }
      if(dAsk<dCloseRate) CloseFlg=true;
     }
   OutMessage="利確"+" "+DoubleToString(NormalizeDouble(dCloseRate,iDigits))+"（"+sTakeProfitMessage+"）";

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
