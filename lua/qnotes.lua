local M = {}

local defaults = {
	notes_directory = os.getenv("HOME") .. "/notes",
	file_extension = ".md",
	journal_subdirectory = "journal",
}

function M.setup(opts)
	opts = opts or {}
	local create_keymap = opts.create_keymap or "<leader>n"
	local search_keymap = opts.search_keymap or "<leader>f"

	vim.keymap.set("n", create_keymap, function()
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

		-- Check if the directory exists, create it if not
		vim.fn.mkdir(notes_directory, "p")

		-- Create the file and open it for editing
		vim.fn.writefile({ "" }, full_path)
		vim.cmd("edit " .. full_path)
		print("Created and opened: " .. full_path)
	end)

	-- Telescope integration for file selection
	vim.keymap.set("n", search_keymap, function()
		local notes_directory = opts.notes_dir or defaults.notes_directory

		require("telescope.builtin").live_grep({
			prompt_title = "Live Grep",
			cwd = notes_directory,
		})
	end)
end

return M
