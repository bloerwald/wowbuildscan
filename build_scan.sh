#!/bin/bash
set -euo pipefail

silent=${silent:-false}

# notification service config, directories, ...
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/config.inc"

cd "${build_scan_dir}"
export LUA_PATH="./?.lua;${lua_casc_dir}/?.lua;${lua_casc_dir}/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/local/lib/lua/5.1/?/init.lua"

programs=(wow_beta wow wowt herot d3 d3cn d3t hero prot prodev)
portals=(eu us public-test beta xx cn)
cdn="http://blzddist1-a.akamaihd.net/tpr/wow" # http://blzddist2-a.akamaihd.net/tpr/wow

function portal_url() { portal=${1}; shift; program=${1}
  echo "http://${portal}.patch.battle.net:1119/${program}"
                      }
function hash_url() { base=${1}; shift; type=${1}; shift; hash=${1}
  echo "${base}/${type}/${hash:0:2}/${hash:2:2}/${hash}"
}

touch .crawled_build_hashes
touch .crawled_archive_hashes
mkdir -p "${cache_dir}"

for program in ${programs[@]}
do
  for portal in ${portals[@]}
  do
    is_first=true
    (timeout 3 curl -s $(portal_url ${portal} ${program})/versions || true) | \
      while read line
      do
#        echo $line >&2
        if $is_first
        then
          if [[ $line != "Region!STRING:0|BuildConfig!HEX:16|CDNConfig!HEX:16|BuildId!DEC:4|VersionsName!String:0"
             && $line != "Region!STRING:0|BuildConfig!HEX:16|CDNConfig!HEX:16|Keyring!HEX:16|BuildId!DEC:4|VersionsName!String:0|ProductConfig!HEX:16"
             && $line != "Region!STRING:0|BuildConfig!HEX:16|CDNConfig!HEX:16|KeyRing!HEX:16|BuildId!DEC:4|VersionsName!String:0|ProductConfig!HEX:16"
             ]]
          then
            echo "BAD HEADER: $line" >&2
            exit 1
          else
            is_first=false
          fi
        else
          echo $line | sed -e "s,[a-z]*|\([0-9a-f]*\)|\([0-9a-f]*\)|*[0-9]*|\([0-9\.]*\).*,\1 \2 \3 ${program},"
        fi
      done
  done
done | \
sort -u | \
while read buildconfig cdnconfig version program
do
  echo BUILD ${buildconfig} ${version} ${program}
  for build in $(timeout 3 curl -s "$(hash_url ${cdn} config ${cdnconfig})" | grep ^builds | sed -e 's,^builds = ,,')
  do
    echo BUILD ${build} ${version} ${program}
  done
  for archive in $(timeout 3 curl -s "$(hash_url ${cdn} config ${cdnconfig})" | grep ^archives | sed -e 's,^archives = ,,')
  do
    echo ARCHIVE ${archive} --no-- ${program}
  done
done | \
sort -u | \
while read type build version program
do
  if [[ $type == BUILD ]]
  then
    set +e
    build_name="$(timeout 3 curl -s "$(hash_url ${cdn} config ${build})" | grep ^build-name | sed -e 's,^build-name = ,,')"
    if [[ -z ${build_name} ]]
    then
      case ${program} in
        d3) build_name=Diablo3-${version}_Retail ;;
        d3cn) build_name=Diablo3-${version}_Retail-CN ;;
        d3t) build_name=Diablo3-${version}_PTR ;;
        hero) build_name=HotS-${version}_Retail ;;
        herot) build_name=HotS-${version}_PTR ;;
        hsb) build_name=HotS-${version}_Beta ;;
        pro) build_name=Overwatch-${version}_Retail ;;
        prodev) build_name=Overwatch-${version}_Beta ;;
        prot) build_name=Overwatch-${version}_PTR ;;
        sc2) build_name=Starcraft2-${version}_Retail ;;
        s2) build_name=Starcraft2-${version}_Retail ;;
        s2b) build_name=Starcraft2-${version}_Beta ;;
        s2t) build_name=Starcraft2-${version}_PTR ;;
        wow) build_name=$(echo ${version}_Retail | sed -e 's,\(.*\)\.\([0-9]*\)_\([a-z_]*\),WOW-\2patch\1_\3,') ;;
        wow_beta) build_name=$(echo ${version}_Beta | sed -e 's,\(.*\)\.\([0-9]*\)_\([a-z_]*\),WOW-\2patch\1_\3,') ;;
        wowt) build_name=$(echo ${version}_PTR | sed -e 's,\(.*\)\.\([0-9]*\)_\([a-z_]*\),WOW-\2patch\1_\3,') ;;
      esac
    fi
    build_key="${build}"
    root_key="$(timeout 3 curl -s "$(hash_url ${cdn} config ${build})" | grep ^root | sed -e 's,^root = ,,')"
    set -e
    if [[ ! -z ${build_name} && ! -z ${build_key} ]]
    then
      echo "BUILD ${program} ${build_name} ${build_key} ${root_key}"
    else
      echo "failed reading from config! ${build_name} ${build_key} ${root_key}" >&2
    fi
  elif [[ $type == ARCHIVE ]]
  then
    echo "ARCHIVE ${program} ${build}"
  fi
done | \
  sort -u | \
  shuf | \
while read type program a1 a2 a3
do
#  echo $program $type $a1 $a2 $a3 >&2
  if [[ $type == BUILD ]]
  then
    set +u
    build="$a1 $a2 $a3"
    set -u
    if ! grep -q "^${build}$" .crawled_build_hashes
    then
      if ! $silent
      then
        set +e
        curl -s "https://api.telegram.org/${telegram_api}/sendMessage" \
             --data "chat_id=${telegram_chat}" \
             --data text="🍾 $(echo ${build} | sed -e 's, .*,,')" >/dev/null || echo "telegram failed"
        echo -e "PASS ${irc_account_PASS}\nNICK ${irc_nick}\nUSER ${irc_USER}\nPRIVMSG ${irc_channel} :buildscan: ${build}\nQUIT\n" | nc ${irc_host} ${irc_port} >/dev/null || echo "irc failed"
        set -e
      fi

      lua "${build_scan_dir}/download_files_for_build.lua" "${output_dir}" "${cache_dir}" "${program}" ${build} \
        | if ! $silent
          then
            mail -s "BUILD ${build}" "${mail_receiver}"
          fi

      echo "${build}" >> .crawled_build_hashes
    fi
  elif [[ $type == ARCHIVE ]]
  then
    archive=$a1
    if ! grep -q "^${archive}$" .crawled_archive_hashes
    then
      echo new archive: $archive

      pushd "${cache_dir}" >/dev/null
      wget --quiet --continue "$(hash_url $cdn data $archive)"{,.index}
      mkdir -p ${archive}.extract
      pushd "${archive}.extract" >/dev/null
      "${build_scan_dir}/index-parse" "../${archive}"

      "${build_scan_dir}/analyse_archive.sh" "${PWD}" "${build_scan_dir}" | tee "${cache_dir}/build_scan.tmp"

      if ! $silent
      then
        curl -s "https://api.telegram.org/${telegram_api}/sendMessage" \
             --data "chat_id=${telegram_chat}" \
             --data text="🍾 ARCHIVE ${archive}: $(echo; sed -e 's,^ *,,' -e 's,\([0-9]\) ,\1× ,' "${cache_dir}/build_scan.tmp")" >/dev/null || echo "telegram failed"
        if grep -q VERSION "${cache_dir}/build_scan.tmp"
        then
          echo -e "PASS ${irc_account_PASS}\nNICK ${irc_nick}\nUSER ${irc_USER}\nPRIVMSG ${irc_channel} :buildscan: archive ${archive} with$(grep VERSION "${cache_dir}/build_scan.tmp" | sed -e 's,VERSION,,' | tr '\n' ', ' | sed -e 's/,$//')\nQUIT\n" | nc ${irc_host} ${irc_port} >/dev/null || echo "irc failed"
        fi
      fi

      popd >/dev/null
      popd >/dev/null

      echo "${archive}" >> .crawled_archive_hashes
    fi
  fi
done

rm -rf "${cache_dir}"
