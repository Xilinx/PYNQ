---
layout: default
title: PYNQ community
description: 
---

# PYNQ community projects

A selection of projects from the PYNQ community is shown below. Note that some examples are built on different versions of the PYNQ image. For questions related to community projects, or to get your project added, please visit the  [**PYNQ support forum**](https://discuss.pynq.io/).

# PYNQ embedded community projects

[![Browsers image](./assets/images/community/sample_projects.png#left)](./embedded.html)

The PYNQ embedded community page highlights examples of projects for Zynq based boards.

Examples include image and video processing, robot and industrial control, machine learning, RISC-V prototyping, RFSoC QPSK and more.

[PYNQ Embedded community projects](./embedded.html)

# PYNQ Alveo community projects and tutorials

PYNQ can be used with  [**Alveo accelerator boards**](https://www.xilinx.com/products/boards-and-kits/alveo.html)  and  [**AWS-F1**](https://aws.amazon.com/ec2/instance-types/f1/). The following examples can be installed on the host computer and run on the Alveo board or on an AWS-F1 instance.

<div class="gallery">
  {% for item in site.data.alveo %}
  {% assign loopindex = forloop.index0 | modulo: 4 %}
    {% if loopindex == 0 %}
<div class="row">
    {% endif %}
      <div class="image" id="gallery_item_{{ loopindex }}">
        <a href="{{ item.url }}" target="_blank">
          <img src="{{ item.image }}" alt="{{ item.alt }}">
        </a>
        <p class="caption"><a href="{{ item.url }}">{{ item.alt }}</a></p>
      </div>
    {% if loopindex == 3 or forloop.last %}
</div>
    {% endif %}
  {% endfor %}
</div>

<hr>

# Machine Learning on Xilinx FPGAs with FINN

![Browsers image](./assets/images/community/finn.png#left) 

PYNQ has been widely used for machine learning research and prototyping.

*FINN*, an experimental framework from Xilinx Research Labs to explore deep neural network inference on FPGAs. It specifically targets quantized neural networks, with emphasis on generating dataflow-style architectures customized for each network.

FINN makes extensive use of PYNQ as a prototyping platform.

For more information see [xilinx.github.io/finn](https://xilinx.github.io/finn/)

<hr>

# Tutorials and other resources

<div class="gallery">
  {% for item in site.data.tutorials %}
  {% assign loopindex = forloop.index0 | modulo: 4 %}
    {% if loopindex == 0 %}
<div class="row">
    {% endif %}
      <div class="image" id="gallery_item_{{ loopindex }}">
        <a href="{{ item.url }}" target="_blank">
          <img src="{{ item.image }}" alt="{{ item.alt }}">
        </a>
        <p class="caption"><a href="{{ item.url }}">{{ item.alt }}</a></p>
      </div>
    {% if loopindex == 3 or forloop.last %}
</div>
    {% endif %}
  {% endfor %}
</div>

<hr>

# Example Notebooks


A selection of notebook examples are shown below that are included in the PYNQ image. The notebooks contain live code, and generated output from the code can be saved in the notebook. Notebooks can be viewed as webpages, or opened on a Pynq enabled board where the code cells in a notebook can be executed. 

<div class="gallery">
  {% for item in site.data.examples %}
  {% assign loopindex = forloop.index0 | modulo: 4 %}
    {% if loopindex == 0 %}
<div class="row">
    {% endif %}
      <div class="image" id="gallery_item_{{ loopindex }}">
        <a href="{{ item.url }}" target="_blank">
          <img src="{{ item.image }}" alt="{{ item.alt }}">
        </a>
        <p class="caption"><a href="{{ item.url }}">{{ item.alt }}</a></p>
      </div>
    {% if loopindex == 3 or forloop.last %}
</div>
    {% endif %}
  {% endfor %}
</div>