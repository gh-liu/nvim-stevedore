local M = {}

local set_lines = function(buf, lines)
	local cmd = string.format("lockmarks lua vim.api.nvim_buf_set_lines(%d, 0, -1, false, %s)", buf, vim.inspect(lines))
	vim.cmd(cmd)
	vim.bo[buf].modified = false
end

local ns = vim.api.nvim_create_namespace("stevedore")
local set_extmark_virt_text = function(buf, virt_texts)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for line, virt_text in ipairs(virt_texts) do
		vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
			invalidate = true,
			virt_text_pos = "eol_right_align",
			virt_text = virt_text,
		})
	end
end

local status_sign_ns = vim.api.nvim_create_namespace("stevedore/status_sign")
local set_extmark_signs = function(buf, signs)
	vim.api.nvim_buf_clear_namespace(buf, status_sign_ns, 0, -1)
	for line, sign in ipairs(signs) do
		vim.api.nvim_buf_set_extmark(buf, status_sign_ns, line - 1, 0, {
			invalidate = true,
			sign_text = sign.sign_text,
			sign_hl_group = sign.sign_hl_group,
		})
	end
end

M.update_lines = function(buf, datas, format)
	local lines = {}
	local virt_texts = {}
	local signs = {}

	if format then
		for _, data in ipairs(datas) do
			local res = format(data)
			if res then
				table.insert(lines, res.line)
				if res.virt_text then
					table.insert(virt_texts, res.virt_text)
				end
				if res.sign then
					table.insert(signs, res.sign)
				end
			end
		end
	end
	set_lines(buf, #lines > 0 and lines or datas)
	set_extmark_virt_text(buf, virt_texts)
	set_extmark_signs(buf, signs)
end

return M
