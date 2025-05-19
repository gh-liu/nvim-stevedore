local Action = {
	Runtime = nil, ---@type Stevedore
}

local split_bufname = function(bufname)
	vim.cmd("vsplit " .. bufname)
end

Action.get_current_line_id = function()
	return require("stevedore.utils").get_line_id(vim.fn.getline("."))
end

Action.split_containers = function()
	local id = Action.get_current_line_id()
	split_bufname(vim.fn.bufname() .. id .. "/")
end

Action.attach_container = function(opts)
	Action.Runtime.attach(Action.get_current_line_id(), opts)
end

Action.run_image = function(id, opts)
	id = id or Action.get_current_line_id()
	Action.Runtime.run(id, opts)
end

Action.inspect = function()
	local id = Action.get_current_line_id()
	split_bufname(vim.fn.bufname() .. id)
end

Action.stop = function()
	Action.Runtime.stop(Action.get_current_line_id())
end

Action.start = function(opts)
	Action.Runtime.start(Action.get_current_line_id(), opts)
end

Action.logs = function()
	Action.Runtime.logs(Action.get_current_line_id())
end

Action.rmi = function(id, opts)
	id = id or Action.get_current_line_id()
	Action.Runtime.rmi(id, opts)
end

Action.rm = function(id)
	id = id or Action.get_current_line_id()
	Action.Runtime.rm(id)
end

Action.pull = function(name)
	Action.Runtime.pull(name)
end

return {
	new = function(runtime)
		Action.Runtime = runtime
		return Action
	end,
}
