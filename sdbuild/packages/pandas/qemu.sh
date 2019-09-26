export HOME=/root

set -x

iter_count=0
max_iterations=3

read -d '' PACKAGES <<EOT
pandas==0.22.0
EOT

while [ -n "$PACKAGES" -a "$max_iterations" != "$iter_count" ];
do 
  printf '%s\n' "$PACKAGES" | while IFS= read -r p
  do 
    python3.6 -m pip install -v $p
    result=$?
    if [ $result != "0" ]; then
      echo "Package $p installed failed" >> pip.failed
      failed_packages="$failed_packages $p"
    fi
  done
  iter_count=$(( $iter_count + 1 ))
  PACKAGES="$failed_packages"
done
