local output_dir, cache_dir, program, build_name, build_hash, root_hash = ...

print ("program=" .. program .. " build_name=" .. build_name .. " build_hash=" .. build_hash .. " root_hash=" .. (root_hash or "none"))

if program == "wowt" or program == "wow_beta" or program == "wow" then

local casc = require("casc").open("http://us.patch.battle.net/" .. program .. "/#us"
  , { cache = cache_dir
    , verifyHashes = false, mergeInstall = true, requireRootFile = false
    , bkey = build_hash
    })

local files = { {suffix = "OSX-64", full = "World of Warcraft.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Beta-64", full = "World of Warcraft Beta.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Debug-64", full = "World of Warcraft Debug.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-GM-64", full = "World of Warcraft GM.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Game-Master-64", full = "World of Warcraft Game Master.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-GameMaster-64", full = "World of Warcraft GameMaster.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Internal-64", full = "World of Warcraft Internal.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Retail-64", full = "World of Warcraft Retail.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Test-64", full = "World of Warcraft Test.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-Test-Retail-64", full = "World of Warcraft Test Retail.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "OSX-64", full = "World of Warcraft-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Beta-64", full = "World of Warcraft Beta-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Debug-64", full = "World of Warcraft Debug-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-GM-64", full = "World of Warcraft GM-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Game-Master-64", full = "World of Warcraft Game Master-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-GameMaster-64", full = "World of Warcraft GameMaster-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Internal-64", full = "World of Warcraft Internal-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Retail-64", full = "World of Warcraft Retail-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Test-64", full = "World of Warcraft Test-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-Test-Retail-64", full = "World of Warcraft Test Retail-64.app/Contents/MacOS/World of Warcraft-64"}
              , {suffix = "OSX-GLReplayer", full = "World of Warcraft Internal.app/Contents/Helpers/GLReplayer.app/Contents/MacOS/GLReplayer"}
              , {suffix = "OSX-GLReplayer-64", full = "World of Warcraft Internal-64.app/Contents/Helpers/GLReplayer.app/Contents/MacOS/GLReplayer"}
              , {suffix = "WIN-64.exe", full = "Wow-64.exe",}
              , {suffix = "WIN-64.pdb", full = "Wow-64.pdb",}
              , {suffix = "WIN-Beta-64.exe", full = "WowB-64.exe",}
              , {suffix = "WIN-Beta-64.pdb", full = "WowB-64.pdb",}
              , {suffix = "WIN-Beta.exe", full = "WowB.exe",}
              , {suffix = "WIN-Beta.pdb", full = "WowB.pdb",}
              , {suffix = "WIN-Beta2.exe", full = "WoW-Beta.exe",}
              , {suffix = "WIN-Beta2.pdb", full = "WoW-Beta.pdb",}
              , {suffix = "WIN-Debug-64.exe", full = "WowD-64.exe",}
              , {suffix = "WIN-Debug-64.pdb", full = "WowD-64.pdb",}
              , {suffix = "WIN-Debug.exe", full = "WowD.exe",}
              , {suffix = "WIN-Debug.pdb", full = "WowD.pdb",}
              , {suffix = "WIN-GameMaster-64.exe", full = "WowGM-64.exe",}
              , {suffix = "WIN-GameMaster-64.pdb", full = "WowGM-64.pdb",}
              , {suffix = "WIN-GameMaster.exe", full = "WoWGM.exe",}
              , {suffix = "WIN-GameMaster.pdb", full = "WoWGM.pdb",}
              , {suffix = "WIN-Internal-64.exe", full = "WowI-64.exe",}
              , {suffix = "WIN-Internal-64.pdb", full = "WowI-64.pdb",}
              , {suffix = "WIN-Internal.exe", full = "WoWI.exe",}
              , {suffix = "WIN-Internal.pdb", full = "WoWI.pdb",}
              , {suffix = "WIN-P-64.exe", full = "WowP-64.exe",} -- UNKNOWN
              , {suffix = "WIN-P-64.pdb", full = "WowP-64.pdb",} -- UNKNOWN
              , {suffix = "WIN-P.exe", full = "WoWP.exe",} -- UNKNOWN
              , {suffix = "WIN-P.pdb", full = "WoWP.pdb",} -- UNKNOWN
              , {suffix = "WIN-Retail-64.exe", full = "WowR-64.exe",}
              , {suffix = "WIN-Retail-64.pdb", full = "WowR-64.pdb",}
              , {suffix = "WIN-Retail.exe", full = "WoWR.exe",}
              , {suffix = "WIN-Retail.pdb", full = "WoWR.pdb",}
              , {suffix = "WIN-Test-64.exe", full = "WowT-64.exe",}
              , {suffix = "WIN-Test-64.pdb", full = "WowT-64.pdb",}
              , {suffix = "WIN-Test-Retail-64.exe", full = "WowTR-64.exe",}
              , {suffix = "WIN-Test-Retail-64.pdb", full = "WowTR-64.pdb",}
              , {suffix = "WIN-Test-Retail.exe", full = "WoWTR.exe",}
              , {suffix = "WIN-Test-Retail.pdb", full = "WoWTR.pdb",}
              , {suffix = "WIN-Test.exe", full = "WoWT.exe",}
              , {suffix = "WIN-Test.pdb", full = "WoWT.pdb",}
              , {suffix = "WIN.exe", full = "Wow.exe",}
              , {suffix = "WIN.pdb", full = "Wow.pdb",}
              , {suffix = "WINAE-64.exe", full = "WowAE-64.exe",}
              , {suffix = "WINAE-64.pdb", full = "WowAE-64.pdb",}
              , {suffix = "WINAE.exe", full = "WowAE.exe",}
              , {suffix = "WINAE.pdb", full = "WowAE.pdb",}
              , {suffix = "RS-WIN.exe", full = "RenderService.exe",}
              , {suffix = "RS-WIN.pdb", full = "RenderService.pdb",}
              , {suffix = "RS-WIN-64.exe", full = "RenderService-64.exe",}
              , {suffix = "RS-WIN-64.pdb", full = "RenderService-64.pdb",}
              , {suffix = "RS-OSX-64", full = "RenderService.app/Contents/MacOS/RenderService"}
              , {suffix = "RS-OSX-64", full = "Render Service.app/Contents/MacOS/Render Service"}
              , {suffix = "RS-OSX-64", full = "RenderService.app/Contents/MacOS/World of Warcraft"}
              , {suffix = "RS-OSX-64", full = "Render Service.app/Contents/MacOS/World of Warcraft"}
              }

for _, file in pairs (files) do
  local output = output_dir .. "/" .. build_name .. "_" .. string.sub (build_hash, 0, 5) .. "_" .. file.suffix
  local cf = casc:readFile(file.full, nil, true)
  if cf then
    print (file.full .. " -> " .. output)
    assert (io.open (output, "w")):write (cf)
  end
end

if root_hash then
  local output = output_dir .. "/" .. build_name .. "_root"
  local cf = casc:readFileByContentHash (root_hash, nil, true)
  if cf then
     print (root_hash .. " -> " .. output)
     assert (io.open (output, "w")):write (cf)
  end
end

end
