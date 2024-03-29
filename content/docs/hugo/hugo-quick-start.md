+++
title = 'Hugo Quick Start'
date = 2024-03-27T20:04:14+08:00
+++

### Introduction

Hugo is a static site generator written in Go.

### Install Hugo on macOS

Hugo is available in two editions: standard and extended. To install the extended edition of Hugo:

```bash
brew install hugo
```

Verify the version you have installed

```bash
hugo version
```

### Quick start

1. Create site
```bash
# Create the directory structure for your project in the technote directory.
hugo new site technote

# Change the current directory to the root of your project.
cd technote

# Initialize an empty Git repository in the current directory.
git init
```

2. Config theme 
```bash
# Clone the nostyleplease theme into the themes directory, adding it to your project as a Git submodule.
git submodule add https://github.com/g-hanwen/hugo-theme-nostyleplease.git themes/nostyleplease

# Append a line to the site configuration file, indicating the current theme.
echo "theme = 'nostyleplease'" >> hugo.toml
```

3. Add content 
```bash
hugo new content posts/my-first-post.md
```
Hugo created the file in the content/posts directory. Open the file with your editor.
```text
+++
title = 'My First Post'
date = 2024-01-14T07:07:07+01:00
draft = true
+++
```
Notice the draft value in the front matter is true. By default, Hugo does not publish draft content when you build the site. 

When satisfied with your new content, set the front matter draft parameter to false.

4. Publish the site
```bash
hugo
```
Hugo creates the entire static site in the public directory in the root of your project. When you publish your site, you typically do not want to include draft, future, or expired content. 
