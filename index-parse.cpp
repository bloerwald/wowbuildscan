#include <vector>
#include <iostream>
#include <cstdio>
#include <algorithm>
#include <array>
#include <iomanip>
#include <sstream>

#include "blte.hpp"
#include "bigendian.hpp"

struct index_entry
{
  std::array<char, 16> hash;
  uint32_BE_t size;
  uint32_BE_t offset;

  bool has_data() const
  {
    return std::any_of (hash.begin(), hash.end(), [](char c) { return !!c; });
  }
  friend std::ostream& operator<< (std::ostream& os, index_entry const& e)
  {
    auto f (os.flags());
    os << std::hex;
    for (size_t x : e.hash)
    {
      os << std::setfill ('0') << std::setw (2) << (x & 0xFF);
    }
    os << " " << std::setw (8) << e.offset;
    os << " " << std::setw (8) << e.size;
    os.flags (f);
    return os;
  }

  std::string hash_as_str() const
  {
    std::ostringstream oss;
    oss << std::hex;
    for (size_t x : hash)
    {
      oss << std::setfill ('0') << std::setw (2) << (x & 0xFF);
    }
    return oss.str();
  }
};

struct index_block
{
  std::array<index_entry, 0x1000 / sizeof (index_entry)> entries;
  char padding[0x1000 - sizeof (entries)];
};

int main (int argc, char** argv)
{
  for (int arg (1); arg < argc; ++arg)
  {
    std::string blob (argv[arg]);
    std::string index (blob + ".index");
    FILE* f (fopen (index.c_str(), "rb"));
    fseek (f, 0, SEEK_END);
    std::vector<index_block> data (ftell (f) / sizeof (index_block));
    fseek (f, 0, SEEK_SET);
    fread (data.data(), sizeof (index_block), data.size(), f);
    fclose (f);

    FILE* b (fopen (blob.c_str(), "rb"));

    for (auto& block : data)
    {
      for (auto& entry : block.entries)
      {
        if (entry.has_data())
        {
          try
          {
            fseek (b, entry.offset, SEEK_SET);
            std::vector<char> data (entry.size);
            fread (data.data(), entry.size, 1, b);
            std::vector<char> out (decode_blte (data));

            FILE* o (fopen (entry.hash_as_str().c_str(), "wb"));
            fwrite (out.data(), out.size(), 1, o);
            fclose (o);
          }
          catch (std::exception const& ex)
          {
            std::cerr << "EX: " << ex.what() << "\n";
          }
        }
      }
    }

    fclose (b);
  }
  return 0;
}
