//+------------------------------------------------------------------+
//|                                         SpanModelTradeViewer.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
string UpperPeriodIndicator="SuperBollinger.tpl";
string LowerPeriodIndicator="SpanModel.tpl";
string Symbols[]=
  {
   "USDJPY",
   "EURJPY",
   "EURUSD",
   "GBPJPY",
   "GBPUSD",
   "AUDJPY",
   "AUDUSD",
   "EURGBP",
   "EURAUD",
   "GBPAUD"
  };
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
//今の通貨ペアを取得
   string CurrentSymbol=ChartSymbol(0);

//今の通貨ペアのインデックスを取得
   int SymbolIndex=0;
   for(SymbolIndex=0; SymbolIndex<ArraySize(Symbols)-1; SymbolIndex++)
     {
      if(CurrentSymbol==Symbols[SymbolIndex])break;
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      //Wボタンが押されたとき
      if(lparam==87)
        {
         //日足適用
         ChartSetSymbolPeriod(0,Symbol(),PERIOD_D1);
         //スーパーボリンジャー適用
         ChartApplyTemplate(0,UpperPeriodIndicator);
        }
      //Zボタンが押されたとき
      if(lparam==90)
        {
         //1時間足適用
         ChartSetSymbolPeriod(0,Symbol(),PERIOD_H1);
         //スパンモデル適用
         ChartApplyTemplate(0,LowerPeriodIndicator);
        }
      //Sボタンが押されたとき
      if(lparam==83)
        {
         //次の通貨をセット
         if(SymbolIndex!=ArraySize(Symbols)-1)
           {
            SymbolIndex=SymbolIndex+1;
           }
         else
           {
            SymbolIndex=0;
           }
         ChartSetSymbolPeriod(0,Symbols[SymbolIndex],PERIOD_CURRENT);
        }
      //Aボタンが押されたとき
      if(lparam==65)
        {
         //前の通貨をセット
         if(SymbolIndex!=0)
           {
            SymbolIndex=SymbolIndex-1;
           }
         else
           {
            SymbolIndex=ArraySize(Symbols)-1;
           }
         ChartSetSymbolPeriod(0,Symbols[SymbolIndex],PERIOD_CURRENT);
        }
     }
  }
//+------------------------------------------------------------------+
