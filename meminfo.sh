#!/usr/bin/env bash
#shopt -s extglob 
#=====================HEADER=========================================|
#AUTOR
# Eduardo Correia dos Santos <eduadro137.dev
#
#LICENÇA
# mit
#
# Gerador de json para cgi-bin a partir do arquivo /proc/meminfo
# Funciona em todos os meminfo
#====================================================================|
set -e
declare -A meminfo=()

mycat() {
  local REPLY
  read -r -d '' || printf '%s' "$REPLY"
}

while read -r name value; do 
    meminfo["${name%:}"]=$(
        if [ "${value%kB}" -le 1024 ]; then
            printf "%s"  "$value"
        elif [[ ${value%kB} -ge 1024 && ${value%kB} -le 1048576 ]]; then
            printf "%.3f MB" $((10**3*${value%kB}/1024))e-3
        elif [ "${value%kB}" -ge 1048576 ]; then
            printf "%.3f GB" $((10**3*${value%kB}/1048576))e-3
        fi
    )
done < /proc/meminfo

mycat << EOF
Content-type: application/json; charset=utf-8

{
$(
    for name in "${!meminfo[@]}"; do
        ((line_count++))
        [ "$line_count" -eq "${#meminfo[@]}" ] && comma="" || comma=","
        printf "\t\"%s\": \"%s\"%s\n" "$name" "${meminfo[$name]}" "$comma"
    done
) 
}
EOF
