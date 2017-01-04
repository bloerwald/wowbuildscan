#include "blte.hpp"

#include <iostream>
#include <vector>
#include <stdexcept>

#include "bigendian.hpp"
#include <zlib.h>

struct BLTE_Header
{
  uint32_t signature;
  uint32_BE_t headerSize;
};

struct BLTE_ChunkInfoEntry
{
  uint32_BE_t compressedSize;
  uint32_BE_t decompressedSize;
  char checksum[16];
};

struct BLTE_ChunkInfo
{
  uint8_t unknownFlags;
  uint24_BE_t chunkCount;
  BLTE_ChunkInfoEntry entries[/*chunkCount*/0];
};

std::vector<char> decode_blte (char const* ptr, size_t size)
{
  std::vector<char> output;

  char const* end (ptr + size);

  BLTE_Header const& header (*reinterpret_cast<BLTE_Header const*> (ptr));
  ptr += sizeof (BLTE_Header);

  if (header.signature != 'ETLB')
  {
    throw std::logic_error ("not BLTE encoded");
  }

  struct info
  {
    uint32_t compressed;
    uint32_t uncompressed;
    info (uint32_t c, uint32_t u) : compressed (c), uncompressed (u) {}
  };
  std::vector<info> chunks;

  if (header.headerSize)
  {
    BLTE_ChunkInfo const& info (*reinterpret_cast<BLTE_ChunkInfo const*> (ptr));
    uint24_t nChunks (info.chunkCount);
    for (uint32_t i (0); i < uint32_t (nChunks); ++i)
    {
      chunks.emplace_back
        (info.entries[i].compressedSize, info.entries[i].decompressedSize);
    }

    ptr += header.headerSize - sizeof (BLTE_Header);
  }
  else
  {
    chunks.emplace_back (size - sizeof (BLTE_Header), 0);
  }

  for (auto& chunk : chunks)
  {
    switch (*ptr)
    {
    case 'N':
      output.insert (output.end(), ptr + 1, ptr + 1 + chunk.uncompressed);
      break;
    case 'E':
      {
        std::cerr << "ENCRYPTED BLOCK, writing zeros!\n";
        std::vector<char> zeros;// (chunk.uncompressed);
        output.insert (output.end(), zeros.begin(), zeros.end());
      }
      break;
    case 'Z':
      {
        z_stream strm;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.avail_in = chunk.compressed - 1;
        strm.next_in = const_cast<Bytef*> (reinterpret_cast<unsigned char const*> (ptr + 1));
        if (inflateInit(&strm) != Z_OK)
        {
          throw std::runtime_error ("bad zlib init");
        }

        std::vector<unsigned char> out (chunk.uncompressed);
        strm.avail_out = out.size();
        strm.next_out = out.data();
        int i;
        if ((i = inflate(&strm, Z_NO_FLUSH)) != Z_STREAM_END)
        {
          throw std::runtime_error ("bad inflate " + std::to_string (i));
        }

        inflateEnd(&strm);

        output.insert (output.end(), out.begin(), out.end());
      }
      break;
    case 'F':
      {
        std::cerr << "RECURSIVE BLOCK, writing zeros!\n";
        std::vector<char> zeros;// (chunk.uncompressed);
        output.insert (output.end(), zeros.begin(), zeros.end());
      }
      break;
    default:
      throw std::logic_error ("unknown BLTE type!");
    }

    ptr += chunk.compressed;
  }

  if (ptr != end)
  {
    throw std::logic_error
      ("didn't read whole data! " + std::to_string (end - ptr) + " bytes left.");
  }

  return output;
}
