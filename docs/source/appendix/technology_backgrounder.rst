***********************
Technology Backgrounder
***********************

Overlays and Design Re-use
==========================

The 'magic' of mapping an application to an SoC, without designing custom
hardware, is achieved by using *FPGA overlays*. FPGA overlays are FPGA designs
that are both highly configurable and highly optimized for a given domain.  The
availability of a suitable overlay removes the need for a software designer to
develop a new bitstream. Software and system designers can customize the
functionality of an existing overlay *in software* once the API for the overlay
bitstream is available.

An FPGA overlay is a domain-specific FPGA design that has been created to be
highly configurable so that it can be used in as many different applications as
possible.  It has been crafted to maximize post-bitstream programmability which
is exposed via its API.  The API provides a new entry-point for
application-focused software and systems engineers to exploit APSoCs in their
solutions.  With an API they only have to write software to program configure
the functions of an overlay for their applications.

By analogy with the Linux kernel and device drivers, FPGA overlays are designed
by relatively few engineers so that they can be re-used by many others. In this
way, a relatively small number of overlay designers can support a much larger
community of APSoC designers.  Overlays exist to promote re-use. Like kernels
and device drivers, these hardware-level artefacts are not static, but evolve
and improve over time.

Characteristics of Good Overlays
================================

Creating one FPGA design and its corresponding API to serve the needs of many
applications in a given domain is what defines a successful overlay.  This,
one-to-many relationship between the overlay and its users, is different from
the more common one-to-one mapping between a bitstream and its application.

Consider the example of an overlay created for controlling drones.  Instead of
creating a design that is optimized for controlling just a single type of drone,
the hardware architects recognize the many common requirements shared by
different drone controllers. They create a design for controlling drones that is
a flexible enough to be used with several different drones.  In effect, they
create a drone-control overlay.  They expose, to the users of their bitstream,
an API through which the users can determine in software the parameters critical
to their application.  For example, a drone control overlay might support up to
eight, pulse-width-modulated (PWM) motor control circuits.  The software
programmer can determine how many of the control circuits to enable and how to
tune the individual motor control parameters to the needs of his particular
drone.

The design of a good overlay shares many common elements with the design of a
class in object-oriented software.  Determining the fundamental data structure,
the private methods and the public interface are common requirements.  The
quality of the class is determined both by its overall usefulness and the
coherency of the API it exposes.  Well-engineered classes and overlays are
inherently useful and are easy to learn and deploy.

Pynq adopts a holistic approach by considering equally the design of the
overlays, the APIs exported by the overlays, and how well these APIs interact
with new and existing Python design patterns and idioms to simplify and improve
the APSoC design process.  One of the key challenges is to identify and refine
good abstractions.  The goal is to find abstractions that improve design
coherency by exposing commonality, even among loosely-related tasks.  As new
overlays and APIs are published, we expect that the open-source software
community will further improve and extend them in new and unexpected ways.

Note that FPGA overlays are not a novel concept.  They have been studied for
over a decade and many academic papers have been published on the topic.

The Case for Productivity-layer Languages
=========================================


Successive generations of All Programmable Systems on Chip embed more processors
and greater processing power. As larger applications are integrated into APSoCs,
the embedded code increases also. Embedded code that is speed or size critical,
will continue to be written in C/C++.  These 'efficiency-layer or systems
languages' are needed to write fast, low-level drivers, for example. However,
the proportion of embedded code that is neither speed-critical or size-critical,
is increasing more rapidly. We refer to this broad class of code as *embedded
applications code*.

Programming embedded applications code in higher-level, 'productivity-layer
languages' makes good sense.  It simply extends the generally-accepted
best-practice of always programming at the highest possible level of
abstraction.  Python is currently a premier productivity-layer language.  It is
now available in different variants for a range of embedded systems, hence its
adoption in Pynq.  Pynq runs CPython on Linux on the ARM® processors in Zynq®
devices.  To further increase productivity and portability, Pynq uses the
Jupyter Notebook, an open-source web framework to rapidly develop systems,
document their behavior and disseminate the results.
