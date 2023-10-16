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
    list_item = true,
    minus_metadata = true,
}

---@param pos Position
---@return boolean isSuit true if the position should be substituted
local function suit(pos)
    local res = true

    local node = ts.get_parser(0, "markdown_inline"):named_node_for_range({ pos.row, pos.col, pos.row, pos.col })
    if not node then
        return false
    end
    local min_node = node:descendant_for_range(pos.row, pos.col, pos.row, pos.col)
    while min_node do
        if ignore[min_node:type()] then
            res = false
            break
        end
        min_node = min_node:parent()
    end

    node = ts.get_node({ pos = { pos.row, pos.col - 1 } })
    if not node then
        return false
    end
    while node do
        if ignore[node:type()] then
            res = false
            break
        end
        node = node:parent()
    end

    return res
end

---@param startPos Position
---@return Position | nil pos
local function findPunctuationPosition(startPos)
    local bufnr = api.nvim_get_current_buf()
    local lines = api.nvim_buf_get_lines(bufnr, startPos.row, -1, false)

    for i, line in ipairs(lines) do
        local initPos = i == 0 and startPos.col + 1 or 0
        local col = line:find("()[.,]", initPos)
        if col then
            local pos = { row = startPos.row + i - 1, col = col - 1 }
            if suit(pos) then
                return pos
            end
        end
    end

    return nil
end

-- substitute half-width punctuation to full-width for all lines
local function substituteHalf()
    ---@param startPos Position
    local function inner(startPos)
        local pos = findPunctuationPosition(startPos)
        if not pos then
            return
        end

        local bufnr = api.nvim_get_current_buf()
        local line = api.nvim_buf_get_lines(bufnr, pos.row, pos.row + 1, false)[1]
        local char = line:sub(pos.col + 1, pos.col + 1)
        local fullChar = half2fullMap[char]
        if not fullChar then
            return
        end

        api.nvim_buf_set_text(bufnr, pos.row, pos.col, pos.row, pos.col + 1, { fullChar })

        inner({ row = pos.row, col = pos.col + 2 })
    end

    inner({ row = 0, col = 0 })
end

M.setup = function()
    api.nvim_create_user_command("SubstituteHalf", substituteHalf, {})
end

return M
