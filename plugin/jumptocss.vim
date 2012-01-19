nnoremap ,jc :call JumpToCSS()<CR>

if exists("g:loaded_jumptocss") || &cp
    finish
endif

let g:loaded_jumptocss = 1

" From http://vim.wikia.com/wiki/Automatically_fitting_a_quickfix_window_height
au FileType qf call AdjustWindowHeight(2, 10)
function! AdjustWindowHeight(minheight, maxheight)
  exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
endfunction

" It's recommended for users to add 
" let g:jumptocss_autoclose = 1
" to their .vimrc
if exists("g:jumptocss_autoclose")
    au FileType qf nnoremap <CR> <CR>:cclose<CR>
endif

function! JumpToCSS()
python << EOF
import vim, re

parts = {
    'tag':None,
    'id':None,
    'classes':[]
    # 'type':None,
}

regexen = {
    'tag': {
        'regex':'<([a-zA-Z0-9-_]+)(?:[^>])',
        'compiled_re':None,
    },
    'id': {
        'regex':'id="([a-zA-Z0-9-_]+)"',
        'compiled_re':None,
    },
    'classes': {
        'regex':'class="([^"]+).*"',
        'compiled_re':None,
    }
}

def get_start_tag():
    # go to beginning of start tag
    vim.command('normal! F<')

    # if there is something in the z register, copy it
    try:
        z_reg = vim.eval('@z')
    except vim.error:
        z_reg = None

    # save the start tag to the z register and eval
    vim.command('normal! "zyf>')
    currenttag = vim.eval('@z')

    # restore original z register if any
    if z_reg is not None:
        vim.command('let @z="'+escape(z_reg)+'"') # what command can I use to assign @z back to z_reg ?

    return currenttag

def assemble_css_regex(parts):
    import re
    regex = '\s*'
    if len(parts["tag"]):
        if parts["tag"][0]:
            regex += '(?P<tag>'+parts["tag"][0]+')?'
    if len(parts["id"]):
        if parts["id"][0]:
            regex += '(?P<id>\#'+parts["id"][0]+')?'
    if len(parts["classes"]):
        regex += '[\.]?(?P<classes>'+'|'.join(parts["classes"])+')?'
        
    regex += '\s*\{?$'

    return re.compile(regex)

def escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

# get start tag
start_tag = get_start_tag()

# find matching strings in start_tag using regexen for each type (tag, id and classes)
for r in regexen.items():
    r[1]["compiled_re"] = re.compile(r[1]["regex"])
    parts[r[0]] = r[1]["compiled_re"].findall(start_tag)
    if r[0] == 'classes':
        try:
            parts["classes"] = parts["classes"][0].split(' ')
        except:
            pass

# create list of CSS buffers
css_buffers = []
for i in vim.buffers:

    try:
        if i.name is None:
            pass
        else:
            if i.name[-4:] == ".css":
                css_buffers.append(i)

    except vim.error:
        print 'you dun goofd'

# based on the "parts" available in the current line of the HTML buffer, create the regex to use to search CSS buffers
css_regex = assemble_css_regex(parts)

# vim.command('let @* = "'+escape(css_regex.pattern)+'"')

matching_lines = []
# for all CSS buffers
for b in css_buffers:
    # for each line in the buffer
    for line in b:
        # if the line is not empty
        if not len(line) == 0:
            # there has to be a better way than running the regex on all non-empty lines of every CSS buffer
            test = css_regex.search(line)

            # if we have a match
            if test is not None:
                # put the matched groups into a dict so we can test how matchy it is
                matchesdict = test.groupdict()

                # rudimentary CSS specificity
                matchiness = 0
                if 'id' in matchesdict and not matchesdict['id'] == None:
                    matchiness += 100
                if 'classes' in matchesdict and not matchesdict['classes'] == None:
                    matchiness += 10
                if  'tag' in matchesdict and not matchesdict['tag'] == None:
                    matchiness += 1

                # format string to be used as quickfix argument
                lines = b[0:]
                err = '%s:%d:%s' % (b.name, lines.index(line) + 1, line)

                # only include lines with matchiness > 0
                if matchiness > 0:
                    matching_lines.append({'matchiness':matchiness,'err_string':err})

# sort based on matchiness descending
matching_lines = sorted(matching_lines, key=lambda k: k['matchiness']) 
matching_lines.reverse()

# "error" refers to quickfix item
error_list = []
for error in matching_lines:
    error_list.append(escape(error['err_string']))
    
if len(error_list):
    if len(error_list) == 1:
        error_string = error_list[0]
        thecommand = 'cexpr "%s"' % error_string
        vim.command(thecommand)
    else:
        # join quickfix formatted strings with newlines
        error_string = '\\n'.join(error_list)

        # prepare quickfix list creation command
        thecommand = 'cgetexpr "%s"' % error_string

        # Create quickfix list and open it
        vim.command(thecommand)
        vim.command('copen')
else:
    vim.command('echo "JumpToCSS: No matches found"')
EOF
endfunction
