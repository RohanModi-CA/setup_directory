--    local function custom_fold(lnum)
--      local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
--    
--      -- Check for custom fold markers
--      if line:match("\\fold") then
--        return ">" 
--      end
--    
--      if line:match("\\endfold") then
--        return "<" 
--      end
--    
--      -- If no custom markers, use indent-based folding 
--      return vim.fn.indent(lnum) > 0 and ">" or "" 
--    end
--    
--    vim.opt.foldexpr = "custom_fold(v:lnum)"
--    vim.opt.foldmethod = "expr"

-- empty setup using defaults
--
-- 



-- nvim-tree wants netrw disabled before it is loaded.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

-- ============================================================
-- Custom folding
--
-- Philosophy:
--
--   Start with foldmethod=indent semantics.
--
--   Then add:
--
--     1. Standalone Allman { is promoted into the indentation
--        fold beneath it.
--
--     2. Pure closing } is promoted into the indentation fold
--        above it.
--
--     3. Multiline /* ... */ creates an additional fold level,
--        INCLUDING both /* and */.
--
--     4. Indentation INSIDE /* ... */ still creates subfolds.
--
--     5. Conventional:
--
--            /*
--             * heading
--             *     subsection
--             */
--
--        uses indentation after the decorative '*'.
--
--     6. \fold ... \endfold is retained as an explicit wrapper.
--
-- IMPORTANT:
--
--   Braces do NOT use >N / <N foldexpr results.
--   Their numeric fold levels are simply adjusted.  This keeps
--   the parent indentation fold continuous.
-- ============================================================


local fold_cache = {}


-- ------------------------------------------------------------
-- Languages in which standalone curly braces should participate
-- in delimiter promotion.
-- ------------------------------------------------------------

local BRACE_FILETYPES = {
  c = true,
  cpp = true,
  objc = true,
  objcpp = true,
  cuda = true,

  java = true,

  javascript = true,
  javascriptreact = true,

  typescript = true,
  typescriptreact = true,

  cs = true,
  go = true,

  php = true,

  css = true,
  scss = true,
  less = true,

  json = true,
  jsonc = true,

  -- Useful for multiline dict/set literals formatted with
  -- standalone braces.
  python = true,
}


-- Rust deliberately omitted here because Rust block comments
-- support nesting, unlike ordinary C/JS block comments.
local BLOCK_COMMENT_FILETYPES = {
  c = true,
  cpp = true,
  objc = true,
  objcpp = true,
  cuda = true,

  java = true,

  javascript = true,
  javascriptreact = true,

  typescript = true,
  typescriptreact = true,

  cs = true,
  go = true,

  php = true,

  css = true,
  scss = true,
  less = true,
}


-- ============================================================
-- Small utilities
-- ============================================================

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end


local function squash_whitespace(s)
  return trim((s:gsub("%s+", " ")))
end


local function get_shiftwidth()
  local sw = vim.bo.shiftwidth

  if sw == 0 then
    sw = vim.bo.tabstop
  end

  if sw == 0 then
    sw = 1
  end

  return sw
end


local function indent_level(lnum, sw)
  return math.floor(vim.fn.indent(lnum) / sw)
end


-- foldmethod=indent ignores blank lines and lines whose first
-- nonblank character occurs in 'foldignore'.
--
-- Returning -1 from foldexpr has the corresponding meaning:
-- use the lower surrounding fold level.
local function is_indent_ignored(line, foldignore)
  if line:match("^%s*$") then
    return true
  end

  if foldignore == nil or foldignore == "" then
    return false
  end

  local first_nonblank = line:match("^%s*(.)")

  if not first_nonblank then
    return true
  end

  return foldignore:find(
    first_nonblank,
    1,
    true
  ) ~= nil
end


-- Count display columns in leading whitespace.
-- Needed for indentation after the decorative '*' inside comments.
local function leading_columns(text, tabstop)
  local col = 0

  for i = 1, #text do
    local c = text:sub(i, i)

    if c == " " then
      col = col + 1

    elseif c == "\t" then
      col = col + (
        tabstop - (col % tabstop)
      )

    else
      break
    end
  end

  return col
end


-- ============================================================
-- Syntax guard
--
-- We only need a modest amount of lexical awareness:
--
--     "{"
--
-- inside a string/comment must not become a brace boundary, and
-- "/*" inside a string must not start a real comment.
--
-- Your Vimscript already has:
--
--     syntax enable
--     syntax sync fromstart
-- ============================================================

local function syntax_kind(lnum, col)
  local ok, syn_id = pcall(
    vim.fn.synID,
    lnum,
    math.max(col, 1),
    1
  )

  if not ok or not syn_id or syn_id == 0 then
    return "unknown"
  end

  local raw =
    vim.fn.synIDattr(syn_id, "name") or ""

  local translated =
    vim.fn.synIDattr(
      vim.fn.synIDtrans(syn_id),
      "name"
    ) or ""

  local name =
    (raw .. " " .. translated):lower()

  if name:find("comment", 1, true) then
    return "comment"
  end

  if name:find("string", 1, true)
      or name:find("character", 1, true)
      or name:find("regexp", 1, true)
      or name:find("regex", 1, true) then
    return "string"
  end

  return "code"
end


-- ============================================================
-- /* ... */ detection
-- ============================================================

local function find_real_comment_start(line, lnum, from_col)
  local pos =
    line:find("/*", from_col or 1, true)

  while pos do
    local kind =
      syntax_kind(lnum, pos)

    -- A real /* may itself be highlighted as Comment, which is
    -- fine.  We only reject things known to be string/regexp text.
    if kind ~= "string" then
      return pos
    end

    pos =
      line:find("/*", pos + 2, true)
  end

  return nil
end


local function find_block_comments(lines, filetype)
  local spans = {}
  local comment_mask = {}

  if not BLOCK_COMMENT_FILETYPES[filetype] then
    return spans, comment_mask
  end

  local open = nil

  for lnum, line in ipairs(lines) do

    if open then
      comment_mask[lnum] = true

      local close_col =
        line:find("*/", 1, true)

      if close_col then
        open.finish = lnum
        open.close_col = close_col

        -- We only promote the entire closing physical line if
        -- nothing except whitespace follows */.
        open.close_standalone =
          line:sub(close_col + 2)
              :match("^%s*$") ~= nil

        spans[#spans + 1] = open
        open = nil
      end

    else
      local start_col =
        find_real_comment_start(
          line,
          lnum,
          1
        )

      if start_col then
        local close_same_line =
          line:find(
            "*/",
            start_col + 2,
            true
          )

        -- /* hello */ does not need a vertical fold.
        if not close_same_line then
          open = {
            start = lnum,
            start_col = start_col,

            -- We can safely hide the whole opening physical line
            -- only if nothing precedes /* except whitespace.
            start_standalone =
              line:sub(1, start_col - 1)
                  :match("^%s*$") ~= nil,
          }

          comment_mask[lnum] = true
        end
      end
    end
  end

  return spans, comment_mask
end


-- ============================================================
-- Brace helpers
-- ============================================================

-- A closer is allowed to contain only closing delimiter
-- punctuation.
--
-- Examples accepted:
--
--     }
--     };
--     },
--     });
--     }};
--
-- Examples rejected:
--
--     } else {
--     } catch (...) {
--
local function pure_brace_closer(text)
  local compact =
    text:gsub("%s+", "")

  if compact:sub(1, 1) ~= "}" then
    return false, 0
  end

  local brace_count = 0

  for i = 1, #compact do
    local c = compact:sub(i, i)

    if c == "}" then
      brace_count = brace_count + 1

    elseif c ~= ")"
        and c ~= "]"
        and c ~= ";"
        and c ~= "," then
      return false, 0
    end
  end

  return brace_count > 0, brace_count
end


-- ============================================================
-- Comment indentation
-- ============================================================

local function comment_uses_star_style(lines, span)
  local meaningful = 0
  local starred = 0

  for lnum = span.start + 1, span.finish - 1 do
    local line = lines[lnum]

    if not line:match("^%s*$") then
      meaningful = meaningful + 1

      if line:match("^%s*%*") then
        starred = starred + 1
      end
    end
  end

  return meaningful > 0
    and meaningful == starred
end


-- Find a meaningful surrounding indentation level while skipping
-- the lines belonging to this block comment.
local function surrounding_level(
  levels,
  comment_mask,
  start_lnum,
  direction,
  line_count
)
  local lnum =
    start_lnum + direction

  while lnum >= 1 and lnum <= line_count do
    if not comment_mask[lnum] then
      local level = levels[lnum]

      if level ~= nil and level >= 0 then
        return level
      end
    end

    lnum = lnum + direction
  end

  return nil
end


-- ============================================================
-- Comment preview helpers
-- ============================================================

local function comment_text_piece(lines, span, lnum)
  local line =
    lines[lnum] or ""

  -- Opening physical line.
  if lnum == span.start then
    local p =
      line:find("/*", 1, true)

    if not p then
      return ""
    end

    local opener_length =
      line:sub(p, p + 2) == "/**"
      and 3
      or 2

    return squash_whitespace(
      line:sub(p + opener_length)
    )
  end


  -- Remove */ from the closing physical line before extracting
  -- text.
  if lnum == span.finish then
    local p =
      line:find("*/", 1, true)

    if p then
      line =
        line:sub(1, p - 1)
    end
  end


  line = trim(line)

  -- Remove decorative leading '*' from conventional comments.
  if line:sub(1, 1) == "*" then
    line =
      line:sub(2)

    if line:sub(1, 1) == " " then
      line =
        line:sub(2)
    end
  end

  return squash_whitespace(line)
end


local function prepare_comment_preview(lines, span)
  local opening_line =
    lines[span.start] or ""

  local p =
    opening_line:find("/*", 1, true)

  if p
      and opening_line:sub(p, p + 2) == "/**" then
    span.opener = "/**"
  else
    span.opener = "/*"
  end


  local first_text = nil
  local has_more = false

  for lnum = span.start, span.finish do
    local piece =
      comment_text_piece(
        lines,
        span,
        lnum
      )

    if piece ~= "" then
      if not first_text then
        first_text = piece
      else
        has_more = true
        break
      end
    end
  end


  if not first_text then
    span.preview =
      span.opener .. " */"

  elseif has_more then
    span.preview =
      span.opener
      .. " "
      .. first_text
      .. " ... */"

  else
    span.preview =
      span.opener
      .. " "
      .. first_text
      .. " */"
  end
end


-- ============================================================
-- Build all effective numeric fold levels
-- ============================================================

local function build_fold_cache()
  local bufnr =
    vim.api.nvim_get_current_buf()

  local winid =
    vim.api.nvim_get_current_win()

  local cache_key =
    tostring(bufnr)
    .. ":"
    .. tostring(winid)

  local tick =
    vim.b.changedtick

  local sw =
    get_shiftwidth()

  local tabstop =
    vim.bo.tabstop

  local foldignore =
    vim.wo.foldignore or "#"

  local filetype =
    vim.bo.filetype or ""

  local syntax =
    vim.bo.syntax or ""


  local old =
    fold_cache[cache_key]

  if old
      and old.tick == tick
      and old.sw == sw
      and old.tabstop == tabstop
      and old.foldignore == foldignore
      and old.filetype == filetype
      and old.syntax == syntax then
    return old
  end


  local lines =
    vim.api.nvim_buf_get_lines(
      bufnr,
      0,
      -1,
      false
    )

  local line_count =
    #lines

  local levels = {}
  local physical_indents = {}


  -- ----------------------------------------------------------
  -- PASS 1
  --
  -- Native foldmethod=indent foundation.
  --
  -- Nothing structural happens here.
  -- ----------------------------------------------------------

  for lnum, line in ipairs(lines) do
    physical_indents[lnum] =
      vim.fn.indent(lnum)

    if is_indent_ignored(
        line,
        foldignore
      ) then

      levels[lnum] = -1

    else
      levels[lnum] =
        math.floor(
          physical_indents[lnum] / sw
        )
    end
  end


  -- ----------------------------------------------------------
  -- PASS 2
  --
  -- Locate block comments before touching braces, because braces
  -- appearing inside /* ... */ are comment contents.
  -- ----------------------------------------------------------

  local comment_spans, comment_mask =
    find_block_comments(
      lines,
      filetype
    )


  local brace_open = {}
  local brace_close = {}


  -- ----------------------------------------------------------
  -- PASS 3
  --
  -- Brace promotion.
  --
  -- NUMERIC LEVELS ONLY.
  --
  -- This is the important correction.
  -- ----------------------------------------------------------

  if BRACE_FILETYPES[filetype] then

    for lnum, line in ipairs(lines) do

      if not comment_mask[lnum] then
        local stripped =
          trim(line)

        local first_col =
          line:find("%S") or 1

        local kind =
          syntax_kind(
            lnum,
            first_col
          )


        if kind ~= "comment"
            and kind ~= "string" then

          -- ----------------------------------------------
          -- Allman opener
          --
          --     if (...)
          --     {
          --         body
          --     }
          --
          -- Physical indentation of { is the parent's.
          -- Promote it one level so it joins BODY.
          -- ----------------------------------------------

          if stripped == "{" then
            local physical_level =
              math.floor(
                physical_indents[lnum] / sw
              )

            levels[lnum] =
              physical_level + 1

            brace_open[lnum] = true


          -- ----------------------------------------------
          -- Closing brace
          --
          --     }
          --
          -- Promote it into the fold it closes.
          --
          -- For:
          --
          --     }};
          --
          -- two closing braces can logically occupy two
          -- enclosing levels.
          -- ----------------------------------------------

          else
            local is_closer, brace_count =
              pure_brace_closer(
                stripped
              )

            if is_closer then
              local physical_level =
                math.floor(
                  physical_indents[lnum] / sw
                )

              levels[lnum] =
                physical_level
                + brace_count

              brace_close[lnum] =
                stripped
            end
          end
        end
      end
    end
  end


  local comment_start = {}
  local comment_owner = {}


  -- ----------------------------------------------------------
  -- PASS 4
  --
  -- Block comments.
  --
  -- A comment creates an OUTER child fold, but indentation inside
  -- the comment remains active.
  --
  -- Example inside a level-1 function:
  --
  --   effective
  --
  --   1    ordinary code
  --   2    /*
  --   2    heading
  --   3        nested
  --   2    */
  --   1    ordinary code
  --
  -- Notice that level 1 remains present implicitly throughout
  -- every level-2 and level-3 line.  Therefore the parent function
  -- fold is never split.
  -- ----------------------------------------------------------

  for _, span in ipairs(comment_spans) do

    -- If either delimiter shares a physical line with unrelated
    -- code, do not hide that entire line inside a promoted comment
    -- fold.
    if span.start_standalone
        and span.close_standalone then

      local before =
        surrounding_level(
          levels,
          comment_mask,
          span.start,
          -1,
          line_count
        )

      local after =
        surrounding_level(
          levels,
          comment_mask,
          span.finish,
          1,
          line_count
        )


      -- Ambient level = surrounding parent.
      --
      -- The lower side wins, matching the conservative behaviour
      -- wanted around dedents.
      local ambient

      if before ~= nil and after ~= nil then
        ambient =
          math.min(before, after)

      elseif before ~= nil then
        ambient = before

      elseif after ~= nil then
        ambient = after

      else
        ambient = 0
      end


      local outer_level =
        ambient + 1

      span.outer_level =
        outer_level

      span.star_style =
        comment_uses_star_style(
          lines,
          span
        )


      -- Both delimiters are part of the OUTER comment fold.
      levels[span.start] =
        outer_level

      levels[span.finish] =
        outer_level

      comment_start[span.start] =
        span


      for lnum = span.start, span.finish do
        comment_owner[lnum] =
          span
      end


      if span.star_style then

        -- ----------------------------------------------
        -- Conventional:
        --
        --     /*
        --      * Heading
        --      *     subsection
        --      *         detail
        --      */
        --
        -- Ignore the indentation before '*', and one normal
        -- formatting space after '*'.
        -- ----------------------------------------------

        for lnum = span.start + 1, span.finish - 1 do
          local line =
            lines[lnum]

          if line:match("^%s*$") then
            levels[lnum] = -1

          else
            local rest =
              line:match("^%s*%*(.*)$")

            if rest == nil then
              rest = ""
            end

            if rest:sub(1, 1) == " " then
              rest =
                rest:sub(2)
            end


            if rest:match("^%s*$") then
              levels[lnum] = -1

            else
              local relative_columns =
                leading_columns(
                  rest,
                  tabstop
                )

              levels[lnum] =
                outer_level
                + math.floor(
                    relative_columns / sw
                  )
            end
          end
        end


      else

        -- ----------------------------------------------
        -- Plain comment:
        --
        --     /*
        --     heading
        --         subsection
        --             detail
        --     */
        --
        -- Find the least-indented meaningful interior line.
        -- That is the comment's relative indentation baseline.
        -- ----------------------------------------------

        local baseline = nil

        for lnum = span.start + 1, span.finish - 1 do
          local line =
            lines[lnum]

          if not line:match("^%s*$") then
            local ind =
              physical_indents[lnum]

            if baseline == nil
                or ind < baseline then
              baseline = ind
            end
          end
        end


        if baseline == nil then
          baseline =
            physical_indents[span.start]
        end


        for lnum = span.start + 1, span.finish - 1 do
          local line =
            lines[lnum]

          if is_indent_ignored(
              line,
              foldignore
            ) then

            levels[lnum] = -1

          else
            local relative_columns =
              math.max(
                0,
                physical_indents[lnum]
                  - baseline
              )

            levels[lnum] =
              outer_level
              + math.floor(
                  relative_columns / sw
                )
          end
        end
      end


      prepare_comment_preview(
        lines,
        span
      )
    end
  end


  -- ----------------------------------------------------------
  -- PASS 5
  --
  -- Your explicit:
  --
  --     \fold
  --         ...
  --     \endfold
  --
  -- It gets one additional numeric wrapper level.
  --
  -- Again: no >N / <N results.
  -- ----------------------------------------------------------

  local marker_start = {}
  local marker_owner = {}

  local marker_stack = {}


  for lnum, line in ipairs(lines) do

    local is_end =
      line:find(
        "\\endfold",
        1,
        true
      ) ~= nil

    local is_start =
      not is_end
      and line:find(
        "\\fold",
        1,
        true
      ) ~= nil


    if is_start then

      local base =
        levels[lnum]

      if base == nil or base < 0 then
        base =
          indent_level(lnum, sw)
      end

      local parent_marker_level = 0

      if #marker_stack > 0 then
        parent_marker_level =
          marker_stack[#marker_stack].level
      end

      local wrapper_level =
        math.max(
          base + 1,
          parent_marker_level + 1
        )

      local marker = {
        start = lnum,
        level = wrapper_level,
      }

      marker_stack[#marker_stack + 1] =
        marker

      levels[lnum] =
        wrapper_level

      marker_start[lnum] =
        marker

      marker_owner[lnum] =
        marker


    elseif is_end
        and #marker_stack > 0 then

      local marker =
        marker_stack[#marker_stack]

      marker.finish =
        lnum

      levels[lnum] =
        math.max(
          marker.level,
          levels[lnum] >= 0
              and levels[lnum]
              or 0
        )

      marker_owner[lnum] =
        marker

      table.remove(
        marker_stack
      )


    elseif #marker_stack > 0 then

      local marker =
        marker_stack[#marker_stack]

      marker_owner[lnum] =
        marker

      if levels[lnum] >= 0 then
        levels[lnum] =
          math.max(
            marker.level,
            levels[lnum] + #marker_stack
          )
      end
    end
  end


  -- ----------------------------------------------------------
  -- foldexpr results
  --
  -- IMPORTANT:
  --
  -- Every structural line returns only:
  --
  --     0, 1, 2, 3, ...
  --
  -- or -1 for indent-style ignored lines.
  --
  -- No >N.
  -- No <N.
  --
  -- This is what prevents delimiter regions from chopping a
  -- parent indentation fold into sibling fragments.
  -- ----------------------------------------------------------

  local results = {}

  for lnum = 1, line_count do
    results[lnum] =
      levels[lnum] or 0
  end


  local cache = {
    tick = tick,
    sw = sw,
    tabstop = tabstop,
    foldignore = foldignore,
    filetype = filetype,
    syntax = syntax,

    lines = lines,
    levels = levels,
    results = results,

    brace_open = brace_open,
    brace_close = brace_close,

    comment_start = comment_start,
    comment_owner = comment_owner,

    marker_start = marker_start,
    marker_owner = marker_owner,
  }

  fold_cache[cache_key] =
    cache

  return cache
end


-- ============================================================
-- foldexpr entry point
-- ============================================================

function _G.CustomFold()
  local cache =
    build_fold_cache()

  return cache.results[vim.v.lnum]
      or 0
end


-- ============================================================
-- Fold previews
-- ============================================================

local function ordinary_preview(cache, first, last)
  for lnum = first, last do
    local line =
      cache.lines[lnum] or ""

    if not line:match("^%s*$") then

      local owner =
        cache.comment_owner[lnum]

      local text

      if owner then
        text =
          comment_text_piece(
            cache.lines,
            owner,
            lnum
          )

      else
        text =
          squash_whitespace(line)
      end


      if text ~= "" then
        return text, lnum
      end
    end
  end

  return "", first
end


local function brace_preview(cache, first, last)
  local first_content = nil
  local consumed_until =
    first

  for lnum = first + 1, last do

    local line =
      cache.lines[lnum] or ""

    local stripped =
      trim(line)

    if stripped ~= ""
        and not cache.brace_close[lnum] then

      local comment =
        cache.comment_start[lnum]


      -- If the first thing in the block is a block comment, use
      -- the useful comment summary instead of merely "/*".
      if comment
          and comment.finish
          and comment.finish <= last then

        first_content =
          comment.preview

        consumed_until =
          comment.finish


      elseif cache.brace_open[lnum] then

        first_content =
          "{ ... }"

        consumed_until =
          lnum


      else

        local owner =
          cache.comment_owner[lnum]

        if owner then
          first_content =
            comment_text_piece(
              cache.lines,
              owner,
              lnum
            )

        else
          first_content =
            squash_whitespace(line)
        end

        consumed_until =
          lnum
      end


      if first_content ~= "" then
        break
      end
    end
  end


  local has_more = false

  for lnum = consumed_until + 1, last do
    local line =
      cache.lines[lnum] or ""

    if trim(line) ~= ""
        and not cache.brace_close[lnum] then
      has_more = true
      break
    end
  end


  local closer = nil

  for lnum = last, first, -1 do
    if cache.brace_close[lnum] then
      closer =
        cache.brace_close[lnum]
      break
    end
  end


  if not first_content
      or first_content == "" then

    if closer then
      return "{ " .. closer
    end

    return "{ ... }"
  end


  local result =
    "{ " .. first_content

  if has_more then
    result =
      result .. " ..."
  end

  if closer then
    result =
      result
      .. " "
      .. closer
  else
    result =
      result .. " }"
  end

  return result
end


local function marker_preview(cache, first, last)
  local first_line =
    cache.lines[first] or ""

  local marker_pos =
    first_line:find(
      "\\fold",
      1,
      true
    )

  if marker_pos then
    local label =
      squash_whitespace(
        first_line:sub(
          marker_pos + 5
        )
      )

    if label ~= "" then
      return "\\fold "
        .. label
        .. " ... \\endfold"
    end
  end


  local text =
    ordinary_preview(
      cache,
      first + 1,
      last
    )

  if text ~= "" then
    return "\\fold "
      .. text
      .. " ... \\endfold"
  end

  return "\\fold ... \\endfold"
end


-- ============================================================
-- foldtext entry point
-- ============================================================

function _G.CustomFoldText()
  local cache =
    build_fold_cache()

  local first =
    vim.v.foldstart

  local last =
    vim.v.foldend

  local count =
    last - first + 1

  local preview


  -- ----------------------------------------------------------
  -- Outermost /* ... */ fold
  -- ----------------------------------------------------------

  local comment =
    cache.comment_start[first]

  if comment
      and comment.finish
      and comment.finish <= last then

    preview =
      comment.preview


  -- ----------------------------------------------------------
  -- Fold beginning on promoted Allman {
  -- ----------------------------------------------------------

  elseif cache.brace_open[first] then

    preview =
      brace_preview(
        cache,
        first,
        last
      )


  -- ----------------------------------------------------------
  -- Explicit \fold
  -- ----------------------------------------------------------

  elseif cache.marker_start[first] then

    preview =
      marker_preview(
        cache,
        first,
        last
      )


  -- ----------------------------------------------------------
  -- Ordinary indentation fold
  --
  -- This includes indentation subfolds inside comments.
  -- ----------------------------------------------------------

  else

    preview =
      ordinary_preview(
        cache,
        first,
        last
      )


    -- For a K&R-style body, the opening brace remains on the
    -- visible header:
    --
    --     if (...) {
    --         hidden body
    --     }
    --
    -- If the pure closing brace has been promoted into this fold,
    -- show it in the summary instead of making it visually vanish.
    local closer =
      cache.brace_close[last]

    if closer
        and preview ~= "" then
      preview =
        preview
        .. " ... "
        .. closer
    end
  end


  if not preview
      or preview == "" then
    preview = "..."
  end


  local noun =
    count == 1
    and "line"
    or "lines"

  local dashes =
    vim.v.folddashes or "--"


  return "+"
    .. dashes
    .. " "
    .. tostring(count)
    .. " "
    .. noun
    .. ": "
    .. preview
end


-- ============================================================
-- Activate
--
-- Your Neovim version requires expression options to contain
-- strings, hence the v:lua bridge.
-- ============================================================

vim.opt.foldmethod =
  "expr"

vim.opt.foldexpr =
  "v:lua.CustomFold()"

vim.opt.foldtext =
  "v:lua.CustomFoldText()"
