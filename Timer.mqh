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
#include "Math.h"
#include "Object.mqh"

/**
 * Class to provide functions to deal with the timer.
 */
class Timer : public Object {
 protected:
  // Variables.
  string name;
  int index;
  uint data[];
  uint start, end;
  ulong max;

 public:
  /**
   * Class constructor.
   */
  Timer(string _name = "") : index(-1), name(_name){};

  /* Main methods */

  /**
   * Start the timer.
   */
  void Start() { start = GetTickCount(); }

  /**
   * Stop the timer.
   */
  Timer *Stop() {
    end = GetTickCount();
    ArrayResize(this PTR_DEREF data, ++this PTR_DEREF index + 1, 10000);
    data[this PTR_DEREF index] = fabs(this PTR_DEREF end - this PTR_DEREF start);
    max = fmax(data[this PTR_DEREF index], this PTR_DEREF max);
    return GetPointer(this);
  }

  /* Misc */

  /**
   * Print the current timer times.
   */
  Timer *PrintSummary() {
    Print(ToString());
    return GetPointer(this);
  }

  /**
   * Print the current timer times when maximum value is reached.
   */
  Timer *PrintOnMax(ulong _min = 1) {
    return data[index] > _min && data[this PTR_DEREF index] >= this PTR_DEREF max ? PrintSummary() : GetPointer(this);
  }

  /* Getters */

  /**
   * Stop the timer.
   */
  uint GetTime(uint _index) { return data[_index]; }
  uint GetTime() { return GetTickCount() - this PTR_DEREF start; }

  /**
   * Returns timer name.
   */
  string GetName() { return this PTR_DEREF name; }

  /**
   * Get the sum of all values.
   */
  ulong GetSum() {
    uint _size = ArraySize(this PTR_DEREF data);
    ulong _sum = 0;
    for (uint _i = 0; _i < _size; _i++) {
      _sum += data[_i];
    }
    return _sum;
  }

  /**
   * Get the median of all values.
   */
  uint GetMedian() {
    if (this PTR_DEREF index >= 0) {
      ArraySort(this PTR_DEREF data);
    }
    return this PTR_DEREF index >= 0 ? this PTR_DEREF data[this PTR_DEREF index / 2] : 0;
  }

  /**
   * Get the minimum time value.
   */
  uint GetMin() { return this PTR_DEREF index >= 0 ? this PTR_DEREF data[ArrayMinimum(this PTR_DEREF data)] : 0; }

  /**
   * Get the maximal time value.
   */
  uint GetMax() {
    int _index = this PTR_DEREF index >= 0 ? ArrayMaximum(this PTR_DEREF data) : -1;
    return _index >= 0 ? data[_index] : 0;
  }

  /* Inherited methods */

  /**
   * Print timer times.
   */
  virtual const string ToString() {
    return StringFormat("%s(%d)=%d-%dms,med=%dms,sum=%dms", GetName(), ArraySize(this PTR_DEREF data), GetMin(),
                        GetMax(), GetMedian(), GetSum());
  }

  /**
   * Returns weight of the object.
   */
  virtual double GetWeight() { return (double)GetSum(); }
};
