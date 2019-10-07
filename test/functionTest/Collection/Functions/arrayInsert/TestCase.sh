#--variantList='insert1 insert2 insertAtStart insertAtEnd pasteEnd'

declare -A explainTest=(
  ['insert1']="insert one element"
  ['insert2']="insert 2 elems"
  ['insertAtStart']="insert 2 elements at start"
  ['insertAtEnd']="insert 2 elements at end"
  ['pasteEnd']="insert paste end"
)

STEPS=(
  'echo ${explainTest[$TTRO_variantCase]}'
  'myTest'
  'checkArray'
)

myTest() {
  case "$TTRO_variantCase" in
    insert1)
      myarr=( 'a a' 'c c' 'dd ' )
      arrayInsert 'myarr' 1 "b b";;
    insert2)
      myarr=( 'a a' 'dd ' )
      arrayInsert 'myarr' 1 "b b" 'c c';;
    insertAtStart)
      myarr=( 'c c' 'dd ' )
      arrayInsert 'myarr' 0 "a a" 'b b';;
    insertAtEnd)
      myarr=( 'a a' 'b b' )
      arrayInsert 'myarr' 2 "c c" 'dd ';;
    pasteEnd)
      myarr=( 'a a' 'b b' )
      arrayInsert 'myarr' 3 "c c" 'dd ';;
  esac
}

checkArray() {
  declare -p myarr
  local len=${#myarr[*]}
  if [[ $len -ne 4 ]]; then
    setFailure "myarr has wrong len: $len"
  else
    [[ ${myarr[0]} == 'a a' ]] && [[ ${myarr[1]} == 'b b' ]] && [[ ${myarr[2]} == 'c c' ]] && [[ ${myarr[3]} == 'dd ' ]] && echo "Array is correct"
  fi

}
