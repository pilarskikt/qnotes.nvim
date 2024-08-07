# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.7 2024-07-30
### Changed
- from now on notes for specific line of code are displayed as virtual text, plugin no longer use diagnostic signs as indicators of existing line note
- line notes created for some file are no longer created separately for every line note 

## 0.0.5
### Added
- creating note for specific line of code, can be triggered with `<leader>ql` by default or set with custom keymap under `create_line_note_keymap `.
delete line specific note is also available by default with `<leader>qd` or with custom keymap by setting `delete_line_note_keymap`.
- line specific notes are using json file to keep metadata information about file and line with linked note, metadata file is created in same directory as notes

## 0.0.3
### Added
- added posibility for setting custom keymaps under `create_note_keymap` and `search_note_keymap` 
more details how to set it up can be found in README.md


## 0.0.2 - 2024-02-23
### Added
- added tags functionality for notes
- now notes uses front matter with tags provided during note creation and title taken from filename

## [0.0.1] - 2024-02-23
### Added

- initial commit of plugin code
