if [ -z "$BOARD" ]; then
  if [ -e /proc/device-tree/chosen/pynq_board ]; then
    export BOARD=`cat /proc/device-tree/chosen/pynq_board | tr '\0' '\n'`
  else
    export BOARD=Unknown
  fi
fi
