local M = {}

-- Check for loaded state
if vim.g.ray_loaded then
  return
end
vim.g.ray_loaded = 1

-- Setup default options
vim.g.ray_browser = vim.g.ray_browser or ''
vim.g.ray_base_url = vim.g.ray_base_url or 'https://ray.so/'
vim.g.ray_config = {
  theme = 'midnight',
  background = 'true',
  darkMode = 'true',
  padding = '64',
  language = 'auto'
}

M.override_config = function(params)
  for k, v in pairs(params) do
    vim.g.ray_config[k] = v
  end
end

M.setup = function(params)
  M.override_config(params)
  vim.api.nvim_command("command! -range Ray :lua require('raysosnap.main').ray_so_snap()")
end

M.ray_so_snap = function()
  local text = M.url_encode(M.encode_base64(M.get_visual_selection()))
  local browser = M.get_browser()
  local options = type(vim.g.ray_config) == "table" and M.get_options() or vim.g.ray_config

  local url = vim.g.ray_base_url .. '/#code=' .. text .. '&' .. options

  if vim.fn.has('win32') and browser == 'start' and vim.o.shell:match("<cmd.exe$") then
    os.execute(browser .. ' "" "' .. url .. '"')
  else
    os.execute(browser .. ' ' .. url)
  end
  print(vim.inspect(vim.g.ray_config))
end

M.get_browser = function()
  -- User-specified browser takes the highest priority
  if vim.g.ray_browser and vim.g.ray_browser ~= '' then
    return vim.g.ray_browser
  end

  -- List of potential browser commands or checks
  local browsers = {
    { check = function() return vim.env.WSL_DISTRO_NAME and vim.fn.executable('cmd.exe') end, cmd = 'cmd.exe /c start' }, -- WSL check
    { check = function() return vim.fn.executable('xdg-open') end,                            cmd = 'xdg-open' },
    { check = function() return vim.fn.has('win32') end,                                      cmd = 'start' },
    { check = function() return vim.fn.executable('open') end,                                cmd = 'open' },
    { check = function() return vim.fn.executable('google-chrome') end,                       cmd = 'google-chrome' },
    { check = function() return vim.fn.executable('firefox') end,                             cmd = 'firefox' }
  }

  -- Loop through the list and return the first valid browser command
  for _, browser in ipairs(browsers) do
    if browser.check() then
      return browser.cmd
    end
  end

  error('Browser not found')
end

M.get_options = function()
  local options = vim.g.ray_config
  local result = ''

  for key, value in pairs(options) do
    result = result .. '&' .. M.url_encode(key) .. '=' .. M.url_encode(options[key])
  end

  return result
end
M.split = function(inputstr, sep)
  if sep == nil then
    sep = "%s" -- default to splitting by spaces
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

M.url_encode = function(str)
  local result = {}

  -- Split each character of the string.
  local characters = {}
  for character in str:gmatch(".") do
    table.insert(characters, character)
  end

  for _, character in ipairs(characters) do
    if M.character_requires_url_encoding(character) then
      for i = 1, #character do
        local byte = character:sub(i, i)
        local decimal = string.byte(byte)
        table.insert(result, string.format("%%%02x", decimal))
      end
    else
      table.insert(result, character)
    end
  end

  return table.concat(result)
end

M.character_requires_url_encoding = function(character)
  local ascii_code = string.byte(character)

  -- Check if it's a number (0-9)
  if ascii_code >= 48 and ascii_code <= 57 then
    return false
    -- Check if it's an uppercase letter (A-Z)
  elseif ascii_code >= 65 and ascii_code <= 90 then
    return false
    -- Check if it's a lowercase letter (a-z)
  elseif ascii_code >= 97 and ascii_code <= 122 then
    return false
    -- Check for '-', '_', '.', '~'
  elseif character == '-' or character == '_' or character == '.' or character == '~' then
    return false
  end

  return true
end

M.get_visual_selection = function()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    if #lines == 0 then return "" end

    -- Modify the start and end lines based on the selection
    lines[1] = lines[1]:sub(start_pos[3])
    lines[#lines] = lines[#lines]:sub(1, end_pos[3])

    return table.concat(lines, "\n")
end

M.encode_base64 = function(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r, b = '', x:byte()
    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r;
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then
      return ''
    end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
    end
    return b:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

return M
