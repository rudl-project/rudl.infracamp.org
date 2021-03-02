---
title: "rudl GitOps deployment"
layout: default-fullsize
description: |
    GitOps managed cluster
og_description: "How to setup gitlab, github and docker-hub and your development environment"
---
{% include_relative _index_jumbotron.html %}

<div class="container container-fluid">
<div class="row flex-xl-nowrap">
    <div class="col-12 col-md-6 mt-3">
        <div class="card">
            <div class="card-body">
                <p class="card-text">
                    {% capture myInclude %}
                    {% include_relative _index_goals.md %}
                    {% endcapture %}
                    {{ myInclude | markdownify }}
                </p>
            </div>
        </div>
    </div>
    <div class="col-12 col-md-6 mt-3">
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Supported platforms</h5>
                 <p class="card-text">
                    <img src="start/logo-gitlab.png" alt="gitlab" style="height: 60px">
                    <img src="start/logo-github.png" alt="github" style="height: 50px">
                    <img src="start/logo-docker.png" alt="docker" style="height: 60px">
                </p>
            </div>
        </div>
    </div>
</div>
</div>






<div class="container mt-5 markdown-body" markdown="1">


</div>


