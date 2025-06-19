if not vim.g.stevedore_runtime then
	if vim.fn.executable("docker") == 1 then
		vim.g.stevedore_runtime = "stevedore.runtime.docker"
	end
	if vim.fn.executable("podman") == 1 then
		vim.g.stevedore_runtime = "stevedore.runtime.podman"
	end
end

vim.api.nvim_create_autocmd("BufReadCmd", {
	pattern = { "stevedore://*" },
	callback = function(args)
		require("stevedore").BufReadCmd()
	end,
	nested = true,
})

vim.api.nvim_create_autocmd("BufWriteCmd", {
	pattern = { "stevedore://*" },
	callback = function(args)
		require("stevedore").BufWriteCmd(vim.v.cmdbang == 1)
	end,
	nested = true,
})

-- vim.api.nvim_create_autocmd("FileReadCmd", {
-- 	pattern = { "stevedore://*" },
-- 	callback = function(args)
-- 		vim.print(args)
-- 	end,
-- })
-- vim.api.nvim_create_autocmd("FileWriteCmd", {
-- 	pattern = { "stevedore://*" },
-- 	callback = function(args)
-- 		vim.print(args)
-- 	end,
-- })

vim.api.nvim_create_user_command("Stevedore", "exe '<mods> split stevedore:///'", { desc = "list all images" })
