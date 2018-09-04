export PATH=/opt/python3.6/bin:$PATH
export HOME=/root

set -x

iter_count=0
max_iterations=3

read -d '' PACKAGES <<EOT
sphinx-rtd-theme
deltasigma
pyeda
nbwavedrom
RISE==5.2.0
jupyter_contrib_nbextensions
jupyter_nbextensions_configurator
jupyterlab
imutils
dash==0.21.1
dash-renderer==0.13.0
dash-html-components==0.11.0
dash-core-components==0.23.0
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
