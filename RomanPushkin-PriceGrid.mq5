//+------------------------------------------------------------------+
//|                                                  Hourly-Grid.mq5 |
//|                                    Copyright 2013, Roman Pushkin |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include <IncGUI.mqh> // refer to http://www.mql5.com/en/articles/310 for more info
#property copyright "Copyright 2013, Roman Pushkin"
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//+----------------------------------------------+ 
//| ¬ходные параметры индикатора                 |
//+----------------------------------------------+ 
input color Line_Color=SteelBlue;                // ÷вет линии

string horizontal_line_token_prefix = "horizontal_line_";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+


int OnInit()
  {
   
   w.Button("btn_Scale1", 0, 160, 20, 20, 18, "1",0xc0c0c0,0,10,"Arial");
   w.Button("btn_Scale2", 0, 135, 20, 20, 18, "2",0xc0c0c0,0,10,"Arial");
   w.Button("btn_Scale3", 0, 110, 20, 20, 18, "3",0xc0c0c0,0,10,"Arial");
   w.Button("btn_Scale4", 0,  85, 20, 20, 18, "4",0xc0c0c0,0,10,"Arial");
   w.Button("btn_Scale5", 0,  60, 20, 20, 18, "5",0xc0c0c0,0,10,"Arial");
   g.SetCorner("btn_Scale1", CORNER_RIGHT_LOWER);
   g.SetCorner("btn_Scale2", CORNER_RIGHT_LOWER);
   g.SetCorner("btn_Scale3", CORNER_RIGHT_LOWER);
   g.SetCorner("btn_Scale4", CORNER_RIGHT_LOWER);
   g.SetCorner("btn_Scale5", CORNER_RIGHT_LOWER);
   
   g.SetState(0, "btn_Scale1", true);
   
  
//--- indicator buffers mapping
   EventSetTimer(1);
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
   main_code();
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
   if(id == CHARTEVENT_CHART_CHANGE ||
      id == CHARTEVENT_OBJECT_DRAG)
      {
         main_code();
      }
   else if(id == CHARTEVENT_OBJECT_CLICK)
   {
      string tmp = StringSubstr(sparam, 0, StringLen("btn_Scale"));
      if(tmp == "btn_Scale")
      {
         g.SetState(0, "btn_Scale1", false);
         g.SetState(0, "btn_Scale2", false);
         g.SetState(0, "btn_Scale3", false);
         g.SetState(0, "btn_Scale4", false);
         g.SetState(0, "btn_Scale5", false);
         g.SetState(0, sparam, true);
         change_scale(sparam);
         ChartRedraw(0);
         
         //Print("selected");
      }
   }
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void change_scale(string selected_button_name)
{
   remove_horizontal_lines();
   
   if(selected_button_name == "btn_Scale1")
   {
         gridResSubDiv = 2.0;
   }
   else if(selected_button_name == "btn_Scale2")
   {
         gridResSubDiv = 4.0;
   }
   else if(selected_button_name == "btn_Scale3")
   {
         gridResSubDiv = 5.0;
   }
   else if(selected_button_name == "btn_Scale4")
   {
         gridResSubDiv = 10.0;
   }
   else
   {
         gridResSubDiv = 1.0;
   }
   
   previous_window_price_max = 0;
   previous_window_price_min = 0;
   main_code();

}
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void OnDeinit(const int reason)
{
   remove_horizontal_lines();
   g.Delete("btn_Scale1");
   g.Delete("btn_Scale2");
   g.Delete("btn_Scale3");
   g.Delete("btn_Scale4");
   g.Delete("btn_Scale5");
   EventKillTimer();
   ChartRedraw(0);
}  

double previous_window_price_max = 0;
double previous_window_price_min = 0;
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   main_code();
   
  }

double log10e = 0.43429448190325182765112891891661;
double gridResSubDiv = 2.0;
double previous_chart_width = 0;

CChartObjectLabel labels[1000];

void main_code()
{
   double window_price_max = ChartGetDouble(0, CHART_PRICE_MAX, 0);
   double window_price_min = ChartGetDouble(0, CHART_PRICE_MIN, 0);
   int chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);

   // execute code only if window price changed

   if(previous_window_price_max == window_price_max &&
      previous_window_price_min == window_price_min &&
      previous_chart_width == chart_width)
      return;
   
   previous_window_price_max = window_price_max;
   previous_window_price_min = window_price_min;
   previous_chart_width = chart_width;

   // remove existing lines
   
   remove_horizontal_lines();
   
   // get range
   
   double range = window_price_max - window_price_min;
   
   double log10Range = log10e * MathLog(range);
   log10Range = MathFloor(log10Range);
   double gridRes = MathPow(10.0, log10Range);
   
   double startPos = window_price_min - gridRes;
   double gridPos = startPos - MathModCorrect(startPos, gridRes);
   
   grid_count = 0;
   
   double modulus;
   string name;
   
   datetime dt = 0;
   int x = 0, y = 0;
   
   while(gridPos < window_price_max + gridRes)
   {
      modulus = MathModCorrect(gridPos, gridRes);
      
      name = horizontal_line_token_prefix + IntegerToString(grid_count);
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, gridPos);
      
      ObjectSetInteger(0, name, OBJPROP_COLOR, Line_Color);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);

      // add labels
      // we need y-coordinate only
      if(ChartTimePriceToXY(0, 0, dt, gridPos, x, y))
      {
      
         
         if(!labels[grid_count].Create(0, "label_" + horizontal_line_token_prefix + IntegerToString(grid_count), 0, chart_width - 40, y - 7))
         {
            Print(GetLastError());
         }
         
         string desc;
         if(gridPos > 1000 && (gridPos == (int)gridPos))
         {
            desc = format_with_separator((int)gridPos);
         } else {
            desc = DoubleToString(gridPos);
         }

         labels[grid_count].Description(desc);
         labels[grid_count].Color((color)(0xFFFFFF));
         labels[grid_count].Font("Tahoma");
         labels[grid_count].FontSize(7);

      } else {
         Print(GetLastError());
      }

    
      gridPos += (gridRes / gridResSubDiv);
      grid_count++;   
   }
   
   
   ChartRedraw();
   
   return;
}

int grid_count = 0;

void remove_horizontal_lines()
{
   //horizontal_line_token_prefix
   
   string name, name2;
   
   for(int i = 0; i < grid_count; i++)
   {
      name = horizontal_line_token_prefix + IntegerToString(i);
      ObjectDelete(0, name);
      
      name2 = "label_" + horizontal_line_token_prefix + IntegerToString(i);
      ObjectDelete(0, name2);
   }
}


//+------------------------------------------------------------------+
//| MathModCorrect                                                   |
//|                                                                  |
//| There are known problems with the MathMod API call identified    |
//| in this article:     http://articles.mql4.com/866                |
//| There is a further problem with the solution presented by that   |
//| article in that it is inaccurate when both a and b parameters    |
//| are small numbers (ie. less than 1.0)                            |
//| Consider a=0.7 and b=0.1                                         |
//| The integer result of a/b is 7. Fine.                            |
//| However, suppose that the nearest floating point representation  |
//| of 0.7 is actually 0.6999999999999999.                           |
//| Now the integer result of a/b is in fact 6. Quite different!     |
//| This version of MathModCorrect gets around the problem by keeping|
//| the result of a/b in a double and normalizing the result         |
//| to two decimal places. Thus a number such as 0.6999999999999999  |
//| would be rounded to 0.70 rather than 0.69 which is a much        |
//| better representation of the true value, before being truncated  |
//| (MathFloor) to yield the modulus.                                |
//|                                                                  |
//+------------------------------------------------------------------+
double MathModCorrect(double a, double b)
{ 
   if(b == 0)
      return 0;

   double tmpRes = a / b;
   double tmpNorm = NormalizeDouble(tmpRes, 2);
   double tmpFlr = MathFloor(tmpNorm);
   double result = (a - (tmpFlr * b));
   return(result);
}


string format_with_separator (int n) {
    string result = "";
    
    int n2 = 0;
    int scale = 1;
    if (n < 0) {
        result += "-";
        n = -n;
    }
    
    while (n >= 1000) {
        n2 = n2 + scale * (n % 1000);
        n /= 1000;
        scale *= 1000;
    }
    
    result += IntegerToString(n, 0);
    
    while (scale != 1) {
        scale /= 1000;
        n = n2 / scale;
        n2 = n2  % scale;
        result += StringFormat(" %03d", n);
    }
    return result;
}