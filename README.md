# Personal Blog of Rob Mengert

In order to build this site locally, clone down the repo and run the following command in the root folder:

```bash
$ hugo -D server
```

The `-D` is required in order to render posts that have `draft: true` in the post heading.

# Theme

This blog site makes use of the [Hugo Poison theme](https://poison.lukeorth.com/).  Installation instructions below:

```bash
$ git submodule add https://github.com/lukeorth/poison.git themes/poison
```

These instructions are taken directly from the Geekblog site.  They advise this method over adding the theme as a git module as is done in the Hugo quickstart for the `ananke` theme.  The reason being is that `npm install` and `npm run build` need to be executed after adding the theme as a module.