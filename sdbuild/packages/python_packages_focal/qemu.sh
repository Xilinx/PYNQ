export HOME=/root

set -x
set -e


cat > requirements.txt <<EOT
numpy==1.20.2
Click==7.0
CppHeaderParser==2.7.4
dash==0.21.1
dash-core-components==0.23.0
dash-html-components==0.12.0
dash-renderer==0.13.0
deltasigma==0.2.2
Flask==1.1.1
Flask-Compress==1.4.0
imutils==0.5.3
itsdangerous==1.1.0
Jinja2==2.10.1
json5==0.8.5
jsonschema==3.0.2
jupyter-core==4.7.1
notebook==6.3.0
qtconsole==5.0.3
jupyter-console==6.4.0
ipykernel==5.5.3
ipywidgets==7.6.3
nbconvert==6.0.7
nbformat==5.1.3
nbsphinx==0.8.3
jupyter-contrib-core==0.3.3
jupyter-contrib-nbextensions==0.5.1
jupyter-highlight-selected-word==0.2.0
jupyter-latex-envs==1.4.6
jupyter-nbextensions-configurator==0.4.1
jupyterlab==3.0.14
jupyterlab-server==2.4.0
jupyter-js-widgets-nbextension==0.0.2.dev0
nbwavedrom==0.2.0
parsec==3.4
patsy==0.5.1
plotly==4.14.3
plotly-express==0.4.1
pyeda==0.28.0
pyrsistent==0.15.4
rise==5.2.0
sphinx-rtd-theme==0.4.3
statsmodels==0.12.0
tqdm==4.32.2
Werkzeug==0.15.6
widgetsnbextension==3.5.1
wurlitzer==1.0.3
cython==0.29.0
setproctitle==1.1.10
psutil==5.7.0
pybind11==2.5.0
EOT

python3 -m pip install -U pip
python3 -m pip install -r requirements.txt
rm requirements.txt
