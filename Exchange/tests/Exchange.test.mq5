//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @file
 * Test functionality of Exchange class.
 */

// Includes.
#include "../../Test.mqh"
#include "../Exchange.h"

// Test classes.
class ExchangeDummy : public Exchange {};

// Global variables.
ExchangeDummy ex_dummy;

/**
 * Implements OnInit().
 */
int OnInit() {
  bool _result = true;
  return _result && GetLastError() == ERR_NO_ERROR ? INIT_SUCCEEDED : INIT_FAILED;
}
