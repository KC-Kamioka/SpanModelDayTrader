//+------------------------------------------------------------------+
//|                                              SpanModelTrader.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| ライブラリ                                                          |
//+------------------------------------------------------------------+
#include <stdlib.mqh>
//+------------------------------------------------------------------+
//| 変数                                                             |
//+------------------------------------------------------------------+;
input bool IsTradeBuy=true; //買いトレード
int TAKEPROFIT;
int STOPLOSS;
int SLIPPAGE;
double LOTCOUNT;
int MAGICNO_DELAYEDSPAN;
int MAGICNO_SPANMODEL;
int MAGICNO_BOLINGER;
static string RETURNCODE="\r\n";
bool TradeStartFlg=false;
string stComment;
//+------------------------------------------------------------------+
//| ログ一覧                                                          |
//+------------------------------------------------------------------+
#define LOGIDNT "-- "
#define LOG0001 "【トレード開始】"
#define LOG0002 "【トレード終了】"
#define LOG0003 "スパンモデルポジションクローズ"
#define LOG0004 "遅行スパンポジションクローズ"
#define LOG0005 "ボリンジャーバンドポジションクローズ"
//+------------------------------------------------------------------+
//| My function                                                      |
//+------------------------------------------------------------------+
// int MyCalculator(int value,int value2) export
//   {
//    return(value+value2);
//   }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("【初期化処理開始】");
//取引情報設定
   string stHeadders[];
   string stResults[];
   bool bRtn=ReadFile("Setting.csv",stHeadders,stResults);
   if(!bRtn)ExpertRemove();
   int Element=0;
   LOTCOUNT=(double)stResults[Element];
   Element=Element+1;
   TAKEPROFIT=(int)stResults[Element];
   Element=Element+1;
   STOPLOSS=(int)stResults[Element];
   Element=Element+1;
   SLIPPAGE=(int)stResults[Element];
   Element=Element+1;
   MAGICNO_DELAYEDSPAN=(int)stResults[Element];
   Element=Element+1;
   MAGICNO_SPANMODEL=(int)stResults[Element];
   Element=Element+1;
   MAGICNO_BOLINGER=(int)stResults[Element];

//コメント作成
   if(IsTradeBuy) stComment="買いトレード";
   else stComment="売りトレード";
   stComment=stComment+"【"+Symbol()+"】";
   for(int i=0; i<ArraySize(stHeadders);i++)
     {
      stComment=stComment+RETURNCODE+stHeadders[i]+" = "+stResults[i];
     }

//コメント表示
   Comment(stComment);

//スパンモデルシグナル初期化
   InitSpanModeSignal();
   Print("【初期化処理終了】");

//トレード開始コメント
   if(TradeStartFlg==true)
     {
      Comment("トレード開始");
      Print(LOG0001);
     }

//コメント送信
   SendNotification(stComment);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
//全ポジションクローズ
   PositionCloseAll();
//トレード終了通知
   SendNotification("トレード終了");
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//週末チェック
   if(DayOfWeek()==5 && Hour()>=23)
     {
      //全ポジションクローズ
      PositionCloseAll();
      //トレード終了
      Comment("週末を迎えたため、トレード終了"+"（"+DoubleToString(Close[0])+"）");
      return;
     }

//トレード停止中
   if(TradeStartFlg==false)
     {
      //トレード開始チェック
      if(CheckSpanModel()==false) return;
      TradeStartFlg=true;
      Comment("トレード開始");
      Print(LOG0001);
     }

//スパンモデルポジションがないとき
   if(!IsExistPosition(MAGICNO_SPANMODEL))
     {
      //スパンモデルポジションオープン判定
      if(IsOverRedSpan())
        {
         //スパンモデルポジションオープン
         Print(LOGIDNT+"スパンモデルポジションオープン");
         PositionOpen(MAGICNO_SPANMODEL);
        }
     }
//スパンモデルポジションがあるとき
   else
     {
      //スパンモデルポジションクローズ判定
      if(IsClosedSpanModel())
        {
         //スパンモデルポジションクローズ
         PositionClose(MAGICNO_SPANMODEL);
         Comment("トレード終了"+"（"+DoubleToString(Close[0])+"）");
         Print(LOGIDNT+LOG0003);
         Print(LOG0002);
        }
     }

//遅行スパンポジションがないとき
   if(!IsExistPosition(MAGICNO_DELAYEDSPAN))
     {
      //遅行スパンポジションオープン判定
      if(BreakDelayedSpan())
        {
         //遅行スパンポジションオープン
         Print(LOGIDNT+"遅行スパンポジションオープン");
         PositionOpen(MAGICNO_DELAYEDSPAN);
        }
     }
//遅行スパンポジション保持中
   else
     {
      //ボリンジャーバンドポジションがないとき
      if(!IsExistPosition(MAGICNO_BOLINGER))
        {
         //ボリンジャーバンド判定
         if(IsOpenTouchBolinger2Sigma())
           {
            //ボリンジャーバンドポジションオープン
            Print(LOGIDNT+"ボリンジャーバンドポジションオープン");
            PositionOpen(MAGICNO_BOLINGER);
           }
        }

      //ボリンジャーバンドポジションがあるとき
      else
        {
         //ボリンジャーバンドクローズ判定
         if(IsCloseTouchBolinger2Sigma())
           {
            //ボリンジャーバンドポジションクローズ
            PositionClose(MAGICNO_BOLINGER);
            Print(LOGIDNT+LOG0005);
           }
        }

      //利益確定
      if(IsCloseTakeProfit())
        {
         //遅行スパンポジションクローズ
         if(IsExistPosition(MAGICNO_DELAYEDSPAN))
           {
            Print(LOGIDNT+LOG0004);
            PositionClose(MAGICNO_DELAYEDSPAN);
           }

         //ボリンジャーバンドポジションクローズ
         if(IsExistPosition(MAGICNO_BOLINGER))
           {
            Print(LOGIDNT+LOG0005);
            PositionClose(MAGICNO_BOLINGER);
           }
         //スパンモデルポジションクローズ
         if(IsExistPosition(MAGICNO_SPANMODEL))
           {
            Print(LOGIDNT+LOG0003);
            PositionClose(MAGICNO_SPANMODEL);
           }

         //トレード終了
         TradeStartFlg=false;
         Comment("トレード終了"+"（"+DoubleToString(Close[0])+"）");
         Print(LOG0002+"（利益確定）");
        }

      //遅行スパンシグナル消灯判定
      if(IsCloseDelayedSpan())
        {
         //遅行スパンポジションクローズ
         PositionClose(MAGICNO_DELAYEDSPAN);

         //ボリンジャーバンドポジションクローズ
         PositionClose(MAGICNO_BOLINGER);

         //スパンモデルポジションクローズ
         PositionClose(MAGICNO_SPANMODEL);

         //トレード終了
         TradeStartFlg=false;
         Comment("トレード終了"+"（"+DoubleToString(Close[0])+"）");
         Print(LOGIDNT+"遅行スパンシグナル消灯");
         Print(LOG0002);
        }
     }
  }
//+--------------------------------------------------------------+
//| スパンモデルシグナル初期化                                         |
//+--------------------------------------------------------------+
void InitSpanModeSignal()
  {
   Print(LOGIDNT+"スパンモデルシグナルチェック開始");
//現在のスパンモデルシグナル取得
   double BlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,-25);
   double RedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,-25);
   if(IsTradeBuy)
     {
      //売りシグナル点灯中はチェック終了
      if(BlueSpan<RedSpan) return;
      Print(LOGIDNT+"スパンモデルシグナルチェック終了");
     }
   else
     {
      //買いシグナル点灯中はチェック終了
      if(BlueSpan>RedSpan) return;
      Print(LOGIDNT+"スパンモデルシグナルチェック終了");
     }

//スパンモデルシグナルチェック
   int nBarNo=0;
   do
     {
      nBarNo=nBarNo+1;
      if(CheckSpanModel(nBarNo)==true)
        {
         TradeStartFlg=true;
        }
     }
   while(TradeStartFlg==false);

//遅行スパンシグナルチェック
   do
     {
      //既に遅行スパンシグナルが点灯していた場合
      if(BreakDelayedSpan(nBarNo))
        {
         //トレード停止
         TradeStartFlg=false;
        }
      nBarNo=nBarNo-1;
     }
   while(nBarNo>0 && TradeStartFlg==true);

   Print(LOGIDNT+"スパンモデルシグナルチェック終了");
  }
//+--------------------------------------------------------------+
//| ボリンジャーバンドポジションクローズ判定                                |
//+--------------------------------------------------------------+
bool IsCloseTouchBolinger2Sigma()
  {
//買いトレードのとき
   if(IsTradeBuy)
     {
      double Plus2Sigma=iBands(NULL,PERIOD_CURRENT,21,2,0,PRICE_CLOSE,1,0);
      //プラス2シグマ接触
      if(Close[0]>=Plus2Sigma) return true;
     }
//売りトレードのとき
   else
     {
      double Mnus2Sigma=iBands(NULL,PERIOD_CURRENT,21,2,0,PRICE_CLOSE,2,0);
      //マイナス2シグマ接触
      if(Close[0]<=Mnus2Sigma) return true;
     }
   return false;
  }
//+--------------------------------------------------------------+
//| ボリンジャーバンドポジションオープン判定                                |
//+--------------------------------------------------------------+
bool IsOpenTouchBolinger2Sigma()
  {
//買いトレードのとき
   if(IsTradeBuy)
     {
      double Mnus2Sigma=iBands(NULL,PERIOD_CURRENT,21,1,0,PRICE_CLOSE,1,0);
      //マイナス2シグマ接触
      if(Close[0]<=Mnus2Sigma) return true;
     }
//売りトレードのとき
   else
     {
      double Plus2Sigma=iBands(NULL,PERIOD_CURRENT,21,1,0,PRICE_CLOSE,2,0);
      //プラス2シグマ接触
      if(Close[0]>=Plus2Sigma) return true;
     }
   return false;
  }
//+--------------------------------------------------------------+
//| 利食い                                                        |
//+--------------------------------------------------------------+
bool IsCloseTakeProfit()
  {

//遅行スパンポジション情報取得
   datetime dtOpenTime=0;      //約定時刻
   double   dOpenPrice=0;      //約定価格
   static int MINPROFIT=100;      //最低利益
   for(int i=0; i<OrdersTotal(); i++)
     {
      bool bSelected=OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==Symbol())
        {
         if(OrderMagicNumber()==MAGICNO_DELAYEDSPAN)
           {
            //約定時刻取得
            dtOpenTime=OrderOpenTime();
            //約定価格取得
            dOpenPrice=OrderOpenPrice();
           }
        }
     }

//約定時の大局観スーパーボリンジャーの値を取得
   int nBarNo=iBarShift(NULL,PERIOD_D1,dtOpenTime);
   double SimpleMA=iBands(NULL,PERIOD_D1,21,0,0,PRICE_CLOSE,0,nBarNo);
   double Plus1Sigma=iBands(NULL,PERIOD_D1,21,1,0,PRICE_CLOSE,1,nBarNo);
   double Mnus1Sigma=iBands(NULL,PERIOD_D1,21,1,0,PRICE_CLOSE,2,nBarNo);

//買いトレードのとき
   if(IsTradeBuy)
     {
      double Plus2Sigma=iBands(NULL,PERIOD_D1,21,2,0,PRICE_CLOSE,1,nBarNo);
      double Plus3Sigma=iBands(NULL,PERIOD_D1,21,3,0,PRICE_CLOSE,1,nBarNo);

      //最低利益確定価格初期化
      double dTakeProfit=dOpenPrice+TAKEPROFIT*Point;

      //約定価格補正
      double dAdjustOpenPrice=dOpenPrice+MINPROFIT*Point;

      //約定価格が移動平均線以下且つ、マイナス1シグマラインより大きい場合
      if(SimpleMA>=dAdjustOpenPrice && Mnus1Sigma<dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観移動平均線
         dTakeProfit=iBands(NULL,PERIOD_D1,21,0,0,PRICE_CLOSE,0,0);
         Comment("大局観移動平均線（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //約定価格がプラス1シグマライン以下且つ、移動平均線より大きい場合
      if(Plus1Sigma>=dAdjustOpenPrice && SimpleMA<dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観プラス1シグマライン
         dTakeProfit=iBands(NULL,PERIOD_D1,21,1,0,PRICE_CLOSE,1,0);
         Comment("大局観プラス1シグマライン（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //約定価格がプラス2シグマライン以下且つ、プラス1シグマラインより大きい場合
      if(Plus2Sigma>=dAdjustOpenPrice && Plus1Sigma<dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観プラス2シグマライン
         dTakeProfit=iBands(NULL,PERIOD_D1,21,2,0,PRICE_CLOSE,1,0);
         Comment("大局観プラス2シグマライン（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //約定価格がプラス3シグマライン以下且つ、プラス2シグマラインより大きい場合
      if(Plus3Sigma>=dAdjustOpenPrice && Plus2Sigma<dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観プラス3シグマライン
         dTakeProfit=iBands(NULL,PERIOD_D1,21,3,0,PRICE_CLOSE,1,0);
         Comment("大局観プラス3シグマライン（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //接触したとき利益確定
      if(dTakeProfit<=Close[0])
        {
         return true;
        }
     }
//売りトレードのとき
   else
     {
      double Mnus2Sigma=iBands(NULL,PERIOD_D1,21,2,0,PRICE_CLOSE,2,nBarNo);
      double Mnus3Sigma=iBands(NULL,PERIOD_D1,21,3,0,PRICE_CLOSE,2,nBarNo);

      //最低利益確定価格初期化
      double dTakeProfit=dOpenPrice-TAKEPROFIT*Point;

      //約定価格補正
      double dAdjustOpenPrice=dOpenPrice-MINPROFIT*Point;

      //約定価格が移動平均線以上且つ、プラス1シグマライン未満の場合
      if(SimpleMA<=dAdjustOpenPrice && Plus1Sigma>dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観移動平均線
         dTakeProfit=iBands(NULL,PERIOD_D1,21,0,0,PRICE_CLOSE,0,0);
         Comment("大局観移動平均線（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //約定価格がマイナス1シグマライン以上且つ、移動平均線未満の場合
      if(Mnus1Sigma<=dAdjustOpenPrice && SimpleMA>dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観マイナス1シグマライン
         dTakeProfit=iBands(NULL,PERIOD_D1,21,1,0,PRICE_CLOSE,2,0);
         Comment("大局観マイナス1シグマライン（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //約定価格がマイナス2シグマライン以上且つ、マイナス1シグマラインの場合
      if(Mnus2Sigma<=dAdjustOpenPrice && Mnus1Sigma>dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観マイナス2シグマライン
         dTakeProfit=iBands(NULL,PERIOD_D1,21,2,0,PRICE_CLOSE,2,0);
         Comment("大局観マイナス2シグマライン（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //約定価格がマイナス3シグマライン以上且つ、マイナス2シグマライン未満の場合
      if(Mnus3Sigma<=dAdjustOpenPrice && Mnus2Sigma>dAdjustOpenPrice)
        {
         //利益確定ポイントは大局観マイナス3シグマライン
         dTakeProfit=iBands(NULL,PERIOD_D1,21,3,0,PRICE_CLOSE,2,0);
         Comment("大局観マイナス3シグマライン（"+DoubleToString(dTakeProfit)+"）で利益確定");
        }
      //接触したとき利益確定
      if(dTakeProfit>=Close[0])
        {
         return true;
        }
     }
   return false;
  }
//+--------------------------------------------------------------+
//| 遅行スパンポジションクローズ判定                                     |
//+--------------------------------------------------------------+
bool IsCloseDelayedSpan()
  {
//買いトレードのとき
   if(IsTradeBuy)
     {
      if(Close[1]<=Low[27]) return true;
     }
//売りトレードのとき
   else
     {
      if(Close[1]>=High[27]) return true;
     }
   return false;
  }
//+--------------------------------------------------------------+
//| 遅行スパンポジションオープン判定                                            |
//+--------------------------------------------------------------+
bool BreakDelayedSpan(int iBarNo=0)
  {
   double BlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,iBarNo-25);
   double RedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,iBarNo-25);

//買いトレードのとき
   if(IsTradeBuy)
     {
      //遅行スパンがローソク足の高値を上抜けたとき
      double Highest=High[iHighest(NULL,PERIOD_CURRENT,MODE_HIGH,27,iBarNo+2)];
      //遅行スパンブレイクチェック
      if(BlueSpan>=RedSpan && Close[iBarNo+1]>Highest)
        {
         Print(LOGIDNT+LOGIDNT+TimeToString(Time[iBarNo])+" "+"遅行スパン買いシグナル点灯");
         return true;
        }
     }
//売りトレードのとき
   else
     {
      //遅行スパンがローソク足の安値を下抜けたとき
      double Lowest=Low[iLowest(NULL,PERIOD_CURRENT,MODE_LOW,27,iBarNo+2)];
      //遅行スパンブレイクチェック
      if(BlueSpan<=RedSpan && Close[iBarNo+1]<Lowest)
        {
         Print(LOGIDNT+LOGIDNT+TimeToString(Time[iBarNo])+" "+"遅行スパン売りシグナル点灯");
         return true;
        }
     }
   return false;
  }
//+--------------------------------------------------------------+
//| スパンモデルポジションオープン判定                                            |
//+--------------------------------------------------------------+
bool IsOverRedSpan()
  {
   double PreBlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,-24);
   double PreRedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,-24);
   double BlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,-25);
   double RedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,-25);

//買いトレードのとき
   if(IsTradeBuy)
     {
      //スパンモデル買いシグナル点灯時、赤色スパンを下回っている場合、トレード開始
      if(PreBlueSpan<PreRedSpan && BlueSpan>=RedSpan && RedSpan>=Close[1])
        {
         return true;
        }
     }
//売りトレードのとき
   else
     {
      //スパンモデル売りシグナル点灯時、赤色スパンを上回っている場合、トレード開始
      if(PreBlueSpan>PreRedSpan && BlueSpan<=RedSpan && RedSpan<=Close[1])
        {
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//| ファイル読み込み                                                    |
//+------------------------------------------------------------------+
bool ReadFile(string FileName,string &stHeadder[],string &stContents[]) export
  {
   int handle;
   handle=FileOpen(FileName,FILE_CSV|FILE_READ,',');
   if(handle<1)
     {
      Print("File my_data.dat not found, the last error is ",GetLastError());
      return false;
     }
   else
     {
      //ファイル読み込み
      int ContentsCount=0;
      string stFileContents[];
      while(!FileIsEnding(handle))
        {
         string str=FileReadString(handle);
         ArrayResize(stFileContents,ContentsCount+1);
         stFileContents[ContentsCount]=str;
         ContentsCount=ContentsCount+1;
        }

      //ファイルクローズ
      FileClose(handle);

      //配列に格納
      int HeadderNo=0;
      int ElementNo=0;
      int ContentsSize=ArraySize(stFileContents);
      ArrayResize(stHeadder,ContentsSize/2);
      ArrayResize(stContents,ContentsSize/2);
      for(ContentsCount=0; ContentsCount<ContentsSize;ContentsCount++)
        {
         //ヘッダー格納
         if(ContentsCount<ContentsSize/2)
           {
            stHeadder[HeadderNo]=stFileContents[ContentsCount];
            HeadderNo=HeadderNo+1;
           }
         //データ格納
         else
           {
            stContents[ElementNo]=stFileContents[ContentsCount];
            ElementNo=ElementNo+1;
           }
        }
      return true;
     }
  }
//+--------------------------------------------------------------+
//| ポジションオープン                                             |
//+--------------------------------------------------------------+
int PositionOpen(int nTicketNo) export
  {
   int nOrderType;
   double dOrderPrice;
   double dOrderStopLoss;
   double dOrderTakeProfit;
   color clrOpen;
//買いトレードの場合
   if(IsTradeBuy)
     {
      nOrderType=OP_BUY;
      dOrderPrice=Ask;
      dOrderStopLoss=Ask-STOPLOSS*Point;
      dOrderTakeProfit=Ask+TAKEPROFIT*Point;
      clrOpen=clrAqua;
     }
//売りトレードの場合
   else
     {
      nOrderType=OP_SELL;
      dOrderPrice=Bid;
      dOrderStopLoss=Bid+STOPLOSS*Point;
      dOrderTakeProfit=Bid-TAKEPROFIT*Point;
      clrOpen=clrDarkRed;
     }
//証拠金チェック
   if(AccountFreeMarginCheck(Symbol(),nOrderType,LOTCOUNT)<=0 || 
      GetLastError()==ERR_NOT_ENOUGH_MONEY)
     {
      //ログ出力
      string sErrMessage=ErrorDescription(ERR_NOT_ENOUGH_MONEY);
      SendNotification(Symbol()+" "+sErrMessage);
      return false;
     }

//ポジションオープン
   int iRtnTicketNo=OrderSend(NULL,nOrderType,LOTCOUNT,dOrderPrice,SLIPPAGE,
                              dOrderStopLoss,dOrderTakeProfit,NULL,nTicketNo,NULL,clrOpen);
   if(iRtnTicketNo==-1)
     {
      int iLastError=GetLastError();
      string sErrMessage=ErrorDescription(iLastError);
      SendNotification(Symbol()+" "+sErrMessage);
     }
   return iRtnTicketNo;
  }
//+------------------------------------------------------------------+
//| ポジションクローズ                                                    |
//+------------------------------------------------------------------+
bool PositionClose(int nMagicNo)
  {
   bool Closed=false;

//オーダー情報取得
   for(int i=0; i<OrdersTotal(); i++)
     {
      bool bSelected=OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==Symbol())
        {
         if(OrderMagicNumber()==nMagicNo)
           {
            //ポジションクローズ
            Closed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),SLIPPAGE,Magenta);
            if(Closed!=true)
              {
               int iLastError=GetLastError();
               string sErrMessage=ErrorDescription(iLastError);
               SendNotification(Symbol()+" "+sErrMessage);
              }
           }
        }
     }
   return Closed;
  }
//+------------------------------------------------------------------+
//| 全ポジションクローズ                                                    |
//+------------------------------------------------------------------+
void PositionCloseAll()
  {

//オーダー情報取得
   for(int i=0; i<OrdersTotal(); i++)
     {
      bool bSelected=OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==Symbol())
        {
         //ポジションクローズ
         bool Closed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),SLIPPAGE,Magenta);
         if(Closed!=true)
           {
            int iLastError=GetLastError();
            string sErrMessage=ErrorDescription(iLastError);
            SendNotification(Symbol()+" "+sErrMessage);
           }
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//| ポジション検索                                                    |
//+------------------------------------------------------------------+
bool IsExistPosition(int nMagicNo)
  {

//オーダー情報取得
   for(int i=0; i<OrdersTotal(); i++)
     {
      bool bSelected=OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==Symbol())
        {
         if(OrderMagicNumber()==nMagicNo) return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//| スパンモデルシグナルチェック                                          |
//+------------------------------------------------------------------+
bool CheckSpanModel(int iBarNo=0)
  {
   double PreBlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,iBarNo-24);
   double PreRedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,iBarNo-24);
   double BlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,iBarNo-25);
   double RedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,iBarNo-25);

//買いトレードのとき
   if(IsTradeBuy)
     {
      //スパンモデル買いシグナル点灯時
      if(PreBlueSpan<PreRedSpan && BlueSpan>=RedSpan)
        {
         Print(LOGIDNT+LOGIDNT+TimeToString(Time[iBarNo])+" "+"スパンモデル買いシグナル点灯");
         return true;
        }
     }
//売りトレードのとき
   else
     {
      //スパンモデル売りシグナル点灯時
      if(PreBlueSpan>PreRedSpan && BlueSpan<=RedSpan)
        {
         Print(LOGIDNT+LOGIDNT+TimeToString(Time[iBarNo])+" "+"スパンモデル売りシグナル点灯");
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//| スパンモデルシグナル消灯チェック                                          |
//+------------------------------------------------------------------+
bool IsClosedSpanModel(int iBarNo=0)
  {
   double PreBlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,iBarNo-24);
   double PreRedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,iBarNo-24);
   double BlueSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,iBarNo-25);
   double RedSpan=iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,iBarNo-25);

//買いトレードのとき
   if(IsTradeBuy)
     {
      //スパンモデル売りシグナル点灯時
      if(PreBlueSpan>PreRedSpan && BlueSpan<=RedSpan)
        {
         Print(LOGIDNT+LOGIDNT+TimeToString(Time[iBarNo])+" "+"スパンモデル買いシグナル消灯");
         return true;
        }
     }
//売りトレードのとき
   else
     {
      //スパンモデル買いシグナル点灯時
      if(PreBlueSpan<PreRedSpan && BlueSpan>=RedSpan)
        {
         Print(LOGIDNT+LOGIDNT+TimeToString(Time[iBarNo])+" "+"スパンモデル売りシグナル消灯");
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
