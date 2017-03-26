local file, output, cache_dir, program, build_hash = ...

local casc = require("casc").open("http://us.patch.battle.net/" .. program .. "/#us"
  , { cache = cache_dir
    , verifyHashes = false, mergeInstall = true, requireRootFile = false
    , bkey = build_hash
    })


local cf = casc:readFile(file, nil, true)
if cf then
   assert (io.open (output, "w")):write (cf)
end
