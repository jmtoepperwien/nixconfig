{ config, pkgs, ... }:
let
  python-packages = p: with p; [
    pandas
    numpy
    pynvim
    ipython
  ];
in {
  home.packages = with pkgs; [
    alacritty
    element-desktop
    discord
    mako
    mpv
    # neovim and plugin dependencies {{{
    neovim
    neovim-remote
    luajitPackages.jsregexp # dependency of luasnip neovim plugin
    tree-sitter
    nextcloud-client
    neovim-qt
    nodejs
    nodePackages.npm
    wget
    curl
    lua-language-server
    clang-tools
    # }}} neovim and plugin dependencies
    # Latex
    texlive.combined.scheme-full
    qutebrowser
    spotify
    sway
    wofi # for sway
    playerctl # sway audio button bindings
    waybar
    font-awesome # needed for waybar icons
    ungoogled-chromium
    (python3.withPackages python-packages)
    virtualenv
    ripgrep
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "SourceCodePro" ]; })
    zathura
    wl-clipboard
    nerdfonts
    xdg-utils
    unzip
    # gnupg
    gnupg
    pinentry-curses
    pass
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
    history.save = 1000;
    history.size = 1000;
    initExtra = ''
      setopt extended_glob

      bindkey 'kj' vi-cmd-mode

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      function open {
      for i
          do (xdg-open "$i" > /dev/null 2> /dev/null &)
      done
    }'';
    shellAliases = {
      "bat" = "bat --theme gruvbox-dark";
      "tree" = "tree -C";
      "tt" = "taskwarrior-tui";
      "cp" = "cp --reflink=auto";
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "wd"
      ];
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
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  # GnuPG
  programs.gpg = {
    enable = true;
  };
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "curses";
  };

  # emails
  accounts.email.accounts = {
    "protonmail" = {
      address = "m.toepperwien@protonmail.com";
      userName = "m.toepperwien@protonmail.com";
      primary = true;
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
    };
    "university" = {
      address = "m.toepperwien@stud.uni-hannover.de";
      userName = "m.toepperwien@stud.uni-hannover.de";
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
    };
    "gmail" = {
      address = "m.toepperwien@gmail.com";
      userName = "m.toepperwien@gmail.com";
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
    };
  };
  programs.thunderbird.enable = true;
  programs.thunderbird.profiles."default".isDefault = true;

}
