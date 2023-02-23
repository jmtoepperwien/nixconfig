if vim.g.GuiLoaded ~= nil then
  vim.cmd [[GuiFont SauceCodePro\ Nerd\ Font\ Mono:h18]]
  vim.cmd [[GuiClipboard()]]
end

if vim.fn.exists(":GuiPopupmenu") then
  vim.cmd [[GuiPopupmenu 0]]
end

if vim.fn.exists(":GuiScrollBar") then
  vim.cmd [[GuiScrollBar 0]]
end

if vim.fn.exists(":GuiRenderLigatures") then
  vim.cmd [[GuiRenderLigatures 0]]
end
