{ config, pkgs, nixpkgs-unstable, ... }:
let
  lua-packages = p: with p; [
    luarocks
  ];
  python-packages = p: with p; [
    pandas
    numpy
    pynvim
    ipython
    matplotlib
    plotly
    scikit-learn
    scipy
    # For molten.nvim
    jupyter-client
    cairosvg
    pnglatex
    plotly
    pyperclip
    nbformat
    pillow
    requests
    websocket-client
  ] ++ [ pkgs.callPackage ../programs/kaleido.nix {} pkgs.callPackage ../programs/jupyter_ascending.nix {} ];
  neomutt_gruvboxtheme = pkgs.callPackage ./neomutt_gruvboxtheme.nix {};
  wallpaper = ./config/hypr/wallpaper/gruvbox-dark-blue.png;
in {
  imports = [ ./devel.nix ];

  home.packages = with pkgs; [
    alacritty
    element-desktop
    discord
    mako
    mpv
    steam-run
    feh
    obsidian
    # neovim and plugin dependencies {{{
    neovim-remote
    luajitPackages.jsregexp # dependency of luasnip neovim plugin
    tree-sitter
    nextcloud-client
    jq
    inkscape
    imv
    nodejs
    nodePackages.npm
    wget
    curl
    lua-language-server
    clang-tools
    nodePackages_latest.pyright
    cairo
    # }}} neovim and plugin dependencies
    lazygit
    # Latex
    texlive.combined.scheme-full
    qutebrowser
    spotify
    sway
    hyprland
    wofi # for sway
    slurp
    grim
    playerctl # sway audio button bindings
    waybar
    font-awesome # needed for waybar icons
    ungoogled-chromium
    (python3.withPackages python-packages)
    (lua5_1.withPackages lua-packages)
    # poetry ignore for now due to dependency missing
    virtualenv
    ripgrep
    pdfgrep
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

    libreoffice-fresh
    grim
    pdftk
    pandoc
    xournalpp
    taskwarrior
    taskwarrior-tui
  ] ++ (with nixpkgs-unstable.legacyPackages.${pkgs.system}; [ neovim-qt neovide ]);

  home.sessionVariables = {
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  # use config folder
  home.file.".config" = {
    source = ./config;
    recursive = true;
  };
  home.file.".p10k.zsh".source = ./config/p10k.zsh;
  home.file.".taskrc".source = ./config/taskrc;

  programs.neovim = {
    enable = true;
    package = nixpkgs-unstable.legacyPackages.${pkgs.system}.neovim-unwrapped;
    extraLuaPackages = ps: [ ps.magick ps.luarocks ];
    extraPackages = [ pkgs.imagemagick ];
    extraPython3Packages = ps: with ps; [
      pynvim
      ipython
      jupyter-client
      cairosvg
      pnglatex
      plotly
      pyperclip
      nbformat
      pillow
      requests
      websocket-client
      kaleido
    ];
    extraLuaConfig = ''
      vim.loader.enable()
      vim.g.mapleader = ","
      require("vimsettings")
      require("bootstrap/lazy")
      require("plugins")
      require("keybindings")
      local status, ts_install = pcall(require, "nvim-treesitter.install")
      if(status) then
        ts_install.compilers = { "${pkgs.gcc_multi}/bin/gcc" }
      end
    '';
  };
  programs.kitty = {
    enable = true;
    font = {
      name = "SauceCodePro Nerd Font Mono";
      size = 15;
    };
    theme = "Gruvbox Material Dark Medium";
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = 0;
      disable_ligatures = "always";
      repaint_delay = 7;  # this is approx 144hz
      enable_audio_bell = false;
      notify_on_cmd_finish = "unfocused 60.0";
    };
    keybindings = {
      "alt+enter" = "new_window_with_cwd";
      "alt+j" = "next_window";
      "alt+k" = "previous_window";
      "alt+t" = "new_tab";
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";
      "alt+6" = "goto_tab 6";
      "alt+7" = "goto_tab 7";
      "alt+8" = "goto_tab 8";
      "alt+9" = "goto_tab 9";
      "alt+0" = "goto_tab 0";
    };
    extraConfig = ''
      map --new-mode passthrough --on-unknown passthrough ctrl+shift+space
      map --mode passthrough ctrl+shift+space pop_keyboard_mode
    '';
  };
  programs.rio = {
    enable = true;
    package = nixpkgs-unstable.legacyPackages.${pkgs.system}.rio;
    settings = {
      theme = "GruvboxDark";
      renderer = {
        performance = "High";
        backend = "Automatic";
        disable-renderer-when-unfocused = false;
        target-fps = 144;
      };
      fonts = {
        family = "SauceCodePro Nerd Font Mono";
        size = 21;
      };
    };
  };

  # allow homemanager fonts
  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true; # not finished if system package completion is wanted (look at home manager documentation)
    autocd = true;
    history.save = 1000;
    history.size = 1000;
    initExtraFirst = ''
      ZSH_DISABLE_COMPFIX=true
    '';
    initExtra = ''
      setopt extended_glob

      bindkey 'kj' vi-cmd-mode

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      function open {
        for i
            do (xdg-open "$i" > /dev/null 2> /dev/null &)
        done
      }
    '';
    shellAliases = {
      "bat" = "bat --theme gruvbox-dark";
      "tree" = "tree -C";
      "tt" = "taskwarrior-tui";
      "cp" = "cp --reflink=auto";
      "cd" = "z";
      "ls" = "eza";
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
        "zoxide"
      ];
    };
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
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
      "image/png" = [ "feh.desktop" ];
    };
  };

  # Hyprland
  services.hyprpaper = {
    enable = false;
    settings = {
      preload = "${wallpaper}";
      wallpaper = ",${wallpaper}";
    };
  };

  # GnuPG
  programs.gpg = {
    enable = true;
  };
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # emails
  accounts.email.accounts = {
    #"protonmail" = {
    #  address = "m.toepperwien@protonmail.com";
    #  userName = "m.toepperwien@protonmail.com";
    #  primary = true;
    #  realName = "Jan Malte Töpperwien";
    #  thunderbird.enable = true;
    #  neomutt.enable = true;
    #  passwordCommand = "pass protonmail";
    #  smtp.tls.enable = true;
    #  smtp.tls.useStartTls = true;
    #};
    "university" = let
      mailboxFolders = [ "Inbox" "Sent" "Archive" ];
    in {
      address = "m.toepperwien@stud.uni-hannover.de";
      userName = "m.toepperwien@stud.uni-hannover.de";
      realName = "Jan Malte Töpperwien";
      imap.host = "mail.stud.uni-hannover.de";
      mbsync = {
        enable = true;
        create = "maildir";
      };
      msmtp.enable = true;
      notmuch.enable = true;
      smtp = {
        host = "smtp.uni-hannover.de";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };
      neomutt = {
        enable = true;
        extraMailboxes = mailboxFolders;
      };
      passwordCommand = "pass unimail";
      primary = true;
    };
    "gmail" = {
      address = "m.toepperwien@gmail.com";
      userName = "m.toepperwien@gmail.com";
      realName = "Jan Malte Töpperwien";
      neomutt.enable = true;
      passwordCommand = "pass gmail";
      imap.host = "imap.gmail.com";
      smtp.host = "smtp.gmail.com";
      smtp.tls.enable = true;
      smtp.tls.useStartTls = false;
      mbsync = {
        enable = true;
        create = "maildir";
      };
      msmtp.enable = true;
      notmuch.enable = true;
   };
  };
  programs.neomutt = {
    enable = true;
    vimKeys = true;
    extraConfig = ''
      set mail_check_stats

      # Group reply
      bind index,pager R group-reply

      # Archive messages with 'A', applies to tagged emails if present and else to current email
      macro index A ":set confirmappend=no delete=yes<enter><tag-prefix><save-message>=Archive<enter>:set confirmappend=yes delete=ask-yes<enter>"

      bind index <Return> display-message

      # gruvbox theme
      source ${neomutt_gruvboxtheme}/colors-gruvbox-shuber.muttrc
      source ${neomutt_gruvboxtheme}/colors-gruvbox-shuber-extended.muttrc
    '';
  };
  programs.mbsync.enable = true;
  services.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "mbsync --all";
    };
  };

}
