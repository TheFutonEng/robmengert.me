---
title: "Hugo on Vercel"
date: 2023-07-22T07:59:11-06:00
draft: true
---

## Introduction

I spent some time trying to get a [Hugo](https://gohugo.io/) site stood up on [Vercel](https://vercel.com/) and skinned my knees a little.  I figured those lessons would make for a good first post.

## Using the Latest Hugo Version

At the time of this writing, the latest Hugo version was v0.115.4.  I followed the [Hugo quick start guide](https://gohugo.io/getting-started/quick-start/) and installed Hugo and Dart Sass via homebrew.  Getting a local site on my Mac stood up took minutes, super easy.  After pushing the site Github and then linking it to Vercel, it wasn't rendering properly.  That turned out just to be a consequence of how the repo was setup.  In short:

**Working**
```bash
<git-root>/site
```

**Not working**
```bash
<git-root>/<random_folder>/site
```

### Vercel Site Definition

I decided to just build the site from within Vercel instead of building it locally.  Using this workflow, the `hugo new site <site_name>` happens on the Vercel side and gets pushed to a git repo in Github.  There was one major problem with this workflow: there was no way to tell what version of Hugo built the site (perhaps my google-fu is poor but I couldn't find anything easily).  I pulled down the repo created by Vercel and tried to start a local instance of the site and got some errors:

```bash
$ hugo server
Watching for changes in /Users/rmengert/projects/robmengert.me/{archetypes,content,themes}
Watching for config changes in /Users/rmengert/projects/robmengert.me/config.toml
Start building sites … 
hugo v0.115.4+extended darwin/arm64 BuildDate=unknown

ERROR render of "page" failed: execute of template failed: html/template:_default/single.html:40:17: no such template "_internal/google_news.html"
ERROR render of "section" failed: execute of template failed: html/template:_default/list.html:40:17: no such template "_internal/google_news.html"
ERROR render of "taxonomy" failed: execute of template failed: html/template:_default/terms.html:40:17: no such template "_internal/google_news.html"
Built in 15 ms
Error: error building site: render: failed to render pages: render of "home" failed: execute of template failed: html/template:index.html:40:17: no such template "_internal/google_news.html"
```

This first batch or errors was easily fixed by removing a line in an HTML file but more errors came right behind it.  This felt like a faulty path to go down.  Not being able to do local development easily was a huge false start.  I found that there are two ways to pick which version of Hugo you want to use on the Vercel side:

- Environmental variable defined within the project settings in [Vercel](https://vercel.com/docs/concepts/projects/environment-variables)
- Creating a [`vercel.json`](https://vercel.com/docs/concepts/projects/project-configuration) file in the root of the directory and defining the Hugo version there

### Back to Local Site Definition

I destroyed the git repo on Github and the Vercel project and decided to start over by again creating the site locally on my Mac, pushing the code to Github, and then linking the repo to Vercel.  But this time, I would use one of the two methods previously mentioned to set the Hugo version used by Vercel.  

Long story short, here are the lessons learned:

- The `vercel.json` file seems to take precedence over the project environmental variables (even though the project environmental variables are the way to go according to the [docs](https://vercel.com/guides/how-do-i-migrate-away-from-vercel-json-env-and-build-env))
- The Hugo version can't have a leading `v` in the `vercel.json` file even though that's how Hugo defines the versions

The reason I learned the first bullet is in part due to the second bullet.  The first successful deployment of this site had the following `vercel.json`:

```json
{
    "build": {
      "env": {
      "HUGO_VERSION": "0.115.4"
      }
    }
  }

```

With the following project level environmental variable:

![Vercel HUGO_VERSION EnvVar](/vercel_environmental_variable.png)

Vercel threw a build error with any version in the `vercel.json` file that had a leading `v` in the version (IE, v.0.115.4).


## Conclusion

Now the version of Hugo used locally can stay up to date easily by updating the `vercel.json` file (until the `vercel.json` file is deprecated).