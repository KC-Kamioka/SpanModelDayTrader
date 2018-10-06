//+------------------------------------------------------------------+
//|                                             SMTDeinitializer.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
long lChartID=0;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//�|�W�V�����N���[�Y
   for(int i=0; i<OrdersTotal(); i++)
     {
      bool bSelected=OrderSelect(i,SELECT_BY_POS);
         bool Closed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,Magenta);
     }
     
//���ݕ\�����̃`���[�g�����
   lChartID=ChartFirst();
   while(lChartID>0)
     {
      //���݂̃`���[�g�̏ꍇ
      if(lChartID==ChartID())
        {
         //���̃`���[�g���Z�b�g
         lChartID=ChartNext(lChartID);
        }
      else
        {
         //�`���[�g�����
         ChartClose(lChartID);

         //���̃`���[�g���Z�b�g
         lChartID=ChartNext(lChartID);
        }
     }   
  }
//+------------------------------------------------------------------+
