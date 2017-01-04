#pragma once

#include <iostream>
#include <cstdint>

struct uint16_BE_t
{
  uint16_t _;
  operator uint16_t() const
  {
    return ( (((_ >> 0) & 0xFF) << 8)
           | (((_ >> 8) & 0xFF) << 0)
           );
  }
  friend std::ostream& operator<< (std::ostream& os, uint16_BE_t const& x)
  {
    return os << uint16_t (x);
  }
};

struct uint24_t
{
  uint8_t _0;
  uint8_t _1;
  uint8_t _2;
  operator uint32_t() const
  {
    return (_0 << 0) | (_1 << 8) | (_2 << 16);
  }
  friend std::ostream& operator<< (std::ostream& os, uint24_t const& x)
  {
    return os << uint32_t (x);
  }

  uint24_t (uint32_t x)
    : _0 (x)
    , _1 (x >> 8)
    , _2 (x >> 16)
  {}
};

struct uint24_BE_t
{
  uint24_t _;
  operator uint24_t() const
  {
    uint32_t x (_);
    return ( (((x >>  0) & 0xFF) << 16)
           | (((x >>  8) & 0xFF) <<  8)
           | (((x >> 16) & 0xFF) <<  0)
           );
  }
  friend std::ostream& operator<< (std::ostream& os, uint24_BE_t const& x)
  {
    return os << uint24_t (x);
  }
};

struct uint32_BE_t
{
  uint32_t _;
  operator uint32_t() const
  {
    return ( (((_ >>  0) & 0xFF) << 24)
           | (((_ >>  8) & 0xFF) << 16)
           | (((_ >> 16) & 0xFF) <<  8)
           | (((_ >> 24) & 0xFF) <<  0)
           );
  }
  friend std::ostream& operator<< (std::ostream& os, uint32_BE_t const& x)
  {
    return os << uint32_t (x);
  }
};
