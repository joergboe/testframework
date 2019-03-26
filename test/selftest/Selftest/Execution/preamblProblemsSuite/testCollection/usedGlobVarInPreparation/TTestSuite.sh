#--variantCount=2

if [[ $TTRO_variantSuite -eq 0 ]]; then
  echo "------------------- Suite init ----------------"
  timeout=155
fi

PREPS=myfunc

myfunc() {
  if [[ $TTRO_variantSuite -eq 1 ]]; then
    echo "------------------- Suite prep ----------------"
    timeout=1000
  fi
}
