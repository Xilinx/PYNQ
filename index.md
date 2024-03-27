---
layout: default
---

<script>
document.addEventListener("DOMContentLoaded", function(){
  // List of image sources
  const zynqboards = [
    "./assets/images/pynqz2_t.png",
    "./assets/images/pynqz2_1t.png"
  ];
  
  const zuplusboards = [
    "./assets/images/pynq-zu_t.png",
	"./assets/images/zcu102_t.png",
    "./assets/images/avnetzu_t.png",
    "./assets/images/ultra96_t.png"
  ];

  const rfsocboards = [
    "./assets/images/rfsoc4x2_t.png",
    "./assets/images/zcu111_t.png",
    "./assets/images/zcu208_t.png"
  ];
	
  const kriaboards = [
    "./assets/images/kria_t.png"
  ];
  
  const alveoboards = [
    "./assets/images/alveou280_t.png",
    "./assets/images/alveo_t.png"
  ];

function rotateImage(imageSources, imageId) {
  const imageElement = document.getElementById(imageId);
  let currentIndex = 0;
  
  // Set a random interval between 3 and 5 seconds
  const interval = Math.floor(Math.random() * (9000 - 5000 + 1)) + 5000;

  // Change the image source after the random interval with fade effect
  setInterval(() => {
    // Calculate the next index
    const nextIndex = (currentIndex + 1) % imageSources.length;
    const nextImage = new Image();
    nextImage.src = imageSources[nextIndex];
    nextImage.onload = function() {
      // Fade out current image
      fadeOut(imageElement, () => {
        // Change the image source
        imageElement.src = imageSources[nextIndex];
        currentIndex = nextIndex;
        // Fade in new image
        fadeIn(imageElement);
      });
    };
  }, interval);
}
  
  // Function to fade out an element
  function fadeOut(element, callback) {
    var opacity = 1;
    var fadeOutInterval = setInterval(function() {
      if (opacity <= 0.1) {
        clearInterval(fadeOutInterval);
        element.style.opacity = 0;
        if (callback) callback();
      }
      element.style.opacity = opacity;
      opacity -= opacity * 0.1;
    }, 50);
  }
  
  // Function to fade in an element
  function fadeIn(element, callback) {
    var opacity = 0;
    var fadeInInterval = setInterval(function() {
      if (opacity >= 1) {
        clearInterval(fadeInInterval);
        element.style.opacity = 1;
        if (callback) callback();
      }
      element.style.opacity = opacity;
      opacity += 0.1;
    }, 50);
  }

  // Call the rotateImage function for each image
  //rotateImage(zynqboards, "zynqboards");
  rotateImage(zuplusboards, "zuplusboards");
  rotateImage(rfsocboards, "rfsocboards");
  rotateImage(kriaboards, "kriaboards");
  rotateImage(alveoboards, "alveoboards");
});
</script>

# What is PYNQ?

<div class="video">
    <video width="100%" height="auto" autoplay loop muted>
        <source src="./assets/videos/pynq_animation.mp4" type="video/mp4">
    </video>
</div>

PYNQ&#8482; is an open-source project from AMD&#174; that makes it easier to use Adaptive Computing platforms.

Using the Python language, Jupyter notebooks, and the huge ecosystem of Python libraries, designers can exploit the benefits of programmable logic and microprocessors to build more capable and exciting electronic systems.

PYNQ can be used to create high performance applications with:

* parallel hardware execution
* high frame-rate video processing
* hardware accelerated algorithms
* real-time signal processing
* high bandwidth IO
* low latency control

<hr>

# Explore PYNQ

Learn about PYNQ with our brief video overview.

<div style="text-align: center;">
<iframe width="560" height="315" style="margin: auto;" src="https://www.youtube.com/embed/IRjrLm8_KB4?si=k6WQaoGRrUmZarvR" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</div>

<hr>

# Who is PYNQ for?

PYNQ is intended to be used by a wide range of designers and developers including:

* Software developers who want to take advantage of the capabilities of Adaptive Computing platforms without having to use ASIC-style design tools to design hardware.
* System architects who want an easy software interface and framework for rapid prototyping and development of their Zynq, Alveo and AWS-F1 design.
* Hardware designers who want their designs to be used by the widest possible audience.

<hr>

# What AMD devices and boards are supported?

PYNQ can be used with Zynq&#8482;, Zynq UltraScale+&#8482;, Kria&#8482;, Zynq RFSoC, Alveo&#8482; accelerator boards and AWS-F1.

<div class="logos">
<img id="zynqboards" src="./assets/images/pynqz2_t.png">
<img id="zuplusboards" src="./assets/images/pynq-zu_t.png">
<img id="rfsocboards" src="./assets/images/rfsoc4x2_t.png">
<img id="kriaboards" src="./assets/images/kv260_t.png">
<img id="alveoboards" src="./assets/images/alveo_t.png">
</div>

<div class="logos">
<img src="./assets/images/221721040-A_AMD_Zynq_Lockup_RGB_Blk.svg">
<img src="./assets/images/221761735-A_AMD_Zynq_MPSoC_DFE_Lockup_RGB_Blk.svg">
<img src="./assets/images/221761734-A_AMD_Zynq_RFSoC_Lockup_RGB_Blk.svg">
<img src="./assets/images/221721038-A_AMD_Kria_Lockup_RGB_Blk.svg">
<img src="./assets/images/221721036-A_AMD_Alveo_Lockup_RGB_Blk.svg">
</div>

PYNQ can be delivered in two ways; as a bootable Linux image for a Zynq board, which includes the pynq Python package, and other open-source packages, or as a Python package for Kria, or an Alveo or AWS-F1 host computer. 
Find out about <a href="./boards.html">PYNQ supported boards</a>.

<hr>

# Key technologies

![Browsers image](./assets/images/technologies.jpg#right) 

[Jupyter Notebook](http://jupyter.org/) is a browser based interactive computing environment. Jupyter notebook documents can be created that include live code, interactive widgets, plots, explanatory text, equations, images and video. 

A PYNQ enabled board can be easily programmed in Jupyter Notebook using Python.

Using Python, developers can use hardware libraries and overlays on the programmable logic. Hardware libraries, or overlays, can speed up software running on a Zynq or Alveo board, and customize the hardware platform and interfaces. 

<hr>

# What software do I need?


![Browsers image](./assets/images/browsers.jpg#left)

Jupyter notebook runs in a web browser. Only a [compatible web browser](https://jupyter-notebook.readthedocs.io/en/latest/notebook.html#browser-compatibility) is needed to start programming PYNQ with Python.

For higher performance, you can also use C/C++ with Python and PYNQ. The [AMD Vitis software development environment](https://www.xilinx.com/products/design-tools/vitis/vitis-platform.html) is available for free. You can also use third party software development tools.

New hardware libraries and overlays can be created using standard AMD and third party hardware design tools.

The [free WebPACK version of AMD Vivado](https://www.xilinx.com/products/design-tools/vivado.html) can be used with a wide range of Zynq boards. 

[Vitis](https://www.xilinx.com/products/design-tools/vitis/vitis-platform.html) and [Vitis open-source Accelerated Libraries](https://github.com/Xilinx/Vitis_Libraries) are also free, and can be used for Alveo/AWS-F1. 


<hr>

# How do I get started with PYNQ?

<div class="column">
   <img class="full_view" src="./assets/images/get_started.jpg#center">
   <p>
   Check the <a href="http://pynq.readthedocs.io/en/latest/getting_started.html">PYNQ Getting Started guide</a>
   </p>
</div>
<div class="column">
   <img class="full_view" src="./assets/images/boards.png#center">
   <p>
   Find out about <a href="./boards.html">supported boards</a>
   </p>
</div>
<div class="column">
   <img class="full_view" src="./assets/images/documentation.png#center">
   <p>
   Read the <a href="http://pynq.readthedocs.io">PYNQ documentation</a>
   </p>
</div>
<div class="column">
   <img class="full_view" src="./assets/images/pynq_tutorial.png#center">
   <p>
   Try the <a href="https://github.com/Xilinx/PYNQ_Workshop">PYNQ tutorial</a>
   </p>
</div>
<br>


<hr>

# Get involved

The full source code for the PYNQ project is available the [PYNQ GitHub](https://github.com/Xilinx/Pynq).

If you would like to get involved or contact the PYNQ team, you can post a message on the [PYNQ support forum](https://discuss.pynq.io/).

