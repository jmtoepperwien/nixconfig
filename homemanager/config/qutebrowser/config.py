import sys

config.load_autoconfig()
config.bind('<Ctrl-J>', 'completion-item-focus next', mode='command')
config.bind('<Ctrl-K>', 'completion-item-focus prev', mode='command')

c.downloads.position = 'bottom'

# gruvbox theme
css = './solarized-everything-css/css/gruvbox/gruvbox-all-sites.css'
config.source('./gruvbox.py')

# Tab binds
config.bind('!', 'tab-focus 1', mode='normal')
config.bind('@', 'tab-focus 2', mode='normal')
config.bind('#', 'tab-focus 3', mode='normal')
config.bind('$', 'tab-focus 4', mode='normal')
config.bind('%', 'tab-focus 5', mode='normal')
config.bind('^', 'tab-focus 6', mode='normal')
config.bind('&', 'tab-focus 7', mode='normal')
config.bind('*', 'tab-focus 8', mode='normal')
config.bind('(', 'tab-focus -1', mode='normal')

config.bind(',m', 'hint links spawn mpv {hint-url}')
