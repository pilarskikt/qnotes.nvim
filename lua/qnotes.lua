local M = {}

local defaults = {
	notes_directory = os.getenv("HOME") .. "/notes",
	file_extension = ".md",
	journal_subdirectory = "journal",
	tags_separator = ",",
}

function M.setup(opts)
	opts = opts or {}

	local function createNote()
		local notes_directory = vim.fn.expand(opts.notes_dir) or vim.fn.expand(defaults.notes_directory)

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

	-- Telescope integration for file selection
	local live_grep_keymap = opts.live_grep_keymap or "<leader>f"
	vim.keymap.set("n", live_grep_keymap, function()
		local notes_directory = opts.notes_dir or defaults.notes_directory

		require("telescope.builtin").live_grep({
			prompt_title = "Live Grep",
			cwd = notes_directory,
		})
	end)

	vim.keymap.set("n", "<leader>n", createNote)
end

return M
