local M = {}

local api = vim.api

-- 查询文本中所有半角标点的位置
local function findPunctuationPositions()
    local bufnr = api.nvim_get_current_buf()
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local positions = {}

    for i, line in ipairs(lines) do
        local linePositions = {}
        for position in line:gmatch("()[.,]") do
            table.insert(linePositions, position)
        end
        if #linePositions > 0 then
            positions[i] = linePositions
        end
    end

    return positions
end

local inCodeBlock = function(node)
    local parent = node:parent()

    while parent do
        if parent:type() == "fenced_code_block" then
            return true
        end
        parent = parent:parent()
    end

    return false
end

M.setup = function()
    api.nvim_create_user_command("SubstituteHalf", function()
        local punctuationPositions = findPunctuationPositions()
        if #punctuationPositions == 0 then
            print("No half font found.")
            return
        end

        -- get the treesitter node from position
        local cur_buf = api.nvim_get_current_buf()
        for i, linePositions in pairs(punctuationPositions) do
            for _, col in pairs(linePositions) do
                local node = vim.treesitter.get_node({
                    bufnr = cur_buf,
                    pos = { i - 1, col - 1 },
                })

                if node and not inCodeBlock(node) then
                    -- get the char in the position
                    local char = api.nvim_buf_get_lines(cur_buf, i - 1, i, false)[1]:sub(col, col)
                    if char == "." then
                        api.nvim_buf_set_text(cur_buf, i - 1, col - 1, i - 1, col, { "。" })
                    elseif char == "," then
                        api.nvim_buf_set_text(cur_buf, i - 1, col - 1, i - 1, col, { "，" })
                    end
                end
            end
        end
    end, {})
end

return M
