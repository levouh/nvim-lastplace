local lastplace = {}

local function create_augroup()
  local group_name = "__lastplace"

  vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", { callback = lastplace.lastplace_buf, group = group_name })
  vim.api.nvim_create_autocmd("FileType", { callback = lastplace.lastplace_buf, group = group_name })
end

local set_cursor_position = function(_)
  local last_line = vim.fn.line([['"]])
  local buff_last_line = vim.fn.line("$")
  local window_last_line = vim.fn.line("w$")
  local window_first_line = vim.fn.line("w0")

  -- If the last line is set and the less than the last line in the buffer
  if last_line > 0 and last_line <= buff_last_line then
    -- Check if the last line of the buffer is the same as the window
    if window_last_line == buff_last_line then
      -- Set line to last line edited
      vim.api.nvim_command([[normal! g`"]])
      -- Try to center
    elseif buff_last_line - last_line > ((window_last_line - window_first_line) / 2) - 1 then
      vim.api.nvim_command([[normal! g`"zz]])
    else
      vim.api.nvim_command([[normal! G'"<c-e>]])
    end
  end

  if vim.fn.foldclosed(".") ~= -1 and lastplace.options.open_folds then
    vim.api.nvim_command([[normal! zvzz]])
  end
end

local function should_set_cursor(buf)
  local varname = "__lastplace_done"
  local ok, done = pcall(vim.api.nvim_buf_get_var, buf, varname)
  if ok and done then
    return false
  end

  vim.api.nvim_buf_set_var(buf, varname, true)

  return true
end

function lastplace.setup(options)
  local defaults = {
    ignore_buftype = { "quickfix", "nofile", "help", "terminal" },
    ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
    open_folds = true,
  }

  lastplace.options = vim.tbl_extend("force", defaults, options or {})

  create_augroup()
end

function lastplace.lastplace_buf(args)
  if not should_set_cursor(args.buf) then
    return
  end

  -- Check if the buffer should be ignored
  if vim.tbl_contains(lastplace.options.ignore_buftype, vim.api.nvim_buf_get_option(0, "buftype")) then
    return
  end

  -- Check if the filetype should be ignored
  if vim.tbl_contains(lastplace.options.ignore_filetype, vim.api.nvim_buf_get_option(0, "filetype")) then
    -- reset cursor to first line
    vim.api.nvim_command([[normal! gg]])
    return
  end

  -- If a line has already been specified on the command line, we are done
  if vim.fn.line(".") > 1 then
    return
  end

  set_cursor_position(args.buf)
end

function lastplace.lastplace_ft(args)
  if not should_set_cursor(args.buf) then
    return
  end

  -- Check if the buffer should be ignored
  if vim.tbl_contains(lastplace.options.ignore_buftype, vim.api.nvim_buf_get_option(0, "buftype")) then
    return
  end

  -- Check if the filetype should be ignored
  if vim.tbl_contains(lastplace.options.ignore_filetype, vim.api.nvim_buf_get_option(0, "filetype")) then
    -- reset cursor to first line
    vim.api.nvim_command([[normal! gg]])
    return
  end

  -- If a line has already been set by the BufReadPost event or on the command
  -- line, we are done.
  if vim.fn.line(".") > 1 then
    return
  end

  -- This shouldn't be reached but, better have it
  set_cursor_position(args.buf)
end

return lastplace
