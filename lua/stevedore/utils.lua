local M = {}

M.get_line_id = function(line)
	return line:match("^/(%x+)/")
end

---@param cmd string[]
M.term_win = function(cmd, opts)
	opts = opts or {}
	vim.cmd.vnew()
	local bufnr = vim.fn.bufnr()
	local options = { term = true }
	if opts.close_on_done then
		-- :h on_exit
		options.on_exit = function(job_id, exit_code, event)
			vim.cmd("silent bdelete! " .. bufnr)
		end
	end
	vim.fn.jobstart(cmd, options)
end

---@param cmd string[]
M.exec_cmd = function(cmd)
	local obj = vim.system(cmd, {}):wait()
	if obj.code == 0 then
		vim.api.nvim_echo({ { obj.stdout } }, true, {})
	else
		vim.api.nvim_echo({ { obj.stderr } }, true, { err = true })
	end
end

return M
