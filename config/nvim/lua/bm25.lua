-- BM25 code search (SQLite FTS5) with a Telescope picker.
-- Indexing/searching is done by scripts/bm25.py.

local M = {}

local function project_root()
  local bufname = vim.api.nvim_buf_get_name(0)
  local start = bufname ~= "" and vim.fn.fnamemodify(bufname, ":h") or vim.fn.getcwd()
  local root = vim.fs.root(start, { ".git" })
  return root or vim.fn.getcwd()
end

local function db_path(root)
  local hash = vim.fn.sha256(root):sub(1, 16)
  local dir = vim.fn.stdpath("cache") .. "/bm25"
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. hash .. ".db"
end

local function script_path()
  return vim.fn.stdpath("config") .. "/scripts/bm25.py"
end

local function open_picker(results, root)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "BM25 code search (" .. #results .. ")",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%4d  %s:%d  %s", entry.idx, entry.path, entry.line, entry.content),
          ordinal = string.format("%04d %s", entry.idx, entry.content),
          path = root .. "/" .. entry.path,
          lnum = entry.line,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.grep_previewer({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then
          vim.cmd("edit " .. vim.fn.fnameescape(sel.path))
          vim.api.nvim_win_set_cursor(0, { sel.lnum, 0 })
          vim.cmd("normal! zz")
        end
      end)
      return true
    end,
  }):find()
end

function M.index()
  local root = project_root()
  local db = db_path(root)
  vim.notify("BM25: indexing " .. root .. " ...")
  vim.system({ "python3", script_path(), "index", root, db }, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        local msg = (res.stdout or ""):gsub("%s+$", "")
        vim.notify("BM25: " .. (msg ~= "" and msg or "index ready"))
      else
        vim.notify("BM25 index failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.search(query)
  local root = project_root()
  local db = db_path(root)

  if vim.fn.filereadable(db) == 0 then
    vim.notify("BM25: no index for this project — run <leader>fi first", vim.log.levels.WARN)
    return
  end

  query = query or vim.fn.input("BM25: ")
  if not query or query == "" then
    return
  end

  local res = vim.system({ "python3", script_path(), "search", db, query }, { text = true }):wait()
  if res.code ~= 0 then
    vim.notify("BM25 search failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
    return
  end

  local results = {}
  for line in (res.stdout or ""):gmatch("[^\n]+") do
    local ok, item = pcall(vim.json.decode, line)
    if ok and item then
      item.idx = #results + 1
      results[#results + 1] = item
    end
  end

  if #results == 0 then
    vim.notify("BM25: no matches for " .. query, vim.log.levels.INFO)
    return
  end

  open_picker(results, root)
end

function M.search_word()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.notify("BM25: no word under cursor", vim.log.levels.WARN)
    return
  end
  M.search(word)
end

return M
