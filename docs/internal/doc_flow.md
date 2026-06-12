# Documentation Flow

## Overview
Documentation is located in the folder docs/ and is published to https://rsmp-nordic.org/rsmp_validator using GitHub Pages.

General documentation is written as Markdown files and is structured as a Jekyll site, which is what GitHub Pages uses.

The sus conformance test suite is documented in the code, and extracted using our automatic doc generator, which then generates Markdown pages that are published as part of the Jekyll site.

Changes to documentation are committed to the `docs` branch, or directly to the `main` branch. GitHub actions then use the `gh-pages` branch to rebuild and publish documentation.

## Jekyll
The general documentation is written in Markdown and structured as a Jekyll site located in docs/. It's deployed on Github Pages, using the branch gh-pages as publishing source.

To update the general documentation:

1. Edit Markdown files in docs/pages/
2. Commit changes and push to the main branch on GitHub.

When you push to the main branch on GitHub, a GitHub Action will run the command to rebuild the documentation in docs/tests. Changes are then committed to the gh-pages branch, which will cause GitHub Pages to update the website.

The Jekyll site includes the documentation described below, located in docs/dev/.

Internal documentation is located in docs/internal/. Files in this folder should not include Jekyll frontmatter. Files without Jekyll frontmatter will not be processed by Jekyll, and will not be shown on the website.

### Running Jekyll Locally
If you want to review the resulting documentation before pushing to Github Pages, you can run Jekyll locally.

The `docs` folder contains its own Gemfile, which requires the Jekyll gem. This folder and its Gemfile is what Github Pages uses to run Jekyll, but you can use it locally as well.

First run `rake spec_docs` if needed, then, assuming you're in the root folder:

```
% cd docs
% bundle
% bundle exec jekyll serve
```

You can now view the site on http://localhost:4000.

## Automatic Document Generation
The documentation of the sus conformance test suite, including tests in `test/site/` and `test/supervisor/`, is written as code comments. The source files are read by the `spec_docs` rake task, which extracts the documentation and generates Markdown pages in `docs/tests/`. The documentation is published as part of the Jekyll site.

To update the documentation:

1. Edit comments in sus test files under `test/site/` or `test/supervisor/`
2. Optionally review the resulting Jekyll site locally (see below).
3. Push changes to the main branch on GitHub.

When you push to the main branch on GitHub, a GitHub Action will run `rake spec_docs` to update the files in `docs/tests/`. Changes are then committed to the gh-pages branch.

When the gh-pages branch on GitHub is updated, GitHub Pages automatically updates the Jekyll site, which includes the generated test-suite pages.
