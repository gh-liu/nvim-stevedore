local utils = require("stevedore.utils")
local term_win = utils.term_win
local exec_cmd = utils.exec_cmd

---@type Stevedore
local Docker = {}

---@return image[]
Docker.list_images = function()
	local images = {}
	local obj = vim.system(
		{ "docker", "images", "--format", "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" },
		{ text = true }
	)
		:wait()
	if obj.code ~= 0 then
		vim.api.nvim_echo({ { obj.stderr } }, true, { err = true })
		return {}
	end
	local image_lines = vim.split(obj.stdout, "\n", { trimempty = true })
	for _, line in ipairs(image_lines) do
		local parts = vim.split(line, " ", {})
		table.insert(images, {
			id = parts[1],
			repo = parts[2],
			tag = parts[3],
			name = string.format("%s:%s", parts[2], parts[3]),
		})
	end
	return images
end

---@return container[]
Docker.list_containers = function(id)
	local containers = {}
	local obj = vim.system(
		{ "docker", "ps", "-a", "--format", "{{.ID}} {{.Command}} {{.Image}} {{.Names}} {{.Status}}" },
		{ text = true }
	):wait()
	if obj.code ~= 0 then
		vim.api.nvim_echo({ { obj.stderr } }, true, { err = true })
		return {}
	end
	local image_lines = vim.split(obj.stdout, "\n", { trimempty = true })
	for _, line in ipairs(image_lines) do
		local parts = vim.split(line, " ", {})
		table.insert(containers, {
			id = parts[1],
			image_name = parts[2], -- TODO: current is command, not image name
			image_id = parts[3],
			name = parts[4],
			status = parts[5],
		})
	end
	return vim.iter(containers)
		:map(function(c)
			if vim.deep_equal(c.image_id, id) then
				return c
			end
		end)
		:totable()
end

---@return string
Docker.inspect = function(id)
	local obj = vim.system({ "docker", "inspect", id }, { text = true }):wait()
	return obj.stdout
end

Docker.attach = function(id, opts)
	opts = opts or {}
	if opts.shell then
		term_win({ "docker", "exec", "-it", id, "bash" })
	else
		term_win({ "docker", "attach", id })
	end
end

Docker.run = function(id, opts)
	opts = opts or {}
	local interactive = opts.interactive or false
	local name = opts.name
	local cmd = { "docker", "run" }
	if name then
		table.insert(cmd, "--name")
		table.insert(cmd, name)
	end
	if interactive then
		table.insert(cmd, "--rm")
		table.insert(cmd, "-it")
		table.insert(cmd, id)
		term_win(cmd)
	else
		table.insert(cmd, "-d")
		table.insert(cmd, id)
		exec_cmd(cmd)
	end
end

Docker.start = function(id, opts)
	opts = opts or {}
	local interactive = opts.interactive or false
	if interactive then
		term_win({ "docker", "start", "-ia", id })
	else
		exec_cmd({ "docker", "start", id })
	end
end

Docker.stop = function(id)
	exec_cmd({ "docker", "stop", id })
end

Docker.status = function(id)
	local obj = vim.system({ "docker", "ps", "-a", "-f", "id=" .. id, "--format", "json" }, { text = true }):wait()
	local containers = vim.json.decode(obj.stdout)
	if #containers == 0 then
		return
	end
	return {
		status = containers[1]["State"],
		state = containers[1]["Status"],
	} ---@type container_status
end

Docker.logs = function(id)
	term_win({ "docker", "logs", "-f", "--tail", "1000", id })
end

Docker.rmi = function(id, opts)
	opts = opts or {}
	if opts.force then
		exec_cmd({ "docker", "rmi", "--force", id })
	else
		exec_cmd({ "docker", "rmi", id })
	end
end

Docker.rm = function(id)
	exec_cmd({ "docker", "rm", id })
end

Docker.pull = function(name)
	term_win({ "docker", "pull", name }, { close_on_done = true })
end

return Docker
