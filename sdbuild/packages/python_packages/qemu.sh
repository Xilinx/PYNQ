export PATH=/opt/python3.6/bin:$PATH
export HOME=/root

set -x

# This shouldn't be necessary but pygraphviz's installation doesn't work properly
export LIBRARY_PATH=/opt/python3.6/lib
iter_count=0
max_iterations=3

read -d '' PACKAGES <<EOT
pygraphviz --install-option=--include-path=/usr/include/graphviz --install-option=--library-path=/usr/lib/graphviz/
beautifulsoup4
Bottleneck
cffi
chardet
html5lib
jupyter
jupyterlab
jupyter_contrib_nbextensions
lxml
nbsphinx
networkx
numexpr
openpyxl
path.py
pipdeptree
plotly
psutil
pytest-ordering
PyYAML
rk
sphinx-rtd-theme
SQLAlchemy
ssh-import-id
urllib3
xlrd
XlsxWriter
xlwt
scipy
Pillow
pandas
deltasigma
seaborn
sympy
uvloop
transitions
pyeda
pycurl
EOT

pip3.6 install numpy requests
while [ -n "$PACKAGES" -a "$max_iterations" != "$iter_count" ];
do 
  printf '%s\n' "$PACKAGES" | while IFS= read -r p
  do 
    pip3.6 install -v $p
    result=$?
    if [ $result != "0" ]; then
      echo "Package $p installed failed" >> pip.failed
      failed_packages="$failed_packages $p"
    fi
  done
  iter_count=$(( $iter_count + 1 ))
  PACKAGES="$failed_packages"
done
