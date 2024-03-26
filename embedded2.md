---
layout: default
title: PYNQ community projects
description: 
---

# PYNQ community projects (continued)

<div class="gallery">
  {% for item in site.data.embedded %}
  {% if forloop.index0 > 31 %}
  {% assign loopindex = forloop.index0 | modulo: 4 %}
    {% if loopindex == 0 %}
<div class="row">
    {% endif %}
      <div class="image" id="projects_gallery_{{ loopindex }}">
        <p class="gallery_title">{{ item.title }}</p>
        <p class="affiliation">{{ item.affiliation }}</p>
        <a href="{{ item.url }}">
          <img src="{{ item.image }}" alt="{{ item.title }}">
        </a>
      </div>
    {% if loopindex == 3 or forloop.last %}
</div>
    {% endif %}
  {% endif %}
  {% endfor %}
</div>

Back to [page 1](./embedded.html)