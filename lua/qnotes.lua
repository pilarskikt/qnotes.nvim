local M = {}

local defaults = {
    notes_directory = os.getenv("HOME") .. "/notes",
    file_extension = ".md",
    journal_subdirectory = "journal",
    tags_separator = ",",
}

local notes_metadata = {}
local ns_id = vim.api.nvim_create_namespace("qnotes")

-- Utility function to get the full path of a note file
local function getNoteFilePath(base_filename)
    local codenotes_directory = notes_directory .. "/codenotes"
    vim.fn.mkdir(codenotes_directory, "p") -- Ensure the codenotes directory exists
    return codenotes_directory .. "/" .. "codenote_" .. base_filename .. defaults.file_extension
end

-- Utility function to save notes metadata
local function saveNotesMetadata()
    local data = vim.fn.json_encode(notes_metadata)
    local file_path = notes_directory .. "/qnotes_metadata.json"
    local file, err = io.open(file_path, "w")
    if not file then
        print("Failed to save notes metadata: " .. tostring(err))
        return
    end
    file:write(data)
    file:close()
    print("Metadata saved to: " .. file_path)
end

-- Utility function to load notes metadata
local function loadNotesMetadata()
    local file_path = notes_directory .. "/qnotes_metadata.json"
    local file, err = io.open(file_path, "r")
    if not file then
        print("Failed to load notes metadata: " .. tostring(err))
        notes_metadata = {}
        return
    end
    local data = file:read("*a")
    notes_metadata = vim.fn.json_decode(data)
    file:close()
    print("Metadata loaded from: " .. file_path)
end

-- Function to update indicators for notes in the buffer
local function updateIndicators()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    local current_file = vim.fn.expand("%:p")
    if notes_metadata[current_file] then
        for _, note in ipairs(notes_metadata[current_file]) do
            local line_number = note.line
            local note_content = note.content
            vim.api.nvim_buf_set_extmark(0, ns_id, line_number - 1, 0, {
                virt_text = {{note_content, "Comment"}},
                virt_text_pos = "eol",
            })
        end
    end
    print("Updated indicators for", current_file)
end

-- Function to create a new note
local function createNote()
    local filename = vim.fn.input("Enter filename: ")
    local full_path

    if not filename or filename == "" then
        local date_str = os.date("%Y-%m-%d")
        filename = date_str .. "-journal" .. defaults.file_extension
        full_path = notes_directory .. "/" .. defaults.journal_subdirectory .. "/" .. filename
        vim.fn.mkdir(notes_directory .. "/" .. defaults.journal_subdirectory, "p")
    else
        if not filename:match(defaults.file_extension .. "$") then
            filename = filename .. defaults.file_extension
        end
        full_path = notes_directory .. "/" .. filename
    end

    local title = filename:gsub(defaults.file_extension .. "$", "")
    local tags = vim.fn.input("Enter tags (comma-separated): ")
    local file, error_message = io.open(full_path, "w")
    if not file then
        print("Error creating file: " .. error_message)
        return
    end
    file:write(string.format("---\ntitle: %s\ntags: %s\n---\n", title, tags))
    file:close()
    vim.cmd("edit " .. full_path)
    print("Note created and opened: " .. full_path)
end

-- Function to create a line note
local function createLineNote()
    local current_file = vim.fn.expand("%:p")
    local line_number = vim.fn.line(".")
    local base_filename = vim.fn.expand("%:t:r")
    local note_file = getNoteFilePath(base_filename)

    local file, error_message = io.open(note_file, "a+")
    if not file then
        print("Error opening note file: " .. error_message)
        return
    end

    local note_content = vim.fn.input("Enter note content: ")
    local note = {
        line = line_number,
        content = note_content,
    }

    -- Update notes metadata
    local notes = notes_metadata[current_file] or {}
    table.insert(notes, note)
    notes_metadata[current_file] = notes
    saveNotesMetadata()

    -- Append note content to the note file
    file:write(string.format("Line %d: %s\n", line_number, note_content))
    file:close()

    print("Note created and linked to " .. current_file .. " at line " .. line_number)
    updateIndicators()
end

-- Function to delete a line note
local function deleteLineNote()
    local current_file = vim.fn.expand("%:p")
    local line_number = vim.fn.line(".")
    local base_filename = vim.fn.expand("%:t:r")
    local note_file = getNoteFilePath(base_filename)

    if vim.fn.filereadable(note_file) == 0 then
        print("Note file does not exist: " .. note_file)
        return
    end

    local file = io.open(note_file, "r")
    local lines = file:read("*a")
    file:close()

    local updated_lines = {}
    local notes = notes_metadata[current_file] or {}

    for _, note in ipairs(notes) do
        if note.line ~= line_number then
            table.insert(updated_lines, string.format("Line %d: %s", note.line, note.content))
        end
    end

    local new_file, error_message = io.open(note_file, "w")
    if not new_file then
        print("Error opening note file: " .. error_message)
        return
    end

    new_file:write(table.concat(updated_lines, "\n"))
    new_file:close()

    -- Update metadata
    notes_metadata[current_file] = vim.tbl_filter(function(n) return n.line ~= line_number end, notes)
    saveNotesMetadata()

    -- Check if the note file is now empty and delete it if so
    local file_size = vim.fn.getfsize(note_file)
    if file_size == 0 then
        os.remove(note_file)
        print("Note file was empty and has been deleted: " .. note_file)

        if not next(notes_metadata[current_file]) then
            notes_metadata[current_file] = nil
            saveNotesMetadata()
        end
    else
        print("Note deleted from " .. current_file .. " at line " .. line_number)
    end

    updateIndicators()
end

-- Setup key mappings and autocommands
function M.setup(opts)
    opts = opts or {}
    notes_directory = vim.fn.expand(opts.notes_dir or defaults.notes_directory)

    loadNotesMetadata()

    vim.keymap.set("n", opts.create_note_keymap or "<leader>qn", createNote)
    vim.keymap.set("n", opts.search_note_keymap or "<leader>qf", function()
        require("telescope.builtin").live_grep({
            prompt_title = "Live Grep",
            cwd = notes_directory,
        })
    end)
    vim.keymap.set("n", opts.create_line_note_keymap or "<leader>ql", createLineNote)
    vim.keymap.set("n", opts.delete_line_note_keymap or "<leader>qd", deleteLineNote)

    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = updateIndicators,
    })
end

return M
