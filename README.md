# Personal Blog of Rob Mengert

In order to build this site locally, clone down the repo and run the following command in the root folder:

```bash
$ hugo -D server
```

The `-D` is required in order to render posts that have `draft: true` in the post heading.

# Theme

This blog site makes use of the [Hugo Anatole theme](https://github.com/lxndrblz/anatole).  Installation instructions below:

```bash
$ git submodule add https://github.com/lxndrblz/anatole themes/anatole
```

These instructions are taken directly from the [Anatole wiki](https://github.com/lxndrblz/anatole/wiki/1%EF%B8%8F%E2%83%A3-Essential-Steps).  

## Medium Conversion to Markdown

For a time, I am going to maintain post parity with Medium.  The process to do that is _somewhat_ automated.  First, use `[medium-to-markdown](https://www.npmjs.com/package/medium-to-markdown)` to get the post into markdown:

```bash
[rmengert@Robs-MBP:~/projects/medium-to-markdown]
cd ~/projects/medium-to-markdown && \ 
npm run convert https://rob-mengert.medium.com/im-going-to-become-a-frontend-dev-e77dc99eac6e > ~/projects/robmengert.me/content/posts/im-going-to-become-a-frontend-dev.md
```

Unfortunately, this tool does not do anything with images that may be on the post.  Those need to be manually downloaded into the `static` folder in this repo.  To keep things simple, create a folder per post:

```bash
$ mkdir static/im-going-to-become-a-frontend-dev
```

The `convert` utility that is part of [ImageMagick](https://www.imagemagick.org/script/index.php) can be used to quick resize an image from the command line:

```bash
convert hotdog-cat.png -resize 50% hotdog-cat-50.png 
```