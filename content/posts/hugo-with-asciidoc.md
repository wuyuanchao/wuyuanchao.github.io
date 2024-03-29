+++
title = 'Hugo With Asciidoc'
date = 2024-03-29T10:07:45+08:00
+++

#### Step 1. 
Create post with .adoc extension
```
hugo new content posts/hugo-with-asciidoc.adoc
```


#### Step 2. 
security configuration: add the following to hugo.toml
```
[security.exec]
allow = ["^dart-sass-embedded$", "^go$", "^npx$", "^postcss$", "^asciidoctor$"]
```

#### Step 3.
github workflow config: add asciidoc install step in job build
```
    - name: Install AsciiDoc
      run: sudo apt-get install -y asciidoc
```
