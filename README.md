# Personal Blog of Rob Mengert

In order to build this site locally, clone down the repo and run the following command in the root folder:

```bash
$ hugo -D server
```

The `-D` is required in order to render posts that have `draft: true` in the post heading.

# Theme

This blog site makes use of the [Hugo Geekblog theme](https://hugo-geekblog.geekdocs.de/).  Installation instructions below:

```bash
$ mkdir -p themes/hugo-geekblog/
$ curl -L https://github.com/thegeeklab/hugo-geekblog/releases/latest/download/hugo-geekblog.tar.gz | tar -xz -C themes/hugo-geekblog/ --strip-components=1
```

These instructions are taken directly from the Geekblog site.  They advise this method over adding the theme as a git module as is done in the Hugo quickstart for the `ananke` theme.  The reason being is that `npm install` and `npm run build` need to be executed after adding the theme as a module.