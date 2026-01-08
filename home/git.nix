{ config, pkgs, lib, name, email, user, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      "*.swp"
      "*~"
      ".dir-locals.el"
      ".serena/"
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
        email = email;
        signingkey = "AC61E672F0A921B7";
      };
      alias = {
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
      commit.gpgsign = true;
      tag.gpgsign = true;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      (if isLinux then "/home/${user}/.ssh/config_external" else "/Users/${user}/.ssh/config_external")
    ];
    matchBlocks = {
      "*" = {
        sendEnv = [ "LANG" "LC_*" ];
        hashKnownHosts = true;
      };
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (if isLinux then "/home/${user}/.ssh/id_mtr21pqh_github" else "/Users/${user}/.ssh/id_mtr21pqh_github")
        ];
      };
    };
  };
}
