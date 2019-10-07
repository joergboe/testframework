#--variantList='delete1 deleteAtStart deleteAtEnd pasteEnd'

declare -A explainTest=(
  ['delete1']="delete one element"
  ['deleteAtStart']="delete 2 elements at start"
  ['deleteAtEnd']="delete 1 elements at end"
  ['pasteEnd']="delete paste end"
)

STEPS=(
  'echo ${explainTest[$TTRO_variantCase]}'
  'myTest'
  'checkArray'
)

myTest() {
  case "$TTRO_variantCase" in
    delete1)
      myarr=( 'a a' "b b" 'xxx' 'c c' 'dd ' )
      arrayDelete 'myarr' 2;;
    deleteAtStart)
      myarr=( 'xxx' 'a a' "b b" 'c c' 'dd ' )
      arrayDelete 'myarr' 0;;
    deleteAtEnd)
      myarr=( 'a a' "b b" 'c c' 'dd ' 'xxx' )
      arrayDelete 'myarr' 4;;
    pasteEnd)
      myarr=( 'a a' "b b" 'c c' 'dd ' )
      arrayDelete 'myarr' 4;;
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
