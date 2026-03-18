#!/usr/bin/env bash
#!/usr/bin/env bash
# <xbar.title>Pushbullet Watcher</xbar.title>
# <xbar.version>0.1</xbar.version>
# <xbar.author>Felipe Mattos</xbar.author>
# <xbar.author.github>fm4tt0s</xbar.author.github>
# <xbar.desc>Watch for Pushbullet pushes for files and open it on Chrome</xbar.desc>
# <xbar.image>https://play-lh.googleusercontent.com/I1rEarjkcHM2Yq13tYxJtg8idaYLK6kGXI0AMSm5VLMl5_nPwVuR4UFhAOSZo83CBe8</xbar.image>
# <xbar.dependencies></xbar.dependencies>
#
#

# config
# base
_this="$(basename "${BASH_SOURCE[0]}")"
_mypath="$( cd "$(dirname "${BASH_SOURCE[0]}")" || return 0 ; pwd -P )"
# api token
_token="YOUR_ACCESS_TOKEN_HERE"
# where the pushes are sent to
_targetiden="YOUR_DEVICE_IDEN_HERE"
# where to save the seen pushes
_seenfile="${_mypath}/${_this//.sh/.seen}.off"
# temp file for building the menu list
_tempfile="/tmp/${_this//.sh/.temp}.off"
# pushes age in seconds
_pushage=86400 # 24h

# start fresh
rm -f "${_tempfile}"
touch "${_tempfile}"

# functions
# get epoch from X seconds ago
f_getepoch() {
  date "-v-${1}S" +%s
}

# get the pushes from the API modified after the given epoch
f_getpushes() {
  curl -s --fail -XGET \
    --header "Access-Token: ${_token}" \
    "https://api.pushbullet.com/v2/pushes?modified_after=${1}&active=true"
    if ! echo "${_response}" | /opt/homebrew/bin/jq -e '.pushes' &>/dev/null; then
      echo "➡️⚠️"
      echo "---"
      echo "API error"
      echo "${_response}"
      exit 1
    fi
}

# check if the push iden is already seen/open
f_isseen() {
  grep -qF "${1};" "${_seenfile}" 2>/dev/null
}

# save the push iden and file url to the seen file
f_save() {
  echo "${1};${2}" >> "${_seenfile}"
  echo "${2}" >> "${_tempfile}"
}

# open the push (file url) with the default browser
f_open() {
  open "${1}"
}

# main
_epoch=$(f_getepoch "${_pushage}")
_response=$(f_getpushes "${_epoch}")
touch "${_tempfile}"
# iterate over the pushes and open the file url if not seen before
_pushlist=$(echo "${_response}" | /opt/homebrew/bin/jq -r --arg tid "${_targetiden}" '.pushes[] | select(.target_device_iden == $tid) | select(.file_url != null) | "\(.iden)|\(.file_url)"')
while IFS="|" read -r _pushiden _fileurl; do
    if ! f_isseen "${_pushiden}"; then
      f_open "${_fileurl}"
      f_save "${_pushiden}" "${_fileurl}"
    fi
done <<< "${_pushlist}"

_i=$(grep -c '' "${_tempfile}")
[[ $_i -gt 0 ]] && _color="color=red" || _color="color=gray"
echo "➡️ ${_i} | ${_color}"
echo "---"
echo "Last checked at $(date)"
echo "---"
if [[ -s "${_tempfile}" ]]; then
  while IFS= read -r _url; do
  _i=$(python3 -c "import urllib.parse,sys; print(urllib.parse.unquote(sys.argv[1]))" "${_url##*/}")
    echo "${_i} | href='${_url}' terminal=false"
  done < "${_tempfile}"
else
  echo "No new pushes found."
fi
exit 0
