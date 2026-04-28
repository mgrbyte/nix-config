{ config, pkgs, lib, name, user, homeDir, ... }:

let
  personalEmail = "mgrbyte@member.fsf.org";
  workEmail = "m.russell@bangor.ac.uk";
in {
  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      "*.swp"
      "*~"
      "#*#"
      ".#*"
      ".dir-locals.el"
      ".idea/**/aws.xml"
      ".idea/**/contentModel.xml"
      ".idea/**/dataSources.ids"
      ".idea/**/dataSources.local.xml"
      ".idea/**/dataSources/"
      ".idea/**/dbnavigator.xml"
      ".idea/**/dictionaries"
      ".idea/**/dynamic.xml"
      ".idea/**/gradle.xml"
      ".idea/**/libraries"
      ".idea/**/mongoSettings.xml"
      ".idea/**/shelf"
      ".idea/**/sonarlint/"
      ".idea/**/sqlDataSources.xml"
      ".idea/**/tasks.xml"
      ".idea/**/uiDesigner.xml"
      ".idea/**/usage.statistics.xml"
      ".idea/**/workspace.xml"
      ".idea/httpRequests"
      ".idea/replstate.xml"
      ".idea/sonarlint.xml"
      ".idea_modules/"
      "*.iws"
      "out/"
      "atlassian-ide-plugin.xml"
      "com_crashlytics_export_strings.xml"
      "crashlytics-build.properties"
      "crashlytics.properties"
      "fabric.properties"
      "http-client.private.env.json"
      ".idea/caches/build_file_checksums.ser"
      ".vscode/*"
      "!.vscode/*.code-snippets"
      "!.vscode/extensions.json"
      "!.vscode/launch.json"
      "!.vscode/settings.json"
      "!.vscode/tasks.json"
      "*.vsix"
    ];
    settings = {
      user = {
        name = name;
        email = personalEmail;
        signingkey = "${homeDir}/.ssh/id_mgrbyte_github.pub";
      };
      alias = {
        bcu = "!git fetch -p && git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -D";
        br = "branch";
        cb = "checkout -b";
        chp = "cherry-pick";
        ci = "commit";
        co = "checkout";
        db = "branch -D";
        df = "diff";
        diff-all = "difftool -y -d";
        llog = "log --oneline --graph";
        log-unpushed = "log --no-merges";
        lp = "log -p";
        mnf = "merge --no-ff";
        rh = "reset --hard";
        rhh = "reset --hard HEAD";
        rn = "branch -m";
        rpo = "remote prune origin";
        sl = "stash list";
        st = "status -uno";
        whatadded = "log --diff-filter=A";
      };
      init.defaultBranch = "main";
      push.default = "simple";
      core = {
        editor = "emacsclient -t";
        autocrlf = "input";
      };
      # Credential helper for Techiaith storfa
      "credential \"https://storfa.techiaith.cymru\"" = {
        username = "oauth";
        helper = "netrc";
      };
      # SSH commit signing (replacing GPG)
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${homeDir}/.ssh/allowed_signers";
      pull.rebase = true;
      rebase.autoStash = true;
      # Work directories override email and signing key; all other paths use personal defaults above
      "includeIf \"gitdir:${homeDir}/gitlab/\"" = {
        path = "${homeDir}/.config/git/work.inc";
      };
      "includeIf \"gitdir:${homeDir}/github/techiaith/\"" = {
        path = "${homeDir}/.config/git/work.inc";
      };
      "includeIf \"gitdir:${homeDir}/github/huggingface/techiaith/\"" = {
        path = "${homeDir}/.config/git/work.inc";
      };
    };
  };

  # Git config include for work directories (overrides global personal defaults)
  home.file.".config/git/work.inc".text = ''
    [user]
      email = ${workEmail}
      signingkey = ${homeDir}/.ssh/id_ed25519_mtr21pqh.pub
  '';
}
