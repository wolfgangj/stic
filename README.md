# `stic` - the "Sanity-To-Insanity Converter"

The `stic` is a very simple tool (~200 lines of Ruby) to convert a sane markup format to HTML5.
I wrote it in particular to make working with
  the (really helpful) [BEM](https://css-tricks.com/bem-101/) convention more convenient.
I actually use this for building a commercial website currently, so it's getting battle-tested.

Features:

- Nicer syntax for HTML5
- Include other files and pass arguments and blocks to them
- Automatic code indentation possible (as opposed to e.g. HAML)
- Can choose the correct tags automatically given the class of an element (useful for BEM)
- Emacs major mode included

## Usage

You should have a file called `html-tags`, which maps classes to tags.
This file may be empty, since the `div` tag is used by default if no tag was specified for a class.
The `html-tags` file has a very simple format:

```
title h1
menu ul
menu-item li
menu-link a
```

So your HTML will end up being semantic,
  but you can conveniently define the structure with your class names only.
(In BEM, everything is done with classes anyway, so this feature helps to avoid some redundancy.)
If several classes are given (as in the example below), the first one decides the tag.

Now you can create a `.stic` file (this is not valid HTML yet, bear with me):

```
;; example.stic
.title Hello, world!
.menu {
  .menu-item.highlighted {
    .menu-link(href: home.html) Home
  }
  .menu-item {
    .menu-link(href: about.html) About
  }
}
.content {
  This is <em>text</em>.
}

;; resulting HTML:
<!DOCTYPE html>
<h1 class="title">Hello, world!</h1>
<ul class="menu">
  <li class="menu-item highlighted">
    <a class="menu-link" href="home.html">Home</a>
  </li>
  <li class="menu-item">
    <a class="menu-link" href="about.html">About</a>
  </li>
</ul>
<div class="content">
  This is <em>text</em>.
</div>
```

The usage of the `stic.rb` script is: `./stic.rb example.stic example.html`.

Automatically generating the matching tags for classes might be nice,
  but to get valid HTML, we also need the `html-head-body` mumbo-jumbo.
This includes some tags which should not have a class attribute.
This can be done by using the percent sign `%` (which you also can combine with classes):

```
;; example2.stic
%html {
  %head {
    %meta(charset:utf-8)
    %title The page title
  }
  %body.page {
    .title Hello, world!
  }
}

;; resulting HTML:
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>The page title</title>
  </head>
  <body class="page">
    <h1 class="title">Hello, world!</h1>
  </body>
</html>
```

Some constructs usually appear repeatedly on a web page, so you can move them into a module
  that you can include.
For the parts which vary, you can pass arguments to a module:

```
;; example3.stic
%html {
  %body {
    .menu {
      @menu-entry(page:home.html text:Home)
      @menu-entry(page:about.html text:'About us')
    }
  }
}

;; menu-entry.stic
.menu-item {
  .menu-link(href:$page) $text
}

;; resulting HTML:
<!DOCTYPE html>
<html>
  <body>
    <ul class="menu">
      <li class="menu-item">
        <a class="menu-link" href="home.html">Home</a>
      </li>
      <li class="menu-item">
        <a class="menu-link" href="about.html">About us</a>
      </li>
    </ul>
  </body>
</html>
```

Variables can also appear in class names and even tag names.
You can also refer to a variable defined in an enclosing module, but you should be careful about that.

However, usually you will also have a layout definition and several web pages which share the layout.
This is why you can pass blocks to modules.
A module can include the content of the block with `@CONTENT` (to which you can pass arguments):

```
;; page.stic
%html {
  %body {
    %h1 $title
    %article {
      @CONTENT(year: '2017')
    }
  }
}

;; welcome.stic
@page(title: 'Hello, world!') {
  %p {
    The quick brown fox jumps over the lazy dog.
  }
  %aside Copyright $year
}

;; resulting HTML:
<!DOCTYPE html>
<html>
  <body>
    <h1>Hello, world!</h1>
    <article>
      <p>
        The quick brown fox jumps over the lazy dog.
      </p>
      <aside>Copyright 2017</aside>
    </article>
  </body>
</html>
```

The exact semantics for variables in blocks are:
Params passed to the block shadow others.
Those from the module where the block originally comes from are second.
Those from the module are third.

A bonus thing `stic` does is handle a few common mistakes humans do:
You can separate arguments with commas and you can use `=` instead of `:` and `"` instead of `'`.
So `.foo(bar=baz, qux="frob")` is the same as `.foo(bar:baz qux:'frob')`.

## Using the Emacs major mode

The procedure of setting up the major mode is standard,
  but for those not experienced with Emacs, here's how to do it:

1. Put the `stic-mode.el` file in a directory like `~/.emacs.d/lisp`.
2. If the directory is not in your load path yet, add it by inserting
     `(push "~/.emacs.d/lisp" load-path)` into your Emacs config (e.g. `~/.emacs`).
3. Below that, add `(require 'stic-mode)` to your Emacs config.
4. If you don't want to restart Emacs for the change to take effect,
     evaluate the two previously added commands
     by inserting the cursor after each (in order) and press `C-x C-e`.
5. When opening `*.stic` files, Emacs will now use `stic-mode`!

The `stic-mode` currently just adds automatic indenting, i.e. commands like
pressing tab or `M-x indent-region` now follow `stic` conventions.

## TODOs

- Readme file for the example project
- Syntax errors in the input are not always handled gracefully.
- Everything after `;;` is discarded from the input, even if the `;;` appears inside of an attibute value. (Fixing this involves updating the Emacs mode to the new behaviour.)
