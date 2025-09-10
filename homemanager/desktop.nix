{
  config,
  pkgs,
  nixpkgs-unstable,
  lib,
  ...
}:
let
  lua-packages =
    p: with p; [
      luarocks
    ];
  python-packages =
    p: with p; [
      pandas
      numpy
      pynvim
      ipython
      matplotlib
      plotly
      scikit-learn
      scipy
      kaleido
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
      # for markdown rendering in nvim
      pylatexenc
    ];
  neomutt_gruvboxtheme = pkgs.callPackage ./neomutt_gruvboxtheme.nix { };
  wallpaper = ./config/hypr/wallpaper/gruvbox-dark-blue.png;
  aspell-dicts =
    p: with p; [
      en
      en-computers
      en-science
      de
    ];
  keepass-database = "~/drive/Passwords.kdbx";
in
{
  imports = [ ./devel.nix ];

  home.packages =
    with pkgs;
    [
      alacritty
      warp-terminal
      element-desktop
      discord
      fnott
      mpv
      steam-run
      obsidian
      zotero
      sqlite
      # neovim and plugin dependencies {{{
      neovim-remote
      luajitPackages.jsregexp # dependency of luasnip neovim plugin
      tree-sitter
      jq
      inkscape
      imv
      nodejs
      nodePackages.npm
      wget
      curl
      lua-language-server
      clang-tools
      pyright
      nixd
      nixfmt-rfc-style
      cairo
      # }}} neovim and plugin dependencies
      lazygit
      # Latex
      texlive.combined.scheme-full
      (aspellWithDicts aspell-dicts)
      qutebrowser
      sway
      hyprland
      slurp
      grim
      playerctl # sway audio button bindings
      waybar
      font-awesome # needed for waybar icons
      ungoogled-chromium
      google-chrome
      nautilus
      (python3.withPackages python-packages)
      uv
      (lua5_1.withPackages lua-packages)
      # poetry ignore for now due to dependency missing
      virtualenv
      ripgrep
      pdfgrep
      zathura
      wl-clipboard
      nerd-fonts.sauce-code-pro
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      xdg-utils
      unzip
      # gnupg
      gnupg
      pinentry-curses
      pass
      gcr  # Provides org.gnome.keyring.SystemPrompter

      libreoffice-fresh
      grim
      pdftk
      pandoc
      xournalpp
      timewarrior
      taskwarrior3
      taskwarrior-tui
      pdfpc
      qmk
      amdgpu_top
    ]
    ++ (with nixpkgs-unstable.legacyPackages.${pkgs.system}; [
      neovim-qt
      neovide
    ]);

  home.sessionVariables = {
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      colors = {
        background = "282828ff";
        text = "d4be98ff";
        match = "e78a4eff";
        selection = "45403dff";
        selection-match = "e78a4eff";
        selection-text = "d4be98ff";
        border = "a9b665ff";
      };
    };
  };
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    git = true;
    colors = "auto";
  };

  programs.git = {
    enable = true;
    userName = "Jan Malte Töpperwien";
    userEmail = "m.toepperwien@protonmail.com";
    signing = {
      key = "0x4AD13F07CA26E224!";
      signByDefault = true;
    };
    extraConfig = {
      core = {
        excludesfile = "/home/mtoepperwien/.config/git/ignore";
      };
      "filter \"sqlite3\"" = {
        clean = "f() { tmpfile=$(mktemp); cat - > $tmpfile; sqlite3 $tmpfile .dump; rm $tmpfile; }; f";
        smudge = "f() { tmpfile=$(mktemp); sqlite3 $tmpfile; cat $tmpfile; rm $tmpfile; }; f";
        required = "true";
      };
    };
    delta.enable = true;
    #riff.enable = true;
    #gitui.enable = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
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
    #package = nixpkgs-unstable.legacyPackages.${pkgs.system}.neovim-unwrapped;
    extraLuaPackages = ps: [
      ps.magick
      ps.luarocks
    ];
    extraPackages = [ pkgs.imagemagick pkgs.pyright pkgs.gcc_multi pkgs.nodejs_24 ];
    extraPython3Packages =
      ps: with ps; [
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
        pylatexenc
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
    shellIntegration.enableZshIntegration = true;
    shellIntegration.enableBashIntegration = true;
    font = {
      name = "SauceCodePro Nerd Font Mono";
      size = 15;
    };
    themeFile = "GruvboxMaterialDarkMedium";
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = 0;
      disable_ligatures = "always";
      repaint_delay = 7; # this is approx 144hz
      enable_audio_bell = false;
      notify_on_cmd_finish = "unfocused 60.0";
    };
    keybindings = {
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

  # allow homemanager fonts
  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true; # not finished if system package completion is wanted (look at home manager documentation)
    autocd = true;
    history.save = 1000;
    history.size = 1000;
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        ZSH_DISABLE_COMPFIX=true
        skip_global_compinit=1
      '')
      (lib.mkAfter ''
        setopt extended_glob

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        function open {
          for i
              do (xdg-open "$i" > /dev/null 2> /dev/null &)
          done
        }
      '')
      ];
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
        "vi-mode"
        "git"
        "zoxide"
      ];
    };
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  services.fnott = {
    enable = true;
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.fnott ];
  };

  programs.feh = {
    enable = true;
  };

  # default applications
  xdg.mime.enable = true;
  xdg.configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable { force = true; };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      "x-scheme-handler/steam" = [ "steam.desktop" ];
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
    scdaemonSettings = {
      disable-ccid = true;
    };
  };


  # emails
  programs.thunderbird = {
    enable = true;
    profiles = {
      "main" = {
        isDefault = true;
      };
    };
  };
  accounts.email.accounts = {
    "protonmail" = {
      address = "m.toepperwien@protonmail.com";
      userName = "m.toepperwien@protonmail.com";
      primary = true;
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
      neomutt.enable = true;
      passwordCommand = "pass protonmail";
      smtp = {
        host = "127.0.0.1";
        port = 1025;
        tls.enable = true;
        tls.useStartTls = true;
      };
      imap = {
        host = "127.0.0.1";
        port = 1143;
        tls.enable = true;
        tls.useStartTls = true;
      };
    };
    "university" =
      let
        mailboxFolders = [
          "Inbox"
          "Sent"
          "Archive"
        ];
      in
      {
        address = "m.toepperwien@stud.uni-hannover.de";
        userName = "m.toepperwien@stud.uni-hannover.de";
        realName = "Jan Malte Töpperwien";
        mbsync = {
          enable = true;
          create = "maildir";
        };
        msmtp.enable = true;
        smtp = {
          host = "smtp.uni-hannover.de";
          port = 587;
          tls.enable = true;
          tls.useStartTls = true;
        };
        imap = {
          host = "mail.uni-hannover.de";
          port = 993;
          tls.enable = true;
        };
        neomutt = {
          enable = true;
          extraMailboxes = mailboxFolders;
        };
        thunderbird.enable = true;
        passwordCommand = "keepassxc-cli clip ${keepass-database} 'LUH Mail' -y 2:$(${pkgs.yubikey-manager}/bin/ykman list -s)";
      };
    "gmail" = {
      address = "m.toepperwien@gmail.com";
      userName = "m.toepperwien@gmail.com";
      realName = "Jan Malte Töpperwien";
      thunderbird.enable = true;
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.enable = true;
        tls.useStartTls = true;
      };
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
}
