---
title: "Learning HTML Part Deux"
date: 2023-08-19T08:33:43-06:00
draft: true
categories: ["web-dev"]
series: ["HTML"]
tags: ["html"]
---

<!-- > medium-to-markdown@0.0.3 convert
> node index.js https://rob-mengert.medium.com/html-learning-part-deux-eccb234d754 -->

[I recently decided to start digging into frontend technologies](https://medium.com/@rob-mengert/im-going-to-become-a-frontend-dev-e77dc99eac6e). [I started with HTML](https://medium.com/@rob-mengert/learning-html-f869d8d1f044) and poked around a little. This post is picking up where the previous one left off.

Ordered Lists
=============

Ordered lists are numbered lists. Plain and simple. They are opened using the `ol` element, and each item in the list is enclosed within a `li` element. The example below is pretty straightforward.

```html
<ol>  
    <li>Item 1</li>  
    <li>Item 2</li>  
    <li>Item 3</li>  
</ol>
```

Which renders like so in a browser:

![ordered list](/learning-html-part-deux/ordered-list.png)

Unordered Lists
===============

Unordered lists are bulleted lists. They are opened using the `ul` element, and each item in the list is enclosed within a `li` element. The example below is also pretty straightforward.

```html
 <ul>  
      <li>Item 1</li>  
      <li>Item 2</li>  
      <li>Item 3</li>  
  </ul>
```

Which renders like so in a browser:

![ordered list](/learning-html-part-deux/unordered-list.png)

Description Lists
=================

Description lists are used to present a list of terms and their corresponding descriptions. The `dl` element is used for the list itself. The `dt` element creates a description term and then the `dd` element creates the data description. I honestly am not entirely clear why someone would choose to use a description list but it does seem to be pretty ubiquitous. The code itself is easy to read:

```html
 <dl>  
      <dt>Item 1</dt>  
      <dd>This is the first item in the description list</dd>  
      <dt>Item 2</dt>  
      <dd>This is the second item in the description list</dd>  
      <dt>Item 3</dt>  
      <dd>This is the third item in the description list</dd>  
  </dl>
```

Which renders in the browser as follows:

![ordered list](/learning-html-part-deux/description-list.png)


Anchor Tags
===========

Anchor tags create hyperlinks and are the way the web is linked together. The anchor tag is just `a` and uses several attributes in order to control the behavior of the link. The below example shows absolute linking:

```html
<p> The <a href="https://developer.mozilla.org/en-US/">MDN</a>   
is a good web resource </p> 
```

What makes this absolute is that the full URL is provided in the link. Relative linking is based on the location from where the current page is in the directory structure. So given this structure:

```bash
$ tree .  
.  
├── about.html  
├── html5.png  
├── img  
│   ├── caribbean.jpg  
│   ├── html\_logo\_300x300.png  
│   └── vacation.jpg  
├── index.html  
└── main.css  
  
1 directory, 7 files
```

The `about.html` file can be referenced using just the file name in the `index.html` page:

```html
<a href="about.html">About Me</a>
```

Wrap Up
=======

Thanks for reading! Next time I’m going to write about how to handle images on web pages.
