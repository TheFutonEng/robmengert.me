---
title: "Learning HTML"
date: 2023-08-12T08:33:43-06:00
draft: true
categories: ["web-dev"]
series: ["HTML"]
tags: ["html"]
---

This is my first post in a series on learning frontend web development. I’m stoked to be in a position where [I can learn these technologies](../im-going-to-become-a-frontend-dev/) to help me perform my job better. I’m working through [Dave Gray’s](https://courses.davegray.codes/view/courses/web-dev-roadmap-for-beginners) course on Web Dev for beginners and this post will document some lessons learned around HTML.

Learning Objectives:
--------------------

*   What is HTML, and what’s it for?
*   Read up on the history of HTML
*   Learn the various parts of the current HTML standard
*   Come up to speed on testing methodologies
*   Document anything else fun or interesting in the land of HTML

![Leeroy Jenkins](/learning-html/leeroy-jenkins-50.png)

What Is HTML?
=============

HTML stands for HyperText Mark-up Language and is the standard way to organize the structure of a web page. Browsers then interpret HTML documents and display everything from the text, images, links, and other elements. This observation can’t be overstated: the entire point of HTML is to provide a standard way for web browsers to render a web page making them consumable for humans.

Like all markup languages, HTML is not considered a programming language. It focuses on describing the presentation and arrangement of information on a web page using tags. There is no native way to implement algorithms or logic in HTML.

History of HTML
===============

No matter how dry it seems, I enjoy learning the history of any technology I learn. People always play an interesting role in the evolution of technology, and the history of HTML is no different. There’s an interesting write-up on the early history of the standard on the [World Wide Web Consortium site](https://www.w3.org/People/Raggett/book4/ch02.html) that covers HTML as an idea through HTML 4.0. In short:

In 1989, physicist Tim Berners-Lee invented the world wide web while working at CERN laboratories in Geneva, Switzerland. It’s a weird place for the birth of the web, but it kinda makes sense. Scientists of all types work very collaboratively in institutions around the world. Tim was thinking through ways where documents hosted on computers anywhere in any country could simply link to documents held by other institutions, making it easy to cross-reference. The concept of hypertext, text which contains links or references to other text, had been around in academia since the 1940s. However, it wasn’t until computers became more prevalent that it became practical to implement. Tim created the first iteration of the HyperText Transfer Protocol or HTTP, and is now used ubiquitously and is the primary means of fetching documents/transimitting data on the web.

The road to standardization was difficult due to a lot of factors. The aforementioned tags (which will be discussed in further depth in a bit) were a particular point of contention. Early participants in the [browser wars](https://en.wikipedia.org/wiki/Browser_wars) of the mid 1990s pretty much all created custom tags that were only understandable via their browsers. Incompatibilities ran rampant and organizations and individuals lobbying for their tags made things challenging. Eventually, standardization by the World Wide Web Consortium (W3C) was achieved via HTML 3.2 in January of 1997.

Parts of HTML
=============

This section will review the part of an HTML doc and provide simple examples.

Tags
----

Tags are the foundational building blocks of an HTML document.

```html
<head>  
<title>Learning about HTML</title>  
</head>
```

In the above code snippet, there are two sets of tags: `head`and `title`

The term ‘tag’ refers to the exact text that is the opening or closing demarcation. So `<head>` for the opening tag and `</head>` for the closing tag. When someone says “the head tag,” they refer to these two text blocks. A full list of tags in the HTML standard can be found on the [W3C site](https://www.w3schools.com/tags/).

Elements
--------

A quick [Google search](https://www.google.com/search?q=what+is+the+difference+between+html+tag+and+element&rlz=1C5GCEM_enUS1006US1006&oq=what+is+the+difference+between+html+ta&gs_lcrp=EgZjaHJvbWUqBwgAEAAYgAQyBwgAEAAYgAQyBggBEEUYOTIMCAIQABgUGIcCGIAEMgcIAxAAGIAEMggIBBAAGBYYHjIICAUQABgWGB4yCAgGEAAYFhgeMggIBxAAGBYYHjIICAgQABgWGB4yCAgJEAAYFhge0gEJMTQxNDlqMGo3qAIAsAIA&sourceid=chrome&ie=UTF-8) will show that elements and tags are commonly used interchangeably. It seems like in casual conversations, that’s fine, but there is an important distinction.

*   Tags refer to just the opening and closing demarcations
*   Elements refer to the opening and closing demarcations and everything in between

Let’s take the same code snippet from the tag section.

```
<head>  
<title>Learning about HTML</title>  
</head>
```

An easy way to understand the difference is that the `head` element contains the `title` element. The title tags are just the `<title>` and `</title>` blocks of text; the text ‘Learning about HTML’ is not part of the `title`tags but is part of the `title` element.

How you probably feel reading this.

Attributes

HTML attributes provide additional information about how an HTML element should function.

```
<element attribute-name=”value”>Some pretend element</element>
```

Using a fictional element of `element` to show the structure, the definition of an attribute is contained within the opening tag and has the form of `attribute-name` equals `value`.

Entities
--------

[HTML entities](https://www.w3schools.com/html/html_entities.asp) are character sequences that display HTML-reserved characters and other special characters on the page. We can infer from the previous code snippets that `<` and `>` are reserved characters in HTML. To render them on a page, an entity must be used, as the below example shows:

```
<p>This is the less than character: &lt </p>
```

The `&lt` sequence will render a literal `<` character on the HTML document.

Common Elements
===============

Going to talk through some common elements in this section.

HTML
----

The `html` element is the root of any HTML document and contains all other elements. It is common that the language of the webpage is coded into the opening tag as an attribute, as shown below.

```
<html lang="en">  
<p>Some stuff on a page.</p>  
</html>
```

The `lang` attribute is not strictly required, but the [W3C validator](https://validator.w3.org/) will throw a warning if it’s not there. This is a useful bit of information that web crawlers will use to help categorize the page.

Head
----

The `head` tag contains data about the document itself. Nothing with this section gets displayed to the client viewing the web page. This element is typically the first element within the `html` element and appears before the `body` element. The only required element within `head` is the `title` element. The `title` element gets displayed in the browser tab. For example, this code:

```
<html lang="en">  
<head>  
<title>Learning more about HTML</title>  
</head>
```

Renders this in the tab:

Body
----

The `body` element contains everything that gets displayed in the browser. This code:

```
<html lang="en">  
<head>  
<title>Learning more about HTML</title>  
</head>  
  
<body>  
    <h1>Hello World!</h1>  
  
    <hr>  
  
    <h2>I'm Ready to Learn HTML</h2>  
    <p>This is my first web page.</p>  
  
</body>  
  
</html>
```

Renders this:

The `body` element itself isn’t terribly interesting, but some additional elements within the above code can be broken down a little further.

H1–6
----

The heading elements are represented by tags `h1` through `h6` with `h1` representing the largest heading and `h6` the smallest. The use of the `h1` and `h2` tags in the above snippet shows that off.

Paragraph (p)
-------------

The `p` element is for text that appears on a page and is not a heading. This paragraph is contained within a `p` element.

Wrap Up
=======

This post sums up some of the foundational parts of HTML. Future posts will continue to break down other parts of the specification with other code snippets and examples.
