#pragma once

#include <vector>

std::vector<char> decode_blte (char const*, std::size_t);

template<typename T, typename... A>
  std::vector<char> decode_blte (std::vector<T, A...> const& data)
{
  return decode_blte
    ( static_cast<char const*> (static_cast<void const*> (data.data()))
    , data.size() * sizeof (T)
    );
}
