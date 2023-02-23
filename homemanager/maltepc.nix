{ config, pkgs, ... }:
let
  selected-nerdfonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "SourceCodePro" ]; })
  ]; # currently not working
  python-packages = p: with p; [
    pandas
    numpy
    pynvim
  ];
in {
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    alacritty
    element-desktop
    mako
    mpv
    # neovim and plugin dependencies {{{
    neovim
    neovim-remote
    luajitPackages.jsregexp # dependency of luasnip neovim plugin
    tree-sitter
    neovim-qt
    nodejs
    nodePackages.npm
    wget
    curl
    # }}} neovim and plugin dependencies
    qutebrowser
    spotify
    sway
    waybar
    font-awesome # needed for waybar icons
    bemenu
    j4-dmenu-desktop # desktop files for bemenu
    ungoogled-chromium
    (python3.withPackages python-packages)
    virtualenv
    ripgrep
    zathura
    wl-clipboard
    nerdfonts
    xdg-utils
    zsh-powerlevel10k
  ];

  home.sessionVariables = {
    VISUAL = "nvim";
  };

  # use config folder
  home.file.".config" = {
    source = ./config;
    recursive = true;
  };
  home.file.".p10k.zsh".source = ./config/p10k.zsh;

  # allow homemanager fonts
  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true; # not finished if system package completion is wanted (look at home manager documentation)
    autocd = true;
    defaultKeymap = "vicmd";
    history.save = 1000;
    history.size = 1000;
    initExtra = "setopt extended_glob\nbindkey 'kj' vi-cmd-mode";
    shellAliases = {
      "bat" = "bat --theme gruvbox-dark";
      "tree" = "tree -C";
      "tt" = "taskwarrior-tui";
      "cp" = "cp --reflink=auto";
    };
    prezto = {
      enable = true;
      editor = {
        dotExpansion = true;
        keymap = "vi";
      };
      prompt.theme = "powerlevel10k";
    };
  };

  # default applications
  xdg.mime.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
    "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
    "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
    "x-scheme-handler/about" = [ "org.qutebrowser.qutebrowser.desktop" ];
    "x-scheme-handler/unknown" = [ "org.qutebrowser.qutebrowser.desktop" ];
    };
  };
}
