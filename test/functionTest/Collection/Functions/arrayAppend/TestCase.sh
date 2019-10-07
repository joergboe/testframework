#--variantList='append1 append2'

declare -A explainTest=(
  ['append1']="append one item"
  ['append2']="append to empty array"
)

STEPS=(
  'echo ${explainTest[$TTRO_variantCase]}'
  'myTest'
  'checkArray'
)

myTest() {
  case "$TTRO_variantCase" in
    append1)
      myarr=( aa bb cc )
      arrayAppend 'myarr' "dd";;
    append2)
      myarr=( )
      arrayAppend 'myarr' 'aa' 'bb' 'cc' "dd";;
  esac
}

checkArray() {
  declare -p myarr
  local len=${#myarr[*]}
  if [[ $len -ne 4 ]]; then
    setFailure "myarr has wrong len: $len"
  else
    [[ ${myarr[0]} == 'aa' ]] && [[ ${myarr[1]} == 'bb' ]] && [[ ${myarr[2]} == 'cc' ]] && [[ ${myarr[3]} == 'dd' ]] && echo "Array is correct"
  fi
}
