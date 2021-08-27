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

/**
 * @file
 * IndicatorBufferValueStorage class.
 */

#ifndef __MQL__
// Allows the preprocessor to include a header file when it is needed.
#pragma once
#endif

// Includes.
#include "Refs.mqh"

/**
 * Holds buffers used to cache values calculated via OnCalculate methods.
 */
template <typename C>
class IndicatorCalculateCache : public Dynamic {
 public:
  // Total number of calculated values.
  int prev_calculated;

  // Number of prices to use.
  int total;

  // Whether cache was initialized with price buffer.
  bool initialized;

  // Buffer to store input prices. Won't be deleted!
  ValueStorage<C> *price_buffer;

  // Buffers used for OnCalculate calculations.
  ARRAY(ValueStorage<C> *, buffers);

  // Auxiliary caches related to this one.
  ARRAY(IndicatorCalculateCache<C> *, subcaches);

  /**
   * Constructor.
   */
  IndicatorCalculateCache(int _buffers_size = 0) {
    prev_calculated = 0;
    total = 0;
    initialized = false;
    Resize(_buffers_size);
  }

  /**
   * Destructor.
   */
  ~IndicatorCalculateCache() {
    int i;

    for (i = 0; i < ArraySize(buffers); ++i) {
      if (buffers[i] != NULL) {
        delete buffers[i];
      }
    }

    for (i = 0; i < ArraySize(subcaches); ++i) {
      if (subcaches[i] != NULL) {
        delete subcaches[i];
      }
    }
  }

  /**
   * Returns size of the current price buffer.
   */
  int GetTotal() { return ArraySize(price_buffer); }

  /**
   * Returns number of already calculated prices (bars).
   */
  int GetPrevCalculated() { return prev_calculated; }

  /**
   * Whether price buffer is already set.
   */
  bool IsInitialized() { return initialized; }

  /**
   * Returns existing or new cache as a child of current one. Useful when indicator uses other indicators and requires
   * unique caches for them.
   */
  IndicatorCalculateCache<C> *GetSubCache(int index) {
    if (index >= ArraySize(subcaches)) {
      ArrayResize(subcaches, index + 1, 10);
    }

    if (subcaches[index] == NULL) {
      subcaches[index] = new IndicatorCalculateCache();
    }

    return subcaches[index];
  }

  /**
   * Add buffer of the given type. Usage: AddBuffer<NativeBuffer>()
   */
  template <typename T>
  int AddBuffer(int _num_buffers = 1) {
    ValueStorage<C> *_ptr;

    while (_num_buffers-- > 0) {
      _ptr = new T();
      ArrayPushObject(buffers, _ptr);
    }

    return ArraySize(buffers) - 1;
  }

  /**
   *
   */
  ValueStorage<C> *GetBuffer(int _index) { return buffers[_index]; }

  /**
   *
   */
  ValueStorage<C> *GetPriceBuffer() { return price_buffer; }

  /**
   *
   */
  void SetPriceBuffer(ValueStorage<C> &_price, int _total = 0) {
    price_buffer = &_price;

    if (_total == 0) {
      _total = _price.Size();
    }

    total = _total;

    // Cache is ready to be used.
    initialized = true;
  }

  /**
   * Resizes all buffers.
   */
  void Resize(int _buffers_size) {
    for (int i = 0; i < ArraySize(buffers); ++i) {
      buffers[i].Resize(_buffers_size, 65535);
    }
  }

  /**
   * Retrieves cached value from the given buffer.
   */
  double GetValue(int _buffer_index, int _shift) { return GetBuffer(_buffer_index)[_shift].Get(); }

  /**
   *
   */
  double GetTailValue(int _buffer_index, int _shift) {
    ValueStorage<C> *_buff = GetBuffer(_buffer_index);
    return _buff[_buff.IsSeries() ? _shift : (ArraySize(_buff) - _shift - 1)].Get();
  }

  /**
   * Updates prev_calculated value used by indicator's OnCalculate method.
   */
  void SetPrevCalculated(int _prev_calculated) {
    prev_calculated = _prev_calculated;

    if (prev_calculated == 0) {
      Print(
          "Trying to call SetPrevCalculated() with 0. That could mean that there is insufficient historical data to "
          "use by OnCalculate(). Try to change INDICATOR_BUFFER_VALUE_STORAGE_HISTORY to higher value.");
      DebugBreak();
    }
  }

  /**
   * Resets prev_calculated value used by indicator's OnCalculate method.
   */
  void ResetPrevCalculated() { prev_calculated = 0; }

  /**
   * Returns prev_calculated value used by indicator's OnCalculate method.
   */
  int GetPrevCalculated(int _prev_calculated) { return prev_calculated; }

  template <typename X>
  void CallOnCalculate() {
    // C::Calculate(total, cache.prev_calculated, 0, price, cache.GetBuffer(0), ma_method, period);
  }
};
