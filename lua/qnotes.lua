local M = {}

local defaults = {
    notes_directory = os.getenv("HOME") .. "/notes",
    file_extension = ".md",
    journal_subdirectory = "journal",
    tags_separator = ",",
    indicator_text = "N", -- The indicator text to display
}

local notes_metadata = {}
local diagnostic_ns = vim.api.nvim_create_namespace("qnotes") -- Create a namespace for diagnostics

function M.setup(opts)
    opts = opts or {}
    local notes_directory = vim.fn.expand(opts.notes_dir) or vim.fn.expand(defaults.notes_directory)


    local function saveNotesMetadata()

        local data = vim.fn.json_encode(notes_metadata)
        local file_path = notes_directory .. "/qnotes_metadata.json" -- Ensure this matches how you construct paths for notes
        local file, err = io.open(file_path, "w")
        if not file then
            print("Failed to save notes metadata: " .. tostring(err))
            return
        end

        file:write(data)
        file:close()
        print("Metadata saved to: " .. file_path) -- Confirm the path for debugging
    end

    local function loadNotesMetadata()
        local file_path = notes_directory .. "/qnotes_metadata.json"
        local file, err = io.open(file_path, "r")
        if not file then
            print("Failed to load notes metadata: " .. tostring(err))
            notes_metadata = {} -- Initialize as empty if the file doesn't exist or can't be opened
            return
        end

        local data = file:read("*a")
        notes_metadata = vim.fn.json_decode(data)
        file:close()
        print("Metadata loaded from: " .. file_path) -- Confirm the path for debugging
    end
    -- Call loadNotesMetadata at the beginning of your plugin setup
    loadNotesMetadata()

    local function updateIndicators()
        local current_file = vim.fn.expand("%:p")
        local diagnostics = {}

        if notes_metadata[current_file] then
            for _, line in ipairs(notes_metadata[current_file]) do
                table.insert(diagnostics, {
                    lnum = line - 1, -- Lua is 1-indexed, Neovim API expects 0-indexed
                    col = 0,
                    message = "Note exists for this line",
                    severity = vim.diagnostic.severity.INFO,
                    source = "qnotes",
                })
            end
        end

        -- Clear existing diagnostics for the buffer before setting new ones
        vim.diagnostic.reset(diagnostic_ns, vim.fn.bufnr())

        -- Now set the diagnostics with the updated list
        vim.diagnostic.set(diagnostic_ns, vim.fn.bufnr(), diagnostics, {
            virtual_text = false,
            signs = true,
            underline = false,
            update_in_insert = false,
        })

        print("Updated indicators for", current_file)
    end

    -- Function to create a new note
    local function createNote()

        -- Get the filename from the user or use Telescope for file selection
        local filename = vim.fn.input("Enter filename: ")
        if not filename or filename == "" then
            local date_str = os.date("%Y-%m-%d")
            filename = date_str .. "-journal" .. defaults.file_extension

            -- Files created with the date-based and "journal" filename will be placed in the "journal" subdirectory
            notes_directory = notes_directory .. "/" .. defaults.journal_subdirectory
            vim.fn.mkdir(notes_directory, "p")
        else
            -- Ensure the filename has the appropriate extension
            if not filename:match(defaults.file_extension .. "$") then
                filename = filename .. defaults.file_extension
            end

            local full_path = notes_directory .. "/" .. filename

            -- Check if the file already exists
            if vim.fn.filereadable(full_path) ~= 0 then
                local user_choice = vim.fn.input("File already exists. Do you want to edit it? (y/n): ")
                if user_choice:lower() == "y" then
                    vim.cmd("edit " .. full_path)
                    print("Opened existing file for editing: " .. full_path)
                    return
                else
                    print("Creation aborted. File already exists: " .. full_path)
                    return
                end
            end
        end

        local full_path = notes_directory .. "/" .. filename

        -- Remove the .md extension from the title
        local title = filename:gsub(defaults.file_extension .. "$", "")

        -- Ask the user for tags
        local tags = vim.fn.input("Enter tags (comma-separated): ")

        -- Create the file and open it for editing with front matter
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

    -- Function to create a note linked to a specific line in the current file
    local function createLineNote()
        local current_file = vim.fn.expand("%:p")
        local line_number = vim.fn.line(".")
        local notes_directory = vim.fn.expand(opts.notes_dir) or vim.fn.expand(defaults.notes_directory)

        -- Generate filename based on the current file's name and line number
        local base_filename = vim.fn.expand("%:t:r")
        local filename = string.format("codenote_%s-l%d%s", base_filename, line_number, defaults.file_extension)
        
        local full_path = notes_directory .. "/" .. filename

        -- Check if the file already exists
        if vim.fn.filereadable(full_path) ~= 0 then
            local user_choice = vim.fn.input("File already exists. Do you want to edit it? (y/n): ")
            if user_choice:lower() == "y" then
                vim.cmd("edit " .. full_path)
                print("Opened existing file for editing: " .. full_path)
                return
            else
                print("Creation aborted. File already exists: " .. full_path)
                return
            end
        end

        -- Create the file and open it for editing
        local file, error_message = io.open(full_path, "w")
        if not file then
            print("Error creating file: " .. error_message)
            return
        end

        file:close()

        -- Store note metadata
        if not notes_metadata[current_file] then
            notes_metadata[current_file] = {}
        end
        table.insert(notes_metadata[current_file], line_number)
        saveNotesMetadata()  -- Save after updating

        vim.cmd("edit " .. full_path)
        print("Note created and linked to " .. current_file .. " at line " .. line_number .. ": " .. full_path)

        -- Update the indicator
        updateIndicators()
    end

    local function deleteLineNote()
        local current_file = vim.fn.expand("%:p")
        local line_number = vim.fn.line(".")
        local base_filename = vim.fn.expand("%:t:r")
        local filename = string.format("codenote_%s-l%d%s", base_filename, line_number, defaults.file_extension)
        local full_path = notes_directory .. "/" .. filename

        -- Check if the file exists
        if vim.fn.filereadable(full_path) == 0 then
            print("Note does not exist: " .. full_path)
            return
        end

        -- Optional: Prompt for confirmation
        local user_choice = vim.fn.input("Are you sure you want to delete this note? (y/n): ")
        if user_choice:lower() ~= "y" then
            print("Deletion aborted.")
            return
        end

        -- Delete the file
        local success, err = os.remove(full_path)
        if success then
            print("Note deleted successfully: " .. full_path)
            -- Remove metadata
            if notes_metadata[current_file] then
                for i, line in ipairs(notes_metadata[current_file]) do
                    if line == line_number then
                        table.remove(notes_metadata[current_file], i)
                        break
                    end
                end
                if #notes_metadata[current_file] == 0 then
                    notes_metadata[current_file] = nil
                end
                saveNotesMetadata()  -- Save after updating
            end
            -- Refresh the current buffer
            vim.cmd('edit!')
        else
            print("Error deleting file: " .. err)
        end
    end

    -- Configure keymaps
    local create_note_keymap = opts.create_note_keymap or "<leader>qn"
    vim.keymap.set("n", create_note_keymap, createNote)

    local search_note_keymap = opts.search_note_keymap or "<leader>qf"
    vim.keymap.set("n", search_note_keymap, function()
        local notes_directory = opts.notes_dir or defaults.notes_directory

        require("telescope.builtin").live_grep({
            prompt_title = "Live Grep",
            cwd = notes_directory,
        })
    end)

    local create_line_note_keymap = opts.create_line_note_keymap or "<leader>ql"
    vim.keymap.set("n", create_line_note_keymap, createLineNote)


    local delete_line_note_keymap = opts.delete_line_note_keymap or "<leader>qd"
    vim.keymap.set("n", delete_line_note_keymap, deleteLineNote)

    -- Autocmd to update indicators when entering a buffer
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
            updateIndicators()
        end
    })
end

-- Define the diagnostic sign
vim.fn.sign_define("QNotesSign", { text = "N"})

return M
