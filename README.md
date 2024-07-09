# <p align="center"> <img src="logo.png" width="100" height="100"> </br> qNotes </p>

This plugin is my primitive way of doing notes as i use NeoVim as my daily code editor.
[![asciicast](https://asciinema.org/a/642563.svg)](https://asciinema.org/a/642563)

## Requirements
* [Neovim > v0.7.0](https://github.com/neovim/neovim/releases/tag/v0.7.0)
* [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    'pilarskikt/qnotes.nvim',
    dependencies={
        {'nvim-telescope/telescope.nvim', branch='0.1.x'}
    },
}
```

## Configuration
You can configure the directory in which you want to keep your notes or stay with default which is `~/notes`
to configure directory please use `notes_dir` for example:
```lua
return {
    'pilarskikt/qnotes.nvim',
    dependencies={
        {'nvim-telescope/telescope.nvim', branch='0.1.x'}
    },
  opts = {
    notes_dir = "~/my_notes/custom/dir"
  },
}
```
User can also create use own keymaps which are `create_note_keymap`, `search_note_keymap`, 'create_line_note_keymap' and 'delete_line_note_keymap':
```lua
return {
    'pilarskikt/qnotes.nvim',
    dependencies={
        {'nvim-telescope/telescope.nvim', branch='0.1.x'}
    },
  opts = {
    create_note_keymap = "<leader>n",
    search_note_keymap = "<leader>f",
  },
}
```

## Usage
At the moment there are four keymaps:\
`<leader>qn` - for creating new note\
`<leader>qf` - for searching through notes
`<leader>ql` - create new note for specific line of code(it will trigger creating(if doesnt exist) metadata file that keeps information about lines that have linked notes)
`<leader>qd` - delete note for current line

When creating new note you will be asked for filename of the notes and tags. If filename is not provided qnotes will create journalfile named `{CURRENT_DATE}-JOURNAL.MD`
the file is going to be created in `journal` subdirectory of your notes directory.
