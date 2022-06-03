#!/usr/bin/env bash
#shopt -s extglob 
#=====================HEADER=========================================|
#AUTOR
# Eduardo Correia dos Santos <eduadro137.dev
#
#LICENÇA
# mit
#
# Gerador de json para cgi-bin a partir do arquivo /proc/cpuinfo
# Funciona em todos os cpuinfo
#====================================================================|

file_cpuinfo=$(</proc/cpuinfo)

mycat() {
  local REPLY
  read -r -d '' || printf '%s' "$REPLY"
}

wc_line() {
  local file=$1 position=$2
  local line_Count size name
  while IFS=':' read -r name __; do
    name=${name//$'\t'/}
    line_Count=$((line_Count+1))
    if [[ "$line_Count" -gt "$position" ]] ;then
      if [[ $name != "processor" && -n $name ]] ;then
        size=$((size+1))
      else
        break
      fi
    fi
  done <<< "$file"
  echo $size # pseudo return
}

list_size() {
  local count_Line
  while read;do
    ((count_Line++))
  done <<< "$file_cpuinfo"
  echo $count_Line # pseudo return
}


count_list() {
  local name block
  while IFS=':' read -r name __;do
    name=${name//$'\t'/}
    [[ $name == "processor" ]] && block=$((block+1))
  done <<< "$file_cpuinfo"
  echo $block # pseudo return
}

flags() {
  local argsflags=($2)
  local argsname=$1
  local comma
  local flags_count
  local flag
  printf "\t\t\"%s\": [ " "$argsname"
  for flag in "${argsflags[@]}"; do
    ((flags_count++))
    [ "$flags_count" -eq 1 ] && tab="" || tab="\t\t\t"
    [ "$flags_count" -eq "${#argsflags[@]}" ] && comma=" ]," || comma=","
    printf "%b\"%s\"%b\n" "$tab" "$flag" "$comma"
  done
}

mycat << STDIN
Content-type: application/json; charset=utf-8

{

$(
  declare -i line_Count_Block line_Count
  block_size=$(count_list)
  file_size=$(list_size)
  while IFS=':' read -r  name value; do
    value=${value# } name=${name//$'\t'/}
    line_Count_Block=$((line_Count_Block+1))
    line_Count=$((line_Count+1))
    if [[ $name == "processor" ]]; then
      size=$(wc_line "$file_cpuinfo" "$line_Count")
      line_Count_Block=0 
      ((block_count++))
      printf "\t\"%s_%s\": {\n" "$name" "$value"
    else
      if [[ $name == "flags" || $name == "vmx flags" || $name == "bugs" || $name == "Features" ]]; then
        flags "$name" "$value"
      elif [[ -n "$name" ]]; then
      printf "\t\t\"%s\": \"%s\"" "${name}" "${value:=null}" 
        if [[ $line_Count_Block -eq $size ]]; then
          [[ "$block_count" -eq "$block_size" && $file_size -eq $line_Count ]] && block_comma="\n\t}\n" || block_comma="\n\t},\n" 
          printf "%b\n" $block_comma
        elif [[ $file_size -ne $line_Count ]]; then
          printf ",\n"
        fi
      
      fi
    fi
   done <<< "$file_cpuinfo"

)

}
STDIN
