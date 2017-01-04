#!/bin/bash

set -euo pipefail

extracted_archive="$(readlink -f "${1}")"
build_scan_dir="$(readlink -f "${2}")"

function pretty_version()
{
  local maybe_branch=${1:-}
  local maybe_build=${2:-}

  if test -n "${maybe_branch}" && test -n "${maybe_build}"
  then
    echo "${maybe_branch}.${maybe_build}"
  elif test -n "${maybe_branch}"
  then
    echo "${maybe_branch}.?"
  elif test -n "${maybe_build}"
  then
    echo "${maybe_build}"
  else
    echo "unknown-version"
  fi
}

( if grep -q Inspector.Build *
  then
    grep -l Inspector.Build * \
      | while read f
        do
          function attrib()
          {
            attribute="${1}"
            prefix="${2:-}"

            if grep -q "<${attribute}> " "${f}"
            then
              echo -n "${prefix}"
              strings "${f}" \
                | grep "^<${attribute}> " \
                | sed -e "s,^<${attribute}> ,,"
            fi
          }
          application=$(attrib "Application")
          application=${application:-$(attrib "Inspector.ProjectId" "App-")}
          application=${application:-unknown-application}

          echo "VERSION ${application} $(pretty_version "$(attrib "Inspector.Branch")" "$(attrib "Inspector.BuildNumber")")"
        done
  fi

  if grep -q '<key>BlizzardFileVersion</key>' *
  then
    grep -l '<key>BlizzardFileVersion</key>' * \
      | while read f
        do
          function attrib()
          {
            attribute="${1}"
            prefix="${2:-}"

            if grep -q "<key>${attribute}</key>" "${f}"
            then
              echo -n "${prefix}"
              strings "${f}" \
                | grep -A 1 "<key>${attribute}</key>" \
                | tail -n1 \
                | sed -e 's,[[:space:]]*<\([a-z]*\)>\([^<]*\)</\1>[[:space:]]*,\2,'
            fi
          }

          application=$(attrib CFBundleExecutable)
          application=${application/BrowserProxy/WowBrowserProxy}

          echo "VERSION ${application} $(attrib BlizzardFileVersion)"
        done
  fi
) | sort -u

file --brief \
     --mime-type \
     --magic-file "${build_scan_dir}/wow.mg:$(dirname $(which file))/../share/misc/magic" \
     --no-pad \
     --uncompress \
     * \
  | sort \
  | uniq -c \
  | sort -n
