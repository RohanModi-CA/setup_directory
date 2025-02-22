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

