local autocmd = vim.api.nvim_create_autocmd

vim.api.nvim_set_hl(0, "StevedoreID", { link = "Label", default = true })

---@class image
---@field id string
---@field repo string
---@field tag string
---@field name string
---@field create number
---@field size number

---@class container_status
---@field state string
---@field status string

---@class container: container_status
---@field id string
---@field name string
---@field image_id string
---@field image_name string

---@class Stevedore
---@field list_images fun(): image[]
---@field list_containers fun(image_id: string): container[]
---@field inspect fun(id: string): string
---@field attach fun(id: string, opts: table)
---@field run fun(id: string, opts: table)
---@field start fun(id: string, opts: table)
---@field stop fun(id: string)
---@field status fun(id: string): container_status
---@field logs fun(id: string)
---@field rmi fun(id: string, opts: table)
---@field rm fun(id: string)
---@field pull fun(name: string)

---@type Stevedore
local Runtime = require(vim.g.stevedore_runtime)

local Action = require("stevedore.action").new(Runtime)

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

local set_conceal = function()
	vim.wo[0][0].concealcursor = "nvic"
	vim.wo[0][0].conceallevel = 3
end

local set_lines = function(buf, lines)
	local cmd = string.format("lockmarks lua vim.api.nvim_buf_set_lines(%d, 0, -1, false, %s)", buf, vim.inspect(lines))
	vim.cmd(cmd)
	vim.bo[buf].modified = false
end

local proper_cursor = function()
	vim.fn.search("^/\\x\\+/\\S", "ez", vim.fn.line("."))
end

local Stevedore = {}

local format_line = function(id, name)
	return string.format("/%s/%s", id, name)
end

local update_lines = function()
	vim.cmd.edit() -- TODO
end

Stevedore.list_images = function(buf)
	autocmd("BufEnter", {
		buffer = buf,
		callback = function()
			local images = Runtime.list_images()
			vim.b[buf].images = images

			local images_names = {} ---@type string[]
			for _, image in ipairs(images) do
				table.insert(images_names, format_line(image.id, image.name))
			end
			set_lines(buf, images_names)

			proper_cursor()

			local virt_texts = {}
			for idx, image in ipairs(images) do
				table.insert(virt_texts, { { image.id, "StevedoreID" } })
			end
			set_extmark_virt_text(buf, virt_texts)

			set_conceal()
		end,
	})

	vim.keymap.set("n", "<cr>", Action.split_containers, { buffer = 0 })
	vim.keymap.set("n", "coi", Action.inspect, { buffer = 0 })
	vim.keymap.set("n", "cor", function()
		Action.run_image(nil, { interactive = true })
	end, { buffer = 0 })
	vim.keymap.set("n", "coR", function()
		Action.run_image(nil, { interactive = false })
	end, { buffer = 0 })
	vim.keymap.set("n", "cod", function()
		Action.rmi(nil, { force = false })
		update_lines()
	end, { buffer = 0 })
	vim.keymap.set("n", "coD", function()
		Action.rmi(nil, { force = true })
		update_lines()
	end, { buffer = 0 })
end

Stevedore.list_containers = function(buf, image_id)
	autocmd("BufEnter", {
		buffer = buf,
		callback = function()
			local containers = Runtime.list_containers(image_id)
			vim.b[buf].containers = containers

			local container_names = {} ---@type string[]
			for _, c in ipairs(containers) do
				table.insert(container_names, format_line(c.id, c.name))
			end
			set_lines(buf, container_names)

			proper_cursor()

			local virt_texts = {}
			local signs = {}
			for idx, c in ipairs(containers) do
				table.insert(virt_texts, {
					{ c.image_name, "@comment" },
					{ " ", "" },
					{ c.id, "StevedoreID" },
				})

				if c.status == "Up" then
					table.insert(signs, { sign_text = "", sign_hl_group = "DiagnosticOk" })
				else
					table.insert(signs, { sign_text = "⊗", sign_hl_group = "DiagnosticError" })
				end
			end
			set_extmark_virt_text(buf, virt_texts)
			set_extmark_signs(buf, signs)

			set_conceal()
		end,
	})

	vim.keymap.set("n", "coi", Action.inspect, { buffer = 0 })
	vim.keymap.set("n", "coa", function()
		Action.attach_container()
	end, { buffer = 0 })
	vim.keymap.set("n", "cos", function()
		Action.start({ interactive = true })
	end, { buffer = 0 })
	vim.keymap.set("n", "coS", function()
		Action.start({ interactive = false })
	end, { buffer = 0 })
	vim.keymap.set("n", "coq", Action.stop, { buffer = 0 })
	vim.keymap.set("n", "col", Action.logs, { buffer = 0 })
	vim.keymap.set("n", "cod", function()
		Action.rm()
		update_lines()
	end, { buffer = 0 })
end

Stevedore.inspect = function(buf, id)
	local res = Runtime.inspect(id)
	local lines = vim.split(res, "\n", {})
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "json"
end

---@param fn function()
local with_disable_undo = function(fn)
	-- Make sure that pressing `u` in new buffer does nothing
	local cache_undolevels = vim.bo[0].undolevels
	vim.bo[0].undolevels = -1
	fn()
	vim.bo[0].undolevels = cache_undolevels
end

local get_line_id = require("stevedore.utils").get_line_id

local set_keywordprg = function(buf)
	vim.bo[buf].keywordprg = ":StevedoreInfo"

	vim.api.nvim_buf_create_user_command(buf, "StevedoreInfo", function()
		if vim.b.images then
			local id = get_line_id(vim.fn.getline("."))
			local image = vim.iter(vim.b.images):find(function(v)
				return v.id == id
			end)
			if image then
				vim.api.nvim_echo({ { image.name }, { " " }, { image.id, "StevedoreID" } }, true, {})
			end
		end
		if vim.b.containers then
			local id = get_line_id(vim.fn.getline("."))
			local container = vim.iter(vim.b.containers):find(function(v)
				return v.id == id
			end)
			if container then
				vim.api.nvim_echo({
					{ container.status },
					{ " " },
					{ container.image_name },
					{ " " },
					{ container.name },
					{ " " },
					{ container.id, "StevedoreID" },
				}, true, {})
			end
		end
	end, { nargs = 1 })
end

local M = {}

M.BufReadCmd = function()
	with_disable_undo(function()
		local match = vim.fn.expand("<amatch>")
		local buf = vim.api.nvim_get_current_buf()

		vim.bo[buf].filetype = "stevedore"
		set_keywordprg(buf)

		if match == "stevedore:///" then
			Stevedore.list_images(buf)
			return
		end

		local _, _, image_id = match:find([[^stevedore:///(%x+)/$]])
		if image_id then
			Stevedore.list_containers(buf, image_id)
			return
		end

		local _, _, image_id, container_id = match:find([[^stevedore:///(%x+)/(%x+)$]])
		if image_id and container_id then
			Stevedore.inspect(buf, container_id)
			return
		end

		local _, _, image_id = match:find([[^stevedore:///(%x+)$]])
		if image_id then
			Stevedore.inspect(buf, image_id)
			return
		end
	end)
end

M.BufWriteCmd = function()
	if vim.b.images then
		local id2image = {}
		for _, image in ipairs(vim.b.images) do
			id2image[image.id] = image
		end

		local need_create = {}
		local need_delete = {}

		local cur_ids = {}
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		for _, line in ipairs(lines) do
			local id = get_line_id(line)
			if not id then
				table.insert(need_create, line)
			else
				local lines = cur_ids[id] or {}
				table.insert(lines, line)
				cur_ids[id] = lines
			end
		end
		for id, _ in pairs(id2image) do
			if not cur_ids[id] then
				table.insert(need_delete, id)
			end
		end
		for _, id in ipairs(need_delete) do
			Action.rmi(id, {})
			print("delete " .. id)
		end
		for _, name in ipairs(need_create) do
			Action.pull(name) -- TODO: which asyc, how to update the images buffer
			print("create " .. name)
		end
	end
	if vim.b.containers then
		local id2container = {}
		for _, container in ipairs(vim.b.containers) do
			id2container[container.id] = container
		end

		local need_create = {}
		local need_delete = {}

		local cur_ids = {}
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		for _, line in ipairs(lines) do
			local id = get_line_id(line)
			if not id then
				table.insert(need_create, line)
			else
				local lines = cur_ids[id] or {}
				table.insert(lines, line)
				cur_ids[id] = lines
			end
		end
		for id, _ in pairs(id2container) do
			if not cur_ids[id] then
				table.insert(need_delete, id)
			end
		end
		for _, id in ipairs(need_delete) do
			Action.rm(id)
			print("delete " .. id)
		end
		for _, name in ipairs(need_create) do
			print("create " .. name)
			local id = vim.fn.bufname():match("stevedore:///(.*)/")
			Action.run_image(id, { name = name })
		end
	end

	vim.bo.modified = false
end
return M
