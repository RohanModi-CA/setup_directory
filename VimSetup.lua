local function custom_fold(lnum)
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]

  -- Check for custom fold markers
  if line:match("\\fold") then
    return ">" 
  end

  if line:match("\\endfold") then
    return "<" 
  end

  -- If no custom markers, use indent-based folding 
  return vim.fn.indent(lnum) > 0 and ">" or "" 
end

vim.opt.foldexpr = "custom_fold(v:lnum)"
vim.opt.foldmethod = "expr"




-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- add lualine
require('lualine').setup()
