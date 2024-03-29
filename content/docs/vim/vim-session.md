+++
title = 'Vim Session'
date = 2024-03-27T14:20:50+08:00
+++

### Introduction
A Session keeps the Views for all windows, plus the global settings.  You can
save a Session and when you restore it later the window layout looks the same.
You can use a Session to quickly switch between different projects,
automatically loading the files you were last working on in that project.

Hence, we can use it to quickly rebuild the previous state and pick up our work where we left off.

### Saving a Session
Saving a session in Vim is straightforward. We need to use the `:mksession` command, or `:mks` for short:
```bash
:mksession
```
we can override it with the ! command:
```bash
:mksession!
```

### Restoring a Session
cd to the dir where session was stored, then using the default or a named session:
```bash
vim -S
vim -S {session file path}
```
restore a session while working in Vim. we use the :source command, or :so for short:
```bash
:source
:source {session file path}
```

### referece:
<https://vimdoc.sourceforge.net/htmldoc/starting.html#session-file>
