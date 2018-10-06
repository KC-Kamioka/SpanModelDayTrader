//+------------------------------------------------------------------+
//|                                                SuperBolinger.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 11

//---- buffers
double SB_ChikoSpan[];
double SimpleMA[];
double Plus1Sigma[];
double Mnus1Sigma[];
double Plus2Sigma[];
double Mnus2Sigma[];
double Plus3Sigma[];
double Mnus3Sigma[];
double BlueSpan[];
double RedSpan[];
double SP_ChikoSpan[];
//---- libraries
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrMagenta);
   SetIndexBuffer(0,SB_ChikoSpan);
   SetIndexShift(0,-21*12);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrAqua);
   SetIndexBuffer(1,SimpleMA);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrYellow);
   SetIndexBuffer(2,Plus1Sigma);
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,clrYellow);
   SetIndexBuffer(3,Mnus1Sigma);
   SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,1,clrBlueViolet);
   SetIndexBuffer(4,Plus2Sigma);
   SetIndexStyle(5,DRAW_LINE,STYLE_SOLID,1,clrBlueViolet);
   SetIndexBuffer(5,Mnus2Sigma);
   SetIndexStyle(6,DRAW_LINE,STYLE_SOLID,1,clrOrange);
   SetIndexBuffer(6,Plus3Sigma);
   SetIndexStyle(7,DRAW_LINE,STYLE_SOLID,1,clrOrange);
   SetIndexBuffer(7,Mnus3Sigma);
   SetIndexStyle(8,DRAW_LINE,STYLE_SOLID,1,clrBlue);
   SetIndexBuffer(8,BlueSpan);
   SetIndexStyle(9,DRAW_LINE,STYLE_SOLID,1,clrRed);
   SetIndexBuffer(9,RedSpan);
   SetIndexStyle(10,DRAW_LINE,STYLE_SOLID,1,clrMagenta);
   SetIndexBuffer(10,SP_ChikoSpan);
   SetIndexShift(10,-26);
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
   int BarNo=0;
   for(int i=0; i<rates_total-2; i++)
     {
      //スーパーボリンジャー作成
      datetime PreTimeM5=iTime(NULL,PERIOD_M5,i);
      datetime TimeM5=iTime(NULL,PERIOD_M5,i-1);
      if(TimeHour(PreTimeM5)!=TimeHour(TimeM5)) BarNo=BarNo+1;
      SB_ChikoSpan[i]= iClose(NULL,PERIOD_H1,BarNo);
      SimpleMA[i] = iBands(NULL,PERIOD_H1,21,0,0,PRICE_CLOSE,0,BarNo);
      Plus1Sigma[i] = iBands(NULL,PERIOD_H1,21,1,0,PRICE_CLOSE,1,BarNo);
      Mnus1Sigma[i] = iBands(NULL,PERIOD_H1,21,1,0,PRICE_CLOSE,2,BarNo);
      Plus2Sigma[i] = iBands(NULL,PERIOD_H1,21,2,0,PRICE_CLOSE,1,BarNo);
      Mnus2Sigma[i] = iBands(NULL,PERIOD_H1,21,2,0,PRICE_CLOSE,2,BarNo);
      Plus3Sigma[i] = iBands(NULL,PERIOD_H1,21,3,0,PRICE_CLOSE,1,BarNo);
      Mnus3Sigma[i] = iBands(NULL,PERIOD_H1,21,3,0,PRICE_CLOSE,2,BarNo);
      
      //スパンモデル作成
      BlueSpan[i]     = iIchimoku(NULL,PERIOD_CURRENT,9,26,52,3,i-26);
      RedSpan[i]      = iIchimoku(NULL,PERIOD_CURRENT,9,26,52,4,i-26);
      SP_ChikoSpan[i] = iClose(NULL,PERIOD_CURRENT,i);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
