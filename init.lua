-- linux
if vim.loader then
  vim.loader.enable()
end

local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

  if fn.empty(fn.glob(install_path)) > 0 then
    print("🔄 Instalando packer.nvim...")
    fn.system({
      'git',
      'clone',
      '--depth',
      '1',
      'https://github.com/wbthomason/packer.nvim',
      install_path
    })
    vim.cmd('packadd packer.nvim')
    return true
  end

  return false
end

local packer_bootstrap = ensure_packer()

------------------------------------------------------------
-- OPÇÕES BÁSICAS
------------------------------------------------------------
vim.deprecate = function() end
--vim.opt.guicursor = "" -- comando que faz com que seja bloco ao inves de linha
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt_local.laststatus = 0
vim.g.mapleader = " "
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt_local.ruler = false
--vim.opt_local.showmode = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.timeoutlen = 300
vim.opt.updatetime = 50
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 0
--vim.o.statusline = " [FILENAME: %t] %= [TYPE: %Y] [LINE: %l/%L : %c] [%p%%] %{Modified_Get()}"
--vim.o.laststatus = 2
vim.o.shortmess = vim.o.shortmess .. "atI"
vim.o.cmdheight = 1
vim.opt.ruler = false
--vim.opt.cursorline = true
vim.o.laststatus = 1

function _G.StatusName()
    if vim.bo.buftype == "terminal" then return "term" end
    local n = vim.fn.expand("%:t")
    return n ~= "" and n or "No Name"
end

vim.o.statusline = " %{v:lua.StatusName()} %m"

local repo_cache = {}

local function esc(s)
    return (s:gsub("%%", "%%%%"))
end

-- com cache: o tabline redesenha a cada movimento do cursor,
-- então não dá para fazer fs_stat em toda chamada
local function tab_dir(tabnr, buf)
    local cwd = vim.fn.getcwd(-1, tabnr)

    if vim.bo[buf].filetype == "netrw" then
        return vim.b[buf].netrw_curdir or cwd
    end
    if vim.bo[buf].buftype ~= "" then return cwd end

    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" or name:match("^%a[%w+.-]*://") then return cwd end

    return vim.fn.fnamemodify(name, ":p:h")
end

local function get_repo_name(dir)
    if repo_cache[dir] then return repo_cache[dir] end

    local d, name = dir, nil
    while d and d ~= "" do
        if vim.uv.fs_stat(d .. "/.git") then
            name = vim.fn.fnamemodify(d, ":t")
            break
        end
        local parent = vim.fn.fnamemodify(d, ":h")
        if parent == d then break end
        d = parent
    end

    name = name or vim.fn.fnamemodify(dir, ":t")
    repo_cache[dir] = name
    return name
end

local function is_diffview_tab(tabnr)
    local tabid = vim.api.nvim_list_tabpages()[tabnr]
    if not tabid then return false end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
        local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
        if ft:match("^Diffview") then return true end
    end
    return false
end

function _G.NvimTabLine()
    local current = vim.fn.tabpagenr()
    local parts = {}

    for i = 1, vim.fn.tabpagenr("$") do
        local buf = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
        local repo = get_repo_name(tab_dir(i, buf))
        local label

        if is_diffview_tab(i) then
            label = "Diff: " .. repo
        else
            local name
            if vim.bo[buf].buftype == "terminal" then
                name = "[term]"
            else
                name = vim.fn.fnamemodify(vim.fn.bufname(buf), ":t")
                if name == "" then name = "[No Name]" end
            end
            label = repo .. " - " .. name
            if i ~= current and vim.bo[buf].modified then
                label = label .. " +"
            end
        end

        local hl = i == current and "%#TabLineSel#" or "%#TabLine#"
        -- %iT = aba clicável com o mouse
       parts[#parts + 1] = "%" .. i .. "T" .. hl .. " " .. esc(label) .. " "
    end

    -- lado direito
    local ft = vim.bo.filetype
    ft = ft ~= "" and (" [" .. (ft:gsub("^%l", string.upper)) .. "]") or ""

    local ok, head = pcall(vim.fn.FugitiveHead)
    local branch = (ok and head ~= "") and (" git:" .. esc(head)) or ""

    local S = vim.diagnostic.severity
    local d = vim.diagnostic.count(0)
    local diag = ""
    if d[S.ERROR] then diag = diag .. " E" .. d[S.ERROR] end
    if d[S.WARN] then diag = diag .. " W" .. d[S.WARN] end

    local lnum, last = vim.fn.line("."), vim.fn.line("$")
    local info = branch .. diag .. ft
        .. " " .. lnum .. "/" .. last .. ":" .. vim.fn.col(".")
        .. " " .. math.floor(lnum * 100 / last) .. "%%"
        .. (vim.bo.modified and " [+]" or "")
        .. " "

    return table.concat(parts, "%#TabLineFill#|") .. "%#TabLineFill#%T%=" .. info
end

vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.NvimTabLine()"

vim.api.nvim_create_autocmd("DirChanged", {
    callback = function() repo_cache = {} end,
})

vim.api.nvim_create_autocmd({
    "CursorMoved", "CursorMovedI", "ModeChanged",
    "TextChanged", "TextChangedI", "BufModifiedSet", "DiagnosticChanged",
}, {
    callback = function() vim.cmd.redrawtabline() end,
})

--vim.o.winbar = "%#TabSep#%{repeat('─', winwidth(0))}"

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "NvimTree", "dashboard", "qf", "DiffviewFiles", "DiffviewFileHistory", "trouble" },
    callback = function() vim.opt_local.winbar = "" end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"

        vim.opt_local.winbar = "%{get(b:, 'netrw_curdir', '')}"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "NvimTree", "qf", "trouble", "netrw", "undotree", "DiffviewFiles", "DiffviewFileHistory" },
    callback = function() vim.opt_local.statusline = " " end,
})
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.treesitter.stop()
  end,
})

--vim.o.statusline = " [FILENAME: %t] %= [TYPE: %Y] [LINE: %l/%L : %c] [%p%%] %{Modified_Get()}"
vim.o.laststatus = 1
vim.o.shortmess = vim.o.shortmess .. "atI"
vim.o.cmdheight = 1

local function web_search()
    local query = vim.fn.input("Search: ")

    if query == "" then
        return
    end

    -- Codifica a query para URL usando o próprio curl
    local encoded = vim.fn.system({
        "curl",
        "-sG",
        "--data-urlencode",
        "q=" .. query,
        "-o",
        "/dev/null",
        "-w",
        "%{url_effective}",
        "https://html.duckduckgo.com/html/",
    })

    encoded = encoded:gsub("\n$", "")

    -- Buffer
    local buf = vim.api.nvim_create_buf(false, true)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "websearch"

    -- Janela
    local width = math.floor(vim.o.columns * 0.80)
    local height = math.floor(vim.o.lines * 0.70)

    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
        title = " Search: " .. query .. " ",
        title_pos = "center",
    })

    vim.wo[win].cursorline = true
    vim.wo[win].wrap = true

    -- Mensagem inicial
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "",
        "  Searching...",
        "",
    })

    ----------------------------------------------------------
    -- Pesquisa
    ----------------------------------------------------------

    vim.fn.jobstart({
        "curl",
        "-Ls",
        "-A",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/146 Safari/537.36",
        "-e",
        "https://html.duckduckgo.com/",
        "-d",
        "q=" .. query,
        "https://html.duckduckgo.com/html/",
    }, {
        stdout_buffered = true,

        on_stdout = function(_, data)
            if not data or #data == 0 then
                return
            end

            vim.schedule(function()
                local html = table.concat(data, "\n")
                local results = {}

                ------------------------------------------------------
                -- Extrai cada resultado
                ------------------------------------------------------

                for block in html:gmatch(
                    '<a rel="nofollow" class="result__a".-</a>'
                ) do
                    local link = block:match(
                        'href="([^"]+)"'
                    )

                    local title = block:match(
                        '>(.-)</a>'
                    )

                    if link and title then
                        -- Remove tags HTML
                        title = title:gsub("<[^>]+>", "")

                        -- Entidades HTML básicas
                        title = title:gsub("&amp;", "&")
                        title = title:gsub("&quot;", '"')
                        title = title:gsub("&#x27;", "'")
                        title = title:gsub("&lt;", "<")
                        title = title:gsub("&gt;", ">")

                        table.insert(results, {
                            title = vim.trim(title),
                            link = link,
                        })
                    end
                end

                ------------------------------------------------------
                -- Monta resultado
                ------------------------------------------------------

                local lines = {
                    " Results: " .. query,
                    "",
                }

                if #results == 0 then
                    table.insert(lines, " Nenhum resultado encontrado.")
                else
                    for i, result in ipairs(results) do
                        table.insert(
                            lines,
                            string.format(" %d. %s", i, result.title)
                        )

                        table.insert(
                            lines,
                            "    " .. result.link
                        )

                        table.insert(lines, "")
                    end
                end

                vim.bo[buf].modifiable = true

                vim.api.nvim_buf_set_lines(
                    buf,
                    0,
                    -1,
                    false,
                    lines
                )

                vim.bo[buf].modifiable = false
            end)
        end,

        on_stderr = function(_, data)
            if data and #data > 0 then
                vim.schedule(function()
                    vim.notify(
                        "Erro no curl: " .. table.concat(data, " "),
                        vim.log.levels.ERROR
                    )
                end)
            end
        end,
    })

    ----------------------------------------------------------
    -- Fechar
    ----------------------------------------------------------

    vim.keymap.set("n", "q", "<cmd>close<CR>", {
        buffer = buf,
        silent = true,
    })

    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", {
        buffer = buf,
        silent = true,
    })

    ----------------------------------------------------------
    -- Abrir link
    ----------------------------------------------------------

    vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()

        local link = line:match("https?://%S+")

        if link then
            if vim.fn.has("win32") == 1 then
                vim.fn.jobstart({
                    "rundll32",
                    "url.dll,FileProtocolHandler",
                    link,
                }, { detach = true })
            else
                vim.fn.jobstart({
                    "xdg-open",
                    link,
                }, { detach = true })
            end
        end
    end, {
        buffer = buf,
        silent = true,
    })
end

vim.keymap.set("n", "<leader>/", web_search, {
    desc = "Web search",
})

------------------------------------------------------------
-- AUTOPAIRS NATIVO
------------------------------------------------------------
local function setup_autopairs()
  local pairs_map = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
  }

  local function insert_pair(l, r)
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)
    local after = line:sub(col + 1)

    if after:sub(1, 1) == r then
      vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), col + 1 })
    else
      vim.api.nvim_set_current_line(before .. l .. r .. after)
      vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), col + 1 })
    end
  end

  for l, r in pairs(pairs_map) do
    vim.keymap.set('i', l, function()
      insert_pair(l, r)
    end, { noremap = true, silent = true })
  end
end

setup_autopairs()

------------------------------------------------------------
-- COMPILE / RUN
------------------------------------------------------------
local compile_state = {
  bufnr = nil,
  winid = nil,
  last_cmd = nil,
  history = {},
  job_id = nil,
}

local function open_compile_buffer()
  local created = false

  if not (compile_state.bufnr and vim.api.nvim_buf_is_valid(compile_state.bufnr)) then
    local existing = vim.fn.bufnr("^\\*compilation\\*$")
    if existing ~= -1 then
      compile_state.bufnr = existing
    else
      compile_state.bufnr = vim.api.nvim_create_buf(false, true)
      vim.bo[compile_state.bufnr].bufhidden = "hide"
      vim.bo[compile_state.bufnr].buftype = "nofile"
      vim.bo[compile_state.bufnr].filetype = "compilation"
      vim.api.nvim_buf_set_name(compile_state.bufnr, "*compilation*")
      created = true
    end
  end

  local visible_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == compile_state.bufnr then
      visible_win = win
      break
    end
  end

  if visible_win then
    compile_state.winid = visible_win
  else
    local original_win = vim.api.nvim_get_current_win()
    local width = math.floor(vim.o.columns * 0.4)
    vim.cmd("vertical botright " .. width .. "vsplit")
    vim.api.nvim_win_set_buf(0, compile_state.bufnr)
    compile_state.winid = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(original_win)
  end

  if created then
    local opts = { buffer = compile_state.bufnr, silent = true, nowait = true }
    vim.keymap.set("n", "q", function()
      if compile_state.winid and vim.api.nvim_win_is_valid(compile_state.winid) then
        vim.api.nvim_win_close(compile_state.winid, false)
      end
    end, opts)
    vim.keymap.set("n", "g", function()
      if compile_state.last_cmd then run_compile(compile_state.last_cmd) end
    end, opts)
    vim.keymap.set("n", "<C-c><C-k>", function()
      if compile_state.job_id then
        vim.fn.jobstop(compile_state.job_id)
        vim.notify("Compilation interrupted", vim.log.levels.WARN)
      end
    end, opts)
  end

  return compile_state.bufnr
end

local function append_lines(bufnr, lines)
  if not lines or #lines == 0 then return end
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
end

function run_compile(cmd)
  vim.cmd("silent! wa")

  compile_state.last_cmd = cmd
  if compile_state.history[#compile_state.history] ~= cmd then
    table.insert(compile_state.history, cmd)
  end

  local bufnr = open_compile_buffer()
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "$ " .. cmd, "" })

  vim.notify("Compilation started", vim.log.levels.INFO)

  compile_state.job_id = vim.fn.jobstart(cmd, {
    shell = true,
    on_stdout = function(_, data)
      if vim.api.nvim_buf_is_valid(bufnr) then append_lines(bufnr, data) end
    end,
    on_stderr = function(_, data)
      if vim.api.nvim_buf_is_valid(bufnr) then append_lines(bufnr, data) end
    end,
    on_exit = function(_, code)
      compile_state.job_id = nil
      if not vim.api.nvim_buf_is_valid(bufnr) then return end

      local status = (code == 0)
          and "finished"
          or ("exited abnormally with code " .. code)

      append_lines(bufnr, { "", "Compilation " .. status })
      vim.bo[bufnr].modifiable = false

      vim.fn.setqflist({}, ' ', {
        title = cmd,
        lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
        efm = vim.o.errorformat,
      })

      if code ~= 0 then
        vim.notify("Compilation failed (code " .. code .. ")", vim.log.levels.ERROR)
      else
        vim.notify("Compilation succeeded", vim.log.levels.INFO)
      end
    end,
  })
end

local function compile_prompt()
  vim.ui.input({
    prompt = "Compile command: ",
    default = compile_state.last_cmd or "make -k ",
  }, function(cmd)
    if cmd and cmd ~= "" then run_compile(cmd) end
  end)
end

local function recompile()
  if compile_state.last_cmd then
    run_compile(compile_state.last_cmd)
  else
    compile_prompt()
  end
end

vim.api.nvim_create_user_command("Compile", compile_prompt, {})
vim.api.nvim_create_user_command("Recompile", recompile, {})

------------------------------------------------------------
-- DASHBOARD PERSONALIZADO
------------------------------------------------------------
local function setup_dashboard()
    vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("Dashboard", { clear = true }),
        callback = function()
            if vim.fn.argc() > 0 then return end

            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            if #lines > 1 or (#lines == 1 and #lines[1] > 0) then return end

            local buf = vim.api.nvim_create_buf(false, true)
            vim.bo[buf].bufhidden = "wipe"
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].filetype = "dashboard"

            vim.api.nvim_win_set_buf(0, buf)

            local win = 0
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.cursorline = false
            vim.opt_local.cursorcolumn = false
            vim.opt_local.signcolumn = "no"
            vim.opt_local.fillchars = { eob = " " }

            local original_guicursor = vim.o.guicursor
            vim.api.nvim_set_hl(0, "DashboardCursor", { blend = 100, nocombine = true })

            local function hide_cursor()
                vim.opt.guicursor = "a:DashboardCursor"
            end

            local function restore_cursor()
                vim.opt.guicursor = original_guicursor
            end

            hide_cursor()

            vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "VimLeavePre" }, {
                buffer = buf,
                callback = restore_cursor,
            })

            vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
                buffer = buf,
                callback = hide_cursor,
            })

            local logo = {}

            local menu = {
                "[n] New File ",
                "[f] Find File",
                "    [e] File Explorer",
                " [wq] Quit     ",
            }

            local width = vim.api.nvim_win_get_width(win)
            local height = vim.api.nvim_win_get_height(win)

            local function center(text_lines)
                local res = {}
                for _, line in ipairs(text_lines) do
                    local pad = math.floor((width - #line) / 2)
                    table.insert(res, string.rep(" ", pad) .. line)
                end
                return res
            end

            local content = {}
            local total_lines = #logo + #menu + 2
            local top_pad = math.floor((height - total_lines) / 2)

            for _ = 1, top_pad do table.insert(content, "") end
            for _, l in ipairs(center(logo)) do table.insert(content, l) end
            table.insert(content, "")
            table.insert(content, "")
            for _, l in ipairs(center(menu)) do table.insert(content, l) end

            vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
            vim.bo[buf].modifiable = false

            local opts = { buffer = buf, noremap = true, silent = true }

            vim.keymap.set("n", "n", function()
                restore_cursor()
                vim.cmd("enew")
            end, opts)

            vim.keymap.set("n", "e", function()
                restore_cursor()
                vim.cmd.Ex()
            end, opts)

            vim.keymap.set("n", "f", function()
                restore_cursor()
                if pcall(require, 'fzf-lua') then
                    require('fzf-lua').files()
                else
                    vim.notify("FZF-Lua não está carregado", vim.log.levels.WARN)
                end
            end, opts)

            vim.keymap.set("n", "wq", ":q!<CR>", opts)
        end,
    })
end

------------------------------------------------------------
-- PACKER + PLUGINS
------------------------------------------------------------
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use {
      'ibhagwan/fzf-lua',
      requires = { 'nvim-lua/plenary.nvim' },
  }
  use {
      'williamboman/mason.nvim',
      tag = 'v1.10.0',
  }
  use { 'tahayvr/matteblack.nvim', as = 'matteblack' }
  use 'xero/miasma.nvim'
  use {
      'nvim-treesitter/nvim-treesitter',
      run = function()
          require('nvim-treesitter.install').update({ with_sync = true })
      end,
  }

  use 'mbbill/undotree'
  use 'tpope/vim-fugitive'
  use 'neovim/nvim-lspconfig'
  use {
      'saghen/blink.cmp',
      tag = 'v1.10.1',
      requires = { 'rafamadriz/friendly-snippets' },
  }
  use 'rose-pine/neovim'
  use 'theprimeagen/harpoon'
  use "sindrets/diffview.nvim"

  use "folke/which-key.nvim"

  use 'dchinmay2/alabaster.nvim'

  use 'martinsione/darkplus.nvim'

  use 'Mofiqul/vscode.nvim'

  use {
      'nvim-tree/nvim-tree.lua',
      requires = { 'nvim-tree/nvim-web-devicons' },
  }

  use {
      'williamboman/mason-lspconfig.nvim',
      tag = 'v1.0.0',
      requires = { 'williamboman/mason.nvim' },
  }

  use { 'folke/zen-mode.nvim' }
  use 'vyrx-dev/sloat'
  use { 'eero-lehtinen/oklch-color-picker.nvim' }
  use { 'echasnovski/mini.surround' }
  use {
    'mfussenegger/nvim-dap',
    requires = {
      { 'rcarriga/nvim-dap-ui', requires = { 'nvim-neotest/nvim-nio' } },
      'theHamsta/nvim-dap-virtual-text',
      'leoluz/nvim-dap-go',
    },
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)

------------------------------------------------------------
-- CONFIGURAÇÕES APÓS INSTALAÇÃO
------------------------------------------------------------
local function post_install_setup()
  setup_dashboard()

  pcall(function()
      require('fzf-lua').setup({
          winopts = {
              height = 0.85,
              width = 0.85,
              row = 0.5,
              col = 0.5,
              border = 'rounded',
          },
          files = {
              prompt = 'Files❯ ',
          },
          grep = {
              prompt = 'Grep❯ ',
          },
      })
  end)

  pcall(function()
      require("mason").setup()
  end)

  pcall(function()
      require('blink.cmp').setup({
          keymap = {
              preset = 'default',
              ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
              ['<Tab>'] = { 'accept', 'fallback' },
              ['<S-Tab>'] = { 'select_prev', 'fallback' },
              ['<C-n>'] = { 'select_next', 'fallback' },
              ['<C-p>'] = { 'select_prev', 'fallback' },
              ['<C-e>'] = { 'hide' },
              ['<C-y>'] = { 'accept' },
          },

          completion = {
              documentation = {
                  auto_show = false,
              },
              menu = {
                  auto_show = true,
                  draw = {
                      columns = { { "label", "label_description", gap = 1 } },
                  },
              },
              list = {
                  max_items = 10,
                  selection = {
                      preselect = true,
                  },
              },
          },

          sources = {
              default = { 'lsp', 'path', 'snippets', 'buffer' },
              providers = {
                  lsp = {
                      name = 'LSP',
                      module = 'blink.cmp.sources.lsp',
                      score_offset = 100,
                  },
                  path = {
                      name = 'Path',
                      module = 'blink.cmp.sources.path',
                      score_offset = 10,
                      opts = {
                          trailing_slash = false,
                          label = 'Path',
                      },
                  },
                  buffer = {
                      name = 'Buffer',
                      module = 'blink.cmp.sources.buffer',
                      score_offset = 5,
                      opts = {
                          min_keyword_length = 2,
                          max_entries = 100,
                      },
                  },
                  snippets = {
                      name = 'Snippets',
                      module = 'blink.cmp.sources.snippets',
                      score_offset = 15,
                  },
              },
          },

          snippets = {
              preset = 'default',
          },

          fuzzy = {
              implementation = 'prefer_rust_with_warning',
          },
      })
  end)

  require("mason-lspconfig").setup({
      ensure_installed = {
          "lua_ls",
          "pyright",
          "vtsls",
      },
      automatic_installation = true,
  })

  local lspconfig = require("lspconfig")
  local capabilities = require('blink.cmp').get_lsp_capabilities()

  require("mason-lspconfig").setup_handlers({
      function(server_name)
          lspconfig[server_name].setup({
              capabilities = capabilities,
          })
      end,

      ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
              capabilities = capabilities,
              settings = {
                  Lua = {
                      diagnostics = {
                          globals = { "vim" },
                      },
                      workspace = {
                          checkThirdParty = false,
                          library = {
                              vim.env.VIMRUNTIME,
                          },
                      },
                      telemetry = {
                          enable = false,
                      },
                  },
              },
          })
      end,

      ["pyright"] = function()
          lspconfig.pyright.setup({
              capabilities = capabilities,
              settings = {
                  python = {
                      analysis = {
                          typeCheckingMode = "basic",
                          autoSearchPaths = true,
                          useLibraryCodeForTypes = true,
                      },
                  },
              },
          })
      end,

      ["vtsls"] = function()
          lspconfig.vtsls.setup({
              capabilities = capabilities,
              settings = {
                  typescript = {
                      inlayHints = {
                          includeInlayParameterNameHints = 'all',
                          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                          includeInlayFunctionParameterTypeHints = true,
                          includeInlayVariableTypeHints = true,
                          includeInlayPropertyDeclarationTypeHints = true,
                          includeInlayFunctionLikeReturnTypeHints = true,
                          includeInlayEnumMemberValueHints = true,
                      },
                  },
                  javascript = {
                      inlayHints = {
                          includeInlayParameterNameHints = 'all',
                          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                          includeInlayFunctionParameterTypeHints = true,
                          includeInlayVariableTypeHints = true,
                          includeInlayPropertyDeclarationTypeHints = true,
                          includeInlayFunctionLikeReturnTypeHints = true,
                          includeInlayEnumMemberValueHints = true,
                      },
                  },
              },
          })
      end,
  })

  pcall(function()
      local mark = require("harpoon.mark")
      local ui = require("harpoon.ui")

      vim.keymap.set("n", "<leader>a", mark.add_file)
      vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

      vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end)
      vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end)
      vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end)
      vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end)
  end)

  pcall(function()
      require('nvim-tree').setup({
          disable_netrw = false,
          hijack_netrw = false,
          hijack_directories = {
              enable = false,
          },
          view = {
              width = 50,
              side = 'left',
          },
          filters = {
              dotfiles = false,
          },
          update_focused_file = {
              enable = true,
          },
      })
  end)

  pcall(function()
      require('diffview').setup({
          view = {
              default = {
                  layout = "diff2_horizontal",
              },
              file_history = {
                  layout = "diff2_horizontal",
              },
          },
          panel = {
              position = "left",
              width = 20,
          },
      })
  end)

  pcall(function()
      local wk = require("which-key")
      wk.setup({
          preset = "helix",
          delay = 300,
      })

      wk.add({
          { "<leader>w", group = "window/write" },
          { "<leader>g", group = "git" },
          { "<leader>v", group = "lsp" },

          { "<leader>ww", desc = "Write file" },
          { "<leader>wq", desc = "Quit" },
          { "<leader>q",  desc = "Close tab" },
          { "<leader>e",  desc = "Explorer (netrw)" },
          { "<leader>n",  desc = "New file" },

          { "<leader>wv", desc = "Vertical split" },
          { "<leader>ws", desc = "Horizontal split" },
          { "<leader>wh", desc = "Go to left window" },
          { "<leader>wj", desc = "Go to below window" },
          { "<leader>wk", desc = "Go to above window" },
          { "<leader>wl", desc = "Go to right window" },

          { "<leader>t", desc = "Open terminal split (zsh)" },
          { "<leader>i", desc = "Open agy in vsplit" },
          { "<leader>o", desc = "Open opencode in vsplit" },

          { "<leader>d", desc = "Diffview open" },
          { "<leader>b", desc = "Toggle NvimTree" },
          { "<leader>u", desc = "Toggle Undotree" },

          { "<leader><Tab>",   desc = "Next tab" },
          { "<leader><S-Tab>", desc = "Previous tab" },
          { "<leader>N", desc = "New tab" },

          { "<leader>gt", desc = "Git status (fugitive)" },
          { "<leader>gl", desc = "Git log (fzf-lua)" },
          { "<leader>gs", desc = "Git status (fzf-lua)" },
          { "<leader>gd", desc = "Git branches (fzf-lua)" },
          { "<leader>gb", desc = "Git file history (fzf-lua)" },
          { "<leader>gg", desc = "Git Grep (fzf-lua)" },
          { "<leader>gc", desc = "Git commit" },

          { "<leader>vww", desc = "Workspace symbol" },
          { "<leader>vd",  desc = "Open diagnostic float" },
          { "<leader>vca", desc = "Code action" },
          { "<leader>vr",  desc = "LSP references" },
          { "<leader>vrn", desc = "LSP rename" },

          { "<leader>f", desc = "Find files (fzf-lua)" },
          { "<leader>x", desc = "Open directory (new tab)" },
          { "<leader>s", desc = "Fuzzy find in current buffer" },
          { "<leader>a", desc = "Harpoon: add file" },
          { "<leader>1", desc = "Harpoon: file 1" },
          { "<leader>2", desc = "Harpoon: file 2" },
          { "<leader>3", desc = "Harpoon: file 3" },
          { "<leader>4", desc = "Harpoon: file 4" },

          { "<leader>m", desc = "Toggle comment", mode = "v" },
      })
  end)

  vim.cmd('hi statusline guibg=NONE')

  vim.keymap.set('n', '<leader>ww', ':write<CR>')
  vim.keymap.set('n', '<leader>wq', ':quit<CR>')
  vim.keymap.set('n', '<leader>e', vim.cmd.Ex)
  vim.keymap.set('n', '<leader>n', ':enew<CR>', { desc = 'New File' })
  vim.keymap.set('n', '<leader>q', ':tabclose<CR>')

  vim.keymap.set('n', '<leader>wv', ':vsplit<CR>', { silent = true })
  vim.keymap.set('n', '<leader>ws', ':split<CR>', { silent = true })

  vim.keymap.set('n', '<leader>wh', '<C-w>h')
  vim.keymap.set('n', '<leader>wj', '<C-w>j')
  vim.keymap.set('n', '<leader>wk', '<C-w>k')
  vim.keymap.set('n', '<leader>wl', '<C-w>l')

  vim.keymap.set('n', '<leader>t', function()
      vim.cmd('belowright 12split')
      vim.cmd('enew')
      vim.fn.termopen({ 'C:/Program Files/Git/bin/bash.exe', '--login', '-i' })
  end, { silent = true })

  vim.keymap.set('n', '<leader>i', function()
      vim.cmd('vsplit')
      vim.cmd('wincmd l')
      vim.cmd('vertical resize 50')
      vim.cmd('terminal agy')
  end, { silent = true, desc = 'Open CLI' })
  vim.keymap.set('n', '<leader>d', ':DiffviewOpen<CR>', { silent = true, desc = 'Diffview' })
  vim.keymap.set('n', '<leader>b', ':NvimTreeToggle<CR>', { silent = true, desc = 'Toggle NvimTree' })
  vim.keymap.set('n', '<leader><Tab>', ':tabnext<CR>', { silent = true, desc = 'Next tab' })
  vim.keymap.set('n', '<leader><S-Tab>', ':tabprevious<CR>', { silent = true, desc = 'Last tab' })
  vim.keymap.set('n', '<leader>N', ':tabnew<CR>', { silent = true, desc = 'New tab' })

  vim.keymap.set("n", "<leader>cc", compile_prompt, { desc = "Compile (prompt)" })
  vim.keymap.set("n", "<leader>cr", recompile, { desc = "Recompile (last command)" })
  vim.keymap.set("n", "]q", ":cnext<CR>", { desc = "Next error" })
  vim.keymap.set("n", "[q", ":cprev<CR>", { desc = "Previous error" })

  vim.keymap.set('n', ']e', ':cnext<CR>zz', { silent = true, desc = "Next error" })
  vim.keymap.set('n', '[e', ':cprevious<CR>zz', { silent = true, desc = "Previous error" })
  vim.keymap.set('n', '<leader>co', ':copen<CR>', { silent = true, desc = "Open quickfix" })

  vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
  vim.keymap.set('n', '<leader>gt', vim.cmd.Git)

  vim.keymap.set('n', '<leader>gl', function()
      require('fzf-lua').git_commits()
  end, { desc = 'Git Log (fzf-lua)' })

  vim.keymap.set('n', '<leader>gs', function()
      require('fzf-lua').git_status()
  end, { desc = 'Git Status (fzf-lua)' })

  vim.keymap.set('n', '<leader>gd', function()
      require('fzf-lua').git_branches()
  end, { desc = 'Git Branches (fzf-lua)' })

  vim.keymap.set('n', '<leader>gb', function()
      require('fzf-lua').git_bcommits()
  end, { desc = 'Git File History (fzf-lua)' })

  vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { silent = true, desc = 'Git commit' })

  vim.keymap.set('n', '<C-p>', function()
      require('fzf-lua').git_files()
  end, { desc = 'Git Files (fzf-lua)' })

  vim.keymap.set("n", "gd", vim.lsp.buf.definition)
  vim.keymap.set("n", "K", vim.lsp.buf.hover)
  vim.keymap.set("n", "<leader>vww", vim.lsp.buf.workspace_symbol)
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_next)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_prev)
  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action)
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references)
  vim.keymap.set("n", "<leader>rr", vim.lsp.buf.rename)
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help)

  vim.keymap.set('n', '<leader>f', function()
    require('fzf-lua').files()
  end, { desc = 'FZF Files' })

  vim.keymap.set('n', '<leader>s', function()
      require('fzf-lua').blines()
  end, { desc = 'Fuzzy find in current buffer' })

  vim.keymap.set('n', '<leader>gg', function()
      require('fzf-lua').live_grep({
          cmd = "git grep --line-number --column --color=always",
          prompt = 'GitGrep❯ ',
      })
  end, { desc = 'Live Grep (git files only)' })

  vim.keymap.set("v", "<leader>m", function()
      local cs = vim.bo.commentstring
      local prefix = cs:match("^(.-)%s*%%s")

      local start_line = vim.fn.line("v")
      local end_line = vim.fn.line(".")
      if start_line > end_line then
          start_line, end_line = end_line, start_line
      end

      local all_commented = true
      for i = start_line, end_line do
          local l = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
          if not l:match("^%s*" .. vim.pesc(prefix)) then
              all_commented = false
              break
          end
      end

      for i = start_line, end_line do
          local l = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
          local new
          if all_commented then
              new = l:gsub("%s*" .. vim.pesc(prefix) .. "%s?", "", 1)
          else
              local indent = l:match("^(%s*)")
              local rest = l:sub(#indent + 1)
              new = indent .. prefix .. " " .. rest
          end
          vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new })
      end

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", false)
  end, { desc = "toggle comentário na seleção" })

  ------------------------------------------------------------
  -- Seletor de diretórios
  ------------------------------------------------------------
  local dirs_cache = nil

  local function populate_cache(callback)
      local home = vim.fn.expand("$HOME")
      local config = home .. "/.config"

      local dirs = {}
      local pending = vim.uv.fs_stat(config) and 2 or 1

      local function done()
          pending = pending - 1
          if pending == 0 then
              dirs_cache = dirs
              if callback then
                  callback()
              end
          end
      end

      local function collect(result)
          if result.code == 0 and result.stdout then
              for line in result.stdout:gmatch("[^\r\n]+") do
                  dirs[#dirs + 1] = line
              end
          end
          vim.schedule(done)
      end

      vim.system(
          { "fd", "--type", "d", "--exclude", ".*", ".", home },
          { text = true },
          collect
      )

      if vim.uv.fs_stat(config) then
          vim.system(
              { "fd", "--type", "d", "--hidden", ".", config },
              { text = true },
              collect
          )
      end
  end

  vim.schedule(function()
      populate_cache()
  end)

  local function open_dir_picker(new_tab)
      local function show()
          require("fzf-lua").fzf_exec(dirs_cache, {
              prompt = "Dirs> ",
              fzf_opts = {
                  ["--height"] = "100%",
                  ["--layout"] = "reverse",
                  ["--border"] = "none",
                  ["--margin"] = "0",
                  ["--padding"] = "0",
              },
              actions = {
                  ["default"] = function(selected)
                      local dir = selected[1]
                      if not dir or dir == "" then
                          return
                      end
                      local target = vim.fn.fnameescape(vim.fn.trim(dir))
                      if new_tab then
                          vim.cmd.tabnew()
                          vim.cmd.tcd(target)
                      else
                          vim.cmd.cd(target)
                      end
                      vim.cmd.edit(".")
                  end,
              },
          })
      end

      if dirs_cache then
          show()
      else
          populate_cache(show)
      end
  end

  vim.keymap.set("n", "<C-x>", function()
      open_dir_picker(false)
  end, { desc = "Open directory (current tab)" })
  vim.keymap.set("n", "<leader>x", function()
      open_dir_picker(true)
  end, { desc = "Open directory (new tab)" })

  pcall(function()
      require('nvim-treesitter.configs').setup({
          ensure_installed = {
              "lua",
              "vim",
              "vimdoc",
              "bash",
              "json",
              "javascript",
              "typescript",
              "html",
              "css",
              "markdown",
              "elixir",
              "python",
          },
          sync_install = true,
          auto_install = true,
          highlight = {
              enable = true,
          },
          indent = {
              enable = true,
          },
      })
  end)

  ------------------------------------------------------------
  -- fzf-lua binds extras
  ------------------------------------------------------------
  pcall(function()
    local set = vim.keymap.set
    set("n", ";r", function() require("fzf-lua").live_grep({ hidden = true }) end, { desc = "Live Grep" })
    set("n", ";c", function() require("fzf-lua").colorschemes() end, { desc = "Colorschemes" })
    set("n", ";a", function() require("fzf-lua").buffers() end, { desc = "Buffers" })
    set("n", "<leader><leader>", function() require("fzf-lua").files({ hidden = true }) end, { desc = "Search Files" })
    set("n", [[\\]], function() require("fzf-lua").resume() end, { desc = "Resume Picker" })

    set("n", "<leader>sh", function() require("fzf-lua").help_tags() end, { desc = "Search Help" })
    set("n", "<leader>sk", function() require("fzf-lua").keymaps() end, { desc = "Search Keymaps" })
    set("n", "<leader>ss", function() require("fzf-lua").builtin() end, { desc = "Search Select" })
    set("n", "<leader>sw", function() require("fzf-lua").grep_cword() end, { desc = "Search Word" })
    set("n", "<leader>sd", function() require("fzf-lua").diagnostics_document() end, { desc = "Search Diagnostics (buf)" })
    set("n", "<leader>sD", function() require("fzf-lua").diagnostics_workspace() end, { desc = "Search Diagnostics (ws)" })
    set("n", "<leader>s.", function() require("fzf-lua").oldfiles() end, { desc = "Search Recent Files" })
    set("n", "<leader>sp", function()
      require("fzf-lua").files({ cwd = vim.fn.stdpath("data") .. "/site/pack/packer/start" })
    end, { desc = "Search Plugin Files" })
    set("n", "<leader>sn", function()
      require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "Search Neovim Config" })
  end)

  ------------------------------------------------------------
  -- which-key bind extra
  ------------------------------------------------------------
  pcall(function()
    vim.keymap.set("n", "<leader>?", function()
      require("which-key").show({ global = false })
    end, { desc = "Buffer Local Keymaps (which-key)" })
  end)

  ------------------------------------------------------------
  -- Zen Mode
  ------------------------------------------------------------
  pcall(function()
    require("zen-mode").setup({
      plugins = {
        options = { laststatus = 0 },
        tmux = true,
        kitty = { enabled = false, font = "+4" },
        alacritty = { enabled = true, font = "18" },
      },
    })
    vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<cr>", { desc = "Zen Mode" })
  end)

  ------------------------------------------------------------
  -- Color Picker (binds <leader>cp / <leader>cP)
  ------------------------------------------------------------
  pcall(function()
    require("oklch-color-picker").setup({
      highlight_colors = { enable = true },
      keymaps = { confirm = "<CR>" },
    })
    vim.keymap.set("n", "<leader>cp", function() require("oklch-color-picker").open_picker() end, { desc = "Open Color Picker" })
    vim.keymap.set("n", "<leader>cP", function() require("oklch-color-picker").pick_under_cursor() end, { desc = "Pick Color Under Cursor" })
  end)

  ------------------------------------------------------------
  -- Sloat (terminal flutuante)
  ------------------------------------------------------------
  pcall(function()
    require("sloat").setup({
      float = { width = 0.4, height = 0.5, border = "single" },
      bottom = { height = 15 },
      root_patterns = { ".git", "Makefile", "package.json", "Cargo.toml", "go.mod" },
    })
    vim.keymap.set({ "n", "t" }, ";t", "<cmd>Sloat float<cr>", { desc = "Sloat: float" })
    vim.keymap.set("n", ";st", "<cmd>Sloat bottom<cr>", { desc = "Sloat: bottom" })
    vim.keymap.set("n", ";d", "<cmd>Sloat kill<cr>", { desc = "Sloat: kill" })
  end)

  ------------------------------------------------------------
  -- mini.surround
  ------------------------------------------------------------
  pcall(function()
    require("mini.surround").setup({
      mappings = {
        add = "sa",
        delete = "sd",
        find = "",
        find_left = "",
        highlight = "",
        replace = "sr",
        update_n_lines = "",
      },
      n_lines = 30,
    })
  end)

  ------------------------------------------------------------
  -- DAP (binds renomeadas para <leader>D*)
  ------------------------------------------------------------
  pcall(function()
    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()
    require("nvim-dap-virtual-text").setup({})

    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    require("dap-go").setup()

    local set = vim.keymap.set
    set("n", "<leader>Db", function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
    set("n", "<leader>DB", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, { desc = "Debug: Conditional Breakpoint" })
    set("n", "<leader>Dc", function() dap.continue() end, { desc = "Debug: Continue/Start" })
    set("n", "<leader>Dn", function() dap.step_over() end, { desc = "Debug: Step Over" })
    set("n", "<leader>Di", function() dap.step_into() end, { desc = "Debug: Step Into" })
    set("n", "<leader>Do", function() dap.step_out() end, { desc = "Debug: Step Out" })
    set("n", "<leader>Dt", function() dap.terminate() end, { desc = "Debug: Terminate" })
    set("n", "<leader>Dr", function() dap.repl.toggle() end, { desc = "Debug: Toggle REPL" })
    set("n", "<leader>Du", function() dapui.toggle() end, { desc = "Debug: Toggle UI" })
    set("n", "<leader>Dg", function() require("dap-go").debug_test() end, { desc = "Debug: Go Test (nearest)" })
    set("n", "<leader>DG", function() require("dap-go").debug_last_test() end, { desc = "Debug: Go Test (last)" })
  end)
end

------------------------------------------------------------
-- EXECUTA SETUP
------------------------------------------------------------
if packer_bootstrap then
  vim.api.nvim_create_autocmd('User', {
    pattern = 'PackerComplete',
    once = true,
    callback = post_install_setup
  })
else
  post_install_setup()
end

------------------------------------------------------------
-- KEYMAPS GLOBAIS EXTRAS
------------------------------------------------------------
local set = vim.keymap.set
local kopts = { noremap = true, silent = true }

set("n", "ss", ":split<Return>", kopts)
set("n", "sv", ":vsplit<Return>", kopts)
set("n", "sx", "<cmd>close<CR>", kopts)

set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })

set("n", "<C-a>", "gg<S-v>G")

set({ "n", "o", "x" }, "<s-h>", "^", { desc = "Jump to beginning of line" })
set({ "n", "o", "x" }, "<s-l>", "g_", { desc = "Jump to end of line" })

set("n", "<leader>cf", '<cmd>let @+ = expand("%")<CR>', { desc = "Copy File Name" })

set("n", "<C-u>", "<C-u>zz")
set("n", "<C-d>", "<C-d>zz")
set("n", "n", "nzzzv", kopts)
set("n", "N", "Nzzzv", kopts)

set("v", "<", "<gv", kopts)
set("v", ">", ">gv", kopts)

set("n", "<leader>lw", "<cmd>set wrap!<CR>", kopts)

set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })

set("n", "x", '"_x', kopts)

set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

set({ "n", "v" }, "<leader>d", [["_d]])
set("x", "p", [["_dP]])

set("n", "<leader><left>", ":vertical resize +20<cr>")
set("n", "<leader><right>", ":vertical resize -20<cr>")
set("n", "<leader><up>", ":resize +10<cr>")
set("n", "<leader><down>", ":resize -10<cr>")

set("n", "<Tab>", ":bnext<cr>", kopts)
set("n", "<S-Tab>", ":bprevious<cr>", kopts)
set("n", "<leader>bd", ":bdelete!<cr>", kopts)
set("n", "<leader>bn", "<cmd> enew <cr>", kopts)

set("n", "<leader>ll", "<cmd>PackerStatus<CR>", { desc = "Open Packer status" })
set("n", "<leader>lm", "<cmd>Mason<CR>", { desc = "Open Mason LSP installer" })

set("n", "<leader>tf", ":ToggleAutoformat<CR>", { desc = "Toggle format on save" })

  -- vim.keymap.set("n", "<leader>//", function()
      -- local query = vim.fn.input("Google: ")
-- 
      -- if query ~= "" then
          -- vim.fn.jobstart({
              -- "xdg-open",
              -- "https://www.google.com/search?q=" .. query,
          -- }, {
              -- detach = true,
          -- })
      -- end
  -- end, { desc = "Pesquisar no Google" })

------------------------------------------------------------
-- COLORSCHEME
------------------------------------------------------------
local function remove_all_italics()
  for _, group in ipairs(vim.fn.getcompletion('', 'highlight')) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
    if ok and hl and hl.italic then
      hl.italic = false
      pcall(vim.api.nvim_set_hl, 0, group, hl)
    end
  end
end

function ColorMyPencils(color)
  color = color or "vscode"

  local ok = pcall(vim.cmd.colorscheme, color)
  if not ok then
    return
  end

  remove_all_italics()
end

ColorMyPencils()
