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
    local ignoreType = {
        "html_block",
        "code_block",
        "fenced_code_block",
        "atx_heading",
        "atx_h1_marker",
        "atx_h2_marker",
        "atx_h3_marker",
        "atx_h4_marker",
        "atx_h5_marker",
        "atx_h6_marker",
        "list_marker_dot",
        "link_reference_definition",
        "link_title",
        "link_label",
        "link_destination",
    }
    while node do
        if vim.tbl_contains(ignoreType, node:type()) then
            return true
        end
        node = node:parent()
    end

    return false
end

local function execute()
    local punctuationPositions = findPunctuationPositions()
    -- note the key is number, so can not use # to get len
    local count = 0
    for _ in pairs(punctuationPositions) do
        count = count + 1
    end
    if count == 0 then
        return
    end

    -- get the treesitter node from position
    local cur_buf = api.nvim_get_current_buf()
    for row, linePositions in pairs(punctuationPositions) do
        for _, col in pairs(linePositions) do
            local node = vim.treesitter.get_node({
                bufnr = cur_buf,
                pos = { row - 1, col - 1 },
            })

            if node and not inCodeBlock(node) then
                -- get the char in the position
                local char = api.nvim_buf_get_lines(cur_buf, row - 1, row, false)[1]:sub(col, col)
                if char == "." then
                    api.nvim_buf_set_text(cur_buf, row - 1, col - 1, row - 1, col, { "。" })
                elseif char == "," then
                    api.nvim_buf_set_text(cur_buf, row - 1, col - 1, row - 1, col, { "，" })
                end
                execute()
            end
        end
    end
end

M.setup = function()
    api.nvim_create_user_command("SubstituteHalf", execute, {})
    -- api.nvim_create_autocmd("CursorMoved", {
    --     pattern = "*.md",
    --     callback = function()
    --         local node = vim.treesitter.get_node()
    --         local node_type = node:type()
    --         vim.notify(node_type)
    --     end,
    -- })
end

return M
