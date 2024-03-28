+++
title = 'Hugo Host on Github Pages'
date = 2024-03-27T20:49:54+08:00
+++


### Step 1. Create a GitHub repository.

#### GitHub Pages

There are three types of GitHub Pages sites: project, user, and organization. 

If you're creating a user site, your repository must be named `<user>.github.io`.

Go <https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site> for detail.


https://github.com/wuyuanchao/wuyuanchao.github.io.git

### Step 2. Config GitHub Actions

Visit your GitHub repository. From the main menu choose Settings > Pages. Change the Source of **Build and deployment** to GitHub Actions. 

Add new workflow in Actions.

.github/workflows/hugo.yaml
```yaml
# Sample workflow for building and deploying a Hugo site to GitHub Pages
name: Deploy Hugo site to Pages

on:
  # Runs on pushes targeting the default branch
  push:
    branches:
      - main

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
permissions:
  contents: read
  pages: write
  id-token: write

# Allow only one concurrent deployment, skipping runs queued between the run in-progress and latest queued.
# However, do NOT cancel in-progress runs as we want to allow these production deployments to complete.
concurrency:
  group: "pages"
  cancel-in-progress: false

# Default to bash
defaults:
  run:
    shell: bash

jobs:
  # Build job
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.124.0
    steps:
      - name: Install Hugo CLI
        run: |
          wget -O ${{ runner.temp }}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
          && sudo dpkg -i ${{ runner.temp }}/hugo.deb          
      - name: Install Dart Sass
        run: sudo snap install dart-sass
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0
      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v4
      - name: Install Node.js dependencies
        run: "[[ -f package-lock.json || -f npm-shrinkwrap.json ]] && npm ci || true"
      - name: Build with Hugo
        env:
          # For maximum backward compatibility with Hugo modules
          HUGO_ENVIRONMENT: production
          HUGO_ENV: production
        run: |
          hugo \
            --gc \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/"          
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  # Deployment job
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

#### Customize the workflow
You may remove `Install Dart Sass` step if your site, themes, and modules do not transpile Sass to CSS using the Dart Sass transpiler.

### Step 3. Push your local repository to GitHub.

Create hugo site and test the code, then push them to GitHub.

If the branch name match the config of 'on.push.branches', the workflow will run automatically.
