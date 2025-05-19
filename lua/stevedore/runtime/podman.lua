local utils = require("stevedore.utils")
local term_win = utils.term_win
local exec_cmd = utils.exec_cmd

---@type Stevedore
local Podman = {}

---@return image[]
Podman.list_images = function()
	local images = {}
	local obj = vim.system(
		{ "podman", "images", "--format", "{{.ID}} {{.Repository}} {{.Tag}} {{.Size}}" },
		{ text = true }
	)
		:wait()
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
Podman.list_containers = function(id)
	local containers = {}
	local obj = vim.system(
		{ "podman", "ps", "-a", "--format", "{{.ID}} {{.Image}} {{.ImageID}} {{.Names}} {{.Status}}" },
		{ text = true }
	):wait()
	local image_lines = vim.split(obj.stdout, "\n", { trimempty = true })
	for _, line in ipairs(image_lines) do
		local parts = vim.split(line, " ", {})
		table.insert(containers, {
			id = parts[1],
			image_name = parts[2],
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
Podman.inspect = function(id)
	local obj = vim.system({ "podman", "inspect", id }, { text = true }):wait()
	return obj.stdout
end

Podman.attach = function(id, opts)
	opts = opts or {}
	if opts.shell then
		term_win({ "podman", "exec", "-it", id, "bash" })
	else
		term_win({ "podman", "attach", id })
	end
end

Podman.run = function(id, opts)
	opts = opts or {}
	local interactive = opts.interactive or false
	local name = opts.name
	local cmd = { "podman", "run" }
	if name then
		table.insert(cmd, "--name")
		table.insert(cmd, name)
	end
	if interactive then
		table.insert(cmd, "--rm", "-it")
		table.insert(cmd, id)
		term_win(cmd)
	else
		table.insert(cmd, "-d")
		table.insert(cmd, id)
		exec_cmd(cmd)
	end
end

Podman.start = function(id, opts)
	opts = opts or {}
	local interactive = opts.interactive or false
	if interactive then
		term_win({ "podman", "start", "-ia", id })
	else
		exec_cmd({ "podman", "start", id })
	end
end

Podman.stop = function(id)
	exec_cmd({ "podman", "stop", id })
end

Podman.status = function(id)
	local obj = vim.system({ "podman", "ps", "-a", "-f", "id=" .. id, "--format", "json" }, { text = true }):wait()
	local containers = vim.json.decode(obj.stdout)
	if #containers == 0 then
		return
	end
	return {
		status = containers[1]["State"],
		state = containers[1]["Status"],
	} ---@type container_status
end

Podman.logs = function(id)
	term_win({ "podman", "logs", "-f", "--tail", "1000", id })
end

Podman.rmi = function(id, opts)
	opts = opts or {}
	if opts.force then
		exec_cmd({ "podman", "rmi", "--force", id })
	else
		exec_cmd({ "podman", "rmi", id })
	end
end

Podman.rm = function(id)
	exec_cmd({ "podman", "rm", id })
end

Podman.pull = function(name)
	term_win({ "podman", "pull", name }, { close_on_done = true })
end

return Podman
