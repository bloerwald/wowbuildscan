#include <vector>
#include <iostream>

#include "blte.hpp"


int main (int argc, char** argv)
{
  FILE* f (fopen (argv[1], "rb"));
  fseek (f, 0, SEEK_END);
  std::vector<char> data (ftell (f));
  fseek (f, 0, SEEK_SET);
  fread (data.data(), data.size(), 1, f);
  fclose (f);

  auto output (decode_blte (data));

  fwrite (output.data(), output.size(), 1, stdout);

  return 0;
}
