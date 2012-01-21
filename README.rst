=========
JumpToCSS
=========

JumpToCSS is a tiny plugin that helps you to quickly navigate from an HTML element to the CSS which affects it, if it is open in another buffer.

The plugin provides a single command, ``:JumpToCSS`` which can be mapped in .vimrc however you choose.

**Recommended mapping:**

    nnoremap ,jc :JumpToCSS<CR>

Usage
-----

Position the cursor inside of the start tag of an HTML element, and call the plugin using ``:JumpToCSS`` or whichever keymap you have specified. The plugin will use a regular expression to attempt to find the CSS that applies to the element in any open buffer with the .css file extension.

It's recommended to add the following to your .vimrc so that the quickfix window will close itself after you've made a selection from the results returned:

    let g:jumptocss_autoclose = 1

Requirements
------------

The plugin requires Vim to be compiled with ``+python``.
