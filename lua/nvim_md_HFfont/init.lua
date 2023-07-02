local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.setup = function()
    vim.notify('hello')
    vim.api.nvim_create_augroup("HFfont_augroup", { clear = true })
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = "HFfont_augroup",
        pattern = "*",
        callback = function()
            local node = ts_utils.get_node_at_cursor()
            vim.notify(node:type())
        end,
    })
end

return M
