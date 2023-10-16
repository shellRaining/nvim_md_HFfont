local M = {}

---@class Position
---@field row number
---@field col number

local api = vim.api
local ts = vim.treesitter

-- a map to convert half-width punctuation to kanji punctuation
local half2fullMap = {
    [","] = "，",
    ["."] = "。",
}

local ignore = {
    html_block = true,
    code_block = true,
    fenced_code_block = true,
    atx_heading = true,
    list_marker_dot = true,
    inline_link = true,
    link_destination = true,
    code_span = true,
    minus_metadata = true,
}

---@param pos Position
---@return boolean isSuit true if the position should be substituted
local function suit(pos)
    local tree = ts.get_parser(0, "markdown_inline")
    local node = tree:named_node_for_range({ pos.row, pos.col, pos.row, pos.col })
    if not node then
        return false
    end
    local min_node = node:descendant_for_range(pos.row, pos.col, pos.row, pos.col)
    -- vim.notify(ts.get_node_text(min_node, 0))
    -- vim.notify(vim.inspect(pos))
    while min_node do
        -- vim.notify(min_node:type())
        if ignore[min_node:type()] then
            return false
        end
        min_node = min_node:parent()
    end

    node = ts.get_node({ pos = { pos.row, pos.col } })
    if not node then
        return false
    end
    while node do
        -- vim.notify(node:type())
        if ignore[node:type()] then
            return false
        end
        node = node:parent()
    end
    return true
end

-- substitute half-width punctuation to full-width for all lines
local function substituteHalf()
    ---@param startPos Position
    local function inner(startPos)
        -- check the startPos
        if startPos.row < 0 or startPos.row >= api.nvim_buf_line_count(0) then
            return
        end
        local line = api.nvim_buf_get_lines(0, startPos.row, startPos.row + 1, false)[1]
        if startPos.col < 0 or startPos.col >= #line then
            inner({ row = startPos.row + 1, col = 0 })
        end

        -- move to start position and search (while jumping to the searched position)
        api.nvim_win_set_cursor(0, { startPos.row + 1, startPos.col })
        local res = vim.fn.search("[.,]", "czW")
        if res == 0 then
            return
        end
        local p = api.nvim_win_get_cursor(0)
        local pos = { row = p[1] - 1, col = vim.fn.col(".") - 1 }

        if suit(pos) then
            local bufnr = api.nvim_get_current_buf()
            line = api.nvim_buf_get_lines(bufnr, pos.row, pos.row + 1, false)[1]
            local char = line:sub(pos.col + 1, pos.col + 1)
            local fullChar = half2fullMap[char]
            if not fullChar then
                return
            end

            api.nvim_buf_set_text(bufnr, pos.row, pos.col, pos.row, pos.col + 1, { fullChar })
        end

        inner({ row = pos.row, col = pos.col + 1 })
    end

    local oldPos = api.nvim_win_get_cursor(0)
    inner({ row = 0, col = 0 })
    api.nvim_win_set_cursor(0, oldPos)
end

M.setup = function()
    api.nvim_create_user_command("SubstituteHalf", substituteHalf, {})
end

return M
