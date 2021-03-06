//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Strategy based on the Moving Average indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/ima
 * - https://www.mql5.com/en/docs/indicators/ima
 */

// Includes.
#include "I_MA.mqh"
#include <EA31337-classes\Strategy.mqh>

// User inputs.
#ifdef __input__ input #endif double MA_SignalBaseLevel = 0;    // Signal base level
#ifdef __input__ input #endif int    MA_SignalOpenMethod = -98; // Signal open method (-127-127)
#ifdef __input__ input #endif double MA_SignalLevel = 1.2;      // Signal level
#ifdef __input__ input #endif string MA_Override = "";          // Params to override

/**
 * Strategy class.
 */
class S_MA : public Strategy {

  private:

  public:

  /**
   * Class constructor.
   */
  void S_MA(StrategyParams &_params)
  {
  }

  /**
   * Initialize strategy.
   */
  bool Init() {
    bool initiated = true;
    IndicatorParams indi_params = { S_IND_MA };
    params.data = new I_MA(indi_params); // @todo: Provide instance of chart, instead of create a new one.
    initiated &= IndicatorInfo().Update();
    initiated &= IndicatorInfo().GetValue(MA_FAST, CURR, (double) TYPE_DOUBLE) > 0;
    return initiated;
  }

  /**
   * Checks strategy trade signal.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   _base_method (int) - base signal method
   *   _open_method (int) - open signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  virtual bool Signal(ENUM_ORDER_TYPE _cmd, int _base_method, int _open_method = 0, double _level = 0.0) {
    bool _signal = false;
    IndicatorInfo().Update();
    _level *= MarketInfo().GetPipSize();
    #define _MA(type, index) IndicatorInfo().GetValue(type, index, (double) TYPE_DOUBLE)

    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _signal  = _MA(MA_FAST, CURR) > _MA(MA_MEDIUM, CURR) + _level;
        _signal &= _MA(MA_MEDIUM, CURR) > _MA(MA_SLOW, CURR) + _level;
        if ((_open_method & OPEN_METHOD1) != 0) _signal &= _MA(MA_FAST, CURR) > _MA(MA_SLOW, CURR) + _level;
        if ((_open_method & OPEN_METHOD2) != 0) _signal &= _MA(MA_MEDIUM, CURR) > _MA(MA_SLOW, CURR);
        if ((_open_method & OPEN_METHOD3) != 0) _signal &= _MA(MA_SLOW, CURR) > _MA(MA_SLOW, PREV);
        if ((_open_method & OPEN_METHOD4) != 0) _signal &= _MA(MA_FAST, CURR) > _MA(MA_FAST, PREV);
        if ((_open_method & OPEN_METHOD5) != 0) _signal &= _MA(MA_FAST, CURR) - _MA(MA_MEDIUM, CURR) > _MA(MA_MEDIUM, CURR) - _MA(MA_SLOW, CURR);
        if ((_open_method & OPEN_METHOD6) != 0) _signal &= (_MA(MA_MEDIUM, PREV) < _MA(MA_SLOW, PREV) || _MA(MA_MEDIUM, FAR) < _MA(MA_SLOW, FAR));
        if ((_open_method & OPEN_METHOD7) != 0) _signal &= (_MA(MA_FAST, PREV) < _MA(MA_MEDIUM, PREV) || _MA(MA_FAST, FAR) < _MA(MA_MEDIUM, FAR));
        break;
      case ORDER_TYPE_SELL:
        _signal  = _MA(MA_FAST, CURR)   < _MA(MA_MEDIUM, CURR) - _level;
        _signal &= _MA(MA_MEDIUM, CURR) < _MA(MA_SLOW, CURR) - _level;
        if ((_open_method & OPEN_METHOD1) != 0) _signal &= _MA(MA_FAST, CURR) < _MA(MA_SLOW, CURR) - _level;
        if ((_open_method & OPEN_METHOD2) != 0) _signal &= _MA(MA_MEDIUM, CURR) < _MA(MA_SLOW, CURR);
        if ((_open_method & OPEN_METHOD3) != 0) _signal &= _MA(MA_SLOW, CURR) < _MA(MA_SLOW, PREV);
        if ((_open_method & OPEN_METHOD4) != 0) _signal &= _MA(MA_FAST, CURR) < _MA(MA_FAST, PREV);
        if ((_open_method & OPEN_METHOD5) != 0) _signal &= _MA(MA_MEDIUM, CURR) - _MA(MA_FAST, CURR) > _MA(MA_SLOW, CURR) - _MA(MA_MEDIUM, CURR);
        if ((_open_method & OPEN_METHOD6) != 0) _signal &= (_MA(MA_MEDIUM, PREV) > _MA(MA_SLOW, PREV) || _MA(MA_MEDIUM, FAR) > _MA(MA_SLOW, FAR));
        if ((_open_method & OPEN_METHOD7) != 0) _signal &= (_MA(MA_FAST, PREV) > _MA(MA_MEDIUM, PREV) || _MA(MA_FAST, FAR) > _MA(MA_MEDIUM, FAR));
        break;
    }
    // _signal &= _method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return _signal;
  }
  virtual bool Signal(ENUM_ORDER_TYPE _cmd) {
    return Signal(_cmd, GetSignalBaseMethod(), GetSignalOpenMethod(), GetSignalLevel());
  }

  bool Draw() {
    #include <EA31337-classes\Draw.mqh>
    /* @todo
    Draw::TLine(StringFormat("%s%s%d", market.GetChartSymbol(), "MA Fast", i),   ma_fast[index][i],   ma_fast[index][i+1],    iTime(NULL, 0, shift), iTime(NULL, 0, shift+1), clrBlue);
    Draw::TLine(StringFormat("%s%s%d", market.GetChartSymbol(), "MA Medium", i), ma_medium[index][i], ma_medium[index][i+1],  iTime(NULL, 0, shift), iTime(NULL, 0, shift+1), clrYellow);
    Draw::TLine(StringFormat("%s%s%d", market.GetChartSymbol(), "MA Slow", i),   ma_slow[index][i],   ma_slow[index][i+1],    iTime(NULL, 0, shift), iTime(NULL, 0, shift+1), clrGray);
    */
    return true;
  }
};
