//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Includes.
#include "../Bar.struct.h"
#include "../Indicator.struct.h"
#include "../Serializer.mqh"
#include "Special/Indi_Math.mqh"

// Structs.
struct IndiPivotParams : IndicatorParams {
  ENUM_PP_TYPE method;  // Pivot point calculation method.
  // Struct constructor.
  IndiPivotParams(ENUM_PP_TYPE _method = PP_CLASSIC, int _shift = 0) : IndicatorParams(INDI_PIVOT) {
    method = _method;
    shift = _shift;
  };
  IndiPivotParams(IndiPivotParams& _params, ENUM_TIMEFRAMES _tf) {
    THIS_REF = _params;
    tf = _tf;
  };
};

/**
 * Implements Pivot Detector.
 */
class Indi_Pivot : public IndicatorTickOrCandleSource<IndiPivotParams> {
 protected:
  /* Protected methods */

  /**
   * Initialize.
   */
  void Init() { Set<int>(STRUCT_ENUM(IndicatorDataParams, IDATA_PARAM_MAX_MODES), 9); }

 public:
  /**
   * Class constructor.
   */
  Indi_Pivot(IndiPivotParams& _p, ENUM_IDATA_SOURCE_TYPE _idstype = IDATA_BUILTIN, IndicatorData* _indi_src = NULL,
             int _indi_src_mode = 0)
      : IndicatorTickOrCandleSource(
            _p, IndicatorDataParams::GetInstance(9, TYPE_FLOAT, _idstype, IDATA_RANGE_MIXED, _indi_src_mode),
            _indi_src) {
    Init();
  };
  Indi_Pivot(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT, int _shift = 0)
      : IndicatorTickOrCandleSource(INDI_PIVOT, _tf, _shift) {
    iparams.tf = _tf;
    Init();
  };

  /**
   * Returns the indicator's struct entry for the given shift.
   *
   * @see: IndicatorDataEntry.
   *
   * @return
   *   Returns IndicatorDataEntry struct filled with indicator values.
   */
  virtual IndicatorDataEntry GetEntry(int _shift = 0) {
    int _ishift = _shift >= 0 ? _shift : iparams.GetShift();
    long _bar_time = GetBarTime(_ishift);
    IndicatorDataEntry _entry = idata.GetByKey(_bar_time);
    if (_bar_time > 0 && !_entry.IsValid() && !_entry.CheckFlag(INDI_ENTRY_FLAG_INSUFFICIENT_DATA)) {
      ResetLastError();
      BarOHLC _ohlc = GetOHLC(_ishift);
      _entry.timestamp = GetBarTime(_ishift);
      if (_ohlc.IsValid()) {
        _entry.Resize(Get<int>(STRUCT_ENUM(IndicatorDataParams, IDATA_PARAM_MAX_MODES)));
        _ohlc.GetPivots(GetMethod(), _entry.values[0].value.vflt, _entry.values[1].value.vflt,
                        _entry.values[2].value.vflt, _entry.values[3].value.vflt, _entry.values[4].value.vflt,
                        _entry.values[5].value.vflt, _entry.values[6].value.vflt, _entry.values[7].value.vflt,
                        _entry.values[8].value.vflt);
        for (int i = 0; i <= 8; ++i) {
          _entry.values[i].SetDataType(TYPE_FLOAT);
        }
      }
      GetEntryAlter(_entry, _ishift);
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, IsValidEntry(_entry));
      if (_entry.IsValid()) {
        idata.Add(_entry, _bar_time);
        istate.is_changed = false;
        istate.is_ready = true;
      } else {
        _entry.AddFlags(INDI_ENTRY_FLAG_INSUFFICIENT_DATA);
      }
    }
    if (_LastError != ERR_NO_ERROR) {
      istate.is_ready = false;
      ResetLastError();
    }
    return _entry;
  }

  /**
   * Returns the indicator's value.
   */
  virtual IndicatorDataEntryValue GetEntryValue(int _mode = 0, int _shift = 0) {
    int _ishift = _shift >= 0 ? _shift : iparams.GetShift();
    return GetEntry(_ishift)[_mode];
  }

  /**
   * Checks if indicator entry values are valid.
   */
  virtual bool IsValidEntry(IndicatorDataEntry& _entry) {
    bool _is_valid = Indicator<IndiPivotParams>::IsValidEntry(_entry);
    switch (Get<ENUM_IDATA_SOURCE_TYPE>(STRUCT_ENUM(IndicatorDataParams, IDATA_PARAM_IDSTYPE))) {
      case IDATA_BUILTIN:
        break;
      case IDATA_INDICATOR:
        // In this mode, price is fetched from given indicator. Such indicator
        // must have at least 4 buffers and define OHLC in the first 4 buffers.
        // Indi_Price is an example of such indicator.
        if (!HasDataSource()) {
          GetLogger().Error("Invalid data source!");
          SetUserError(ERR_INVALID_PARAMETER);
          _is_valid &= false;
        }
        break;
      default:
        SetUserError(ERR_INVALID_PARAMETER);
        _is_valid &= false;
        break;
    }
    return _is_valid;
  }

  /* Getters */

  /**
   * Returns OHLC struct.
   */
  BarOHLC GetOHLC(int _shift = 0) {
    BarOHLC _ohlc;
    switch (Get<ENUM_IDATA_SOURCE_TYPE>(STRUCT_ENUM(IndicatorDataParams, IDATA_PARAM_IDSTYPE))) {
      case IDATA_BUILTIN:
        // In this mode, price is fetched from chart.
        _ohlc = Chart::GetOHLC(_shift);
        break;
      case IDATA_INDICATOR:
        // In this mode, price is fetched from given indicator. Such indicator
        // must have at least 4 buffers and define OHLC in the first 4 buffers.
        // Indi_Price is an example of such indicator.
        if (HasDataSource()) {
          _ohlc.open = GetDataSource().GetValue<float>(PRICE_OPEN, _shift);
          _ohlc.high = GetDataSource().GetValue<float>(PRICE_HIGH, _shift);
          _ohlc.low = GetDataSource().GetValue<float>(PRICE_LOW, _shift);
          _ohlc.close = GetDataSource().GetValue<float>(PRICE_CLOSE, _shift);
        }
        break;
      default:
        SetUserError(ERR_INVALID_PARAMETER);
        break;
    }
    return _ohlc;
  }

  /**
   * Get pivot point calculation method.
   */
  ENUM_PP_TYPE GetMethod() { return iparams.method; }

  /* Setters */

  /**
   * Set pivot point calculation method.
   */
  void SetMethod(ENUM_PP_TYPE _method) {
    istate.is_changed = true;
    iparams.method = _method;
  }

  /**
   * Whether we can and have to select mode when specifying data source.
   */
  virtual bool IsDataSourceModeSelectable() { return false; }
};
