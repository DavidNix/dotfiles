// Safe Commands Plugin - Blocks dangerous bash commands
// Blocks dangerous shell commands, secret access, and destructive macOS operations.

export const SafeCommandsPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") {
        return;
      }

      const command = output.args.command || "";
      const isGitPush = /\bgit\s+push\b/i.test(command);

      const block = (pattern, message) => {
        if (pattern.test(command)) {
          throw new Error(message);
        }
      };

      const secretPatterns = [
        /\.ssh\//i,
        /\b(?:id_rsa|id_ed25519)\b/i,
        /\.(?:pem|key|p12)\b/i,
        /\.aws\/credentials\b/i,
        /\.npmrc\b/i,
        /\.netrc\b/i,
        /\.kube\/config\b/i,
        /\.docker\/config\.json\b/i,
        /\.config\/gh\/hosts\.yml\b/i,
        /\.gnupg\//i,
        /\.vault-token\b/i,
      ];

      // Block terraform apply (any variant)
      if (/terraform\s+apply/i.test(command)) {
        throw new Error("terraform apply commands are blocked because they can make destructive infrastructure changes that are difficult to reverse. The AI agent is not permitted to modify live infrastructure automatically.");
      }

      // Block any command containing .env, .envrc, or .vault-password
      if (command.includes(".env") || command.includes(".envrc") || command.includes(".vault-password")) {
        throw new Error("Access denied: Commands containing '.env', '.envrc', or '.vault-password' are blocked because these files typically contain sensitive credentials, API keys, passwords, or other secrets that should never be exposed or manipulated by AI agents.");
      }

      // Block common secret-bearing files and directories
      if (secretPatterns.some((pattern) => pattern.test(command))) {
        throw new Error("Access denied: Commands referencing SSH keys, cloud credentials, package tokens, kube configs, Docker auth, GitHub auth, GPG data, or Vault tokens are blocked because they can expose sensitive secrets.");
      }

      // Block all printenv commands
      if (/\bprintenv\b/i.test(command)) {
        throw new Error("printenv commands are blocked because they can expose sensitive environment variables including API keys, credentials, and other secrets that should not be visible to AI agents.");
      }

      // Block exact 'env' command only
      if (/^\s*env\s*$/i.test(command) || /^\s*env\s+/.test(command)) {
        throw new Error("env command is blocked because it can display all environment variables including sensitive secrets like API keys, credentials, and configuration values that should not be exposed to AI agents.");
      }

      // Block other broad environment dumping commands
      block(/^\s*(?:set|export|typeset)\s*$/i, "set/export/typeset without arguments are blocked because they can expose sensitive shell variables and environment values.");
      block(/\bdeclare\s+-p\b/i, "declare -p is blocked because it can expose sensitive shell variables and environment values.");
      block(/\blaunchctl\s+getenv\b/i, "launchctl getenv is blocked because it can expose sensitive macOS session environment values.");

      // Block privilege escalation
      block(/\b(?:sudo|su)\b/i, "sudo and su are blocked because AI agents are not permitted to escalate privileges or run commands as another user.");

      // Block destructive git operations
      block(/\bgit\s+reset\b[^;&|]*\s--hard\b/i, "git reset --hard is blocked because it irreversibly discards local work.");
      if (/\bgit\s+clean\b/i.test(command) && !/(^|\s)(?:-[A-Za-z]*n[A-Za-z]*|--dry-run)(\s|$)/i.test(command)) {
        throw new Error("git clean without -n/--dry-run is blocked because it deletes untracked files.");
      }
      block(/\bgit\s+checkout\b[^;&|]*\s--(?:\s|$)/i, "git checkout -- is blocked because it can discard local file changes.");
      block(/\bgit\s+restore\b[^;&|]*(?:\s\.|\s--worktree\b|\s--staged\s+\.)/i, "broad git restore operations are blocked because they can discard local file changes.");
      block(/\bgit\s+push\b[^;&|]*\s(?:--delete|-d)\b/i, "git push --delete is blocked because it deletes remote branches.");
      block(/\bgit\s+push\b[^;&|]*\s:[^\s]+/i, "git push ref deletion syntax is blocked because it deletes remote branches.");
      block(/\bgit\s+branch\b[^;&|]*\s-D\b/i, "git branch -D is blocked because it force-deletes local branches.");

      // Block broad destructive filesystem operations
      block(/\brm\s+[^;&|]*(?:-[^\s]*r[^\s]*f|-[^\s]*f[^\s]*r)\s+(?:--\s+)?(?:\/|~|\$HOME|\$\{HOME\}|\.|\.\.|\*|\.\/\*)($|\s)/i, "broad rm -rf commands are blocked because they can cause irreversible data loss.");
      block(/\bfind\b[^;&|]*\s-delete\b/i, "find -delete is blocked because it can remove many files recursively.");
      block(/\brsync\b[^;&|]*\s--delete\b/i, "rsync --delete is blocked because it can mirror-delete files from the destination.");
      block(/\b(?:chmod|chown)\b[^;&|]*\s-R\b[^;&|]*(?:\s\/|\s~|\s\$HOME|\s\$\{HOME\}|\s\.|\s\.\.)($|\s)/i, "broad recursive chmod/chown commands are blocked because they can damage file ownership or permissions.");
      block(/\bdd\b/i, "dd is blocked because it can overwrite disks or files with little protection.");

      // Block destructive or sensitive macOS system commands
      block(/\bdiskutil\s+(?:eraseDisk|eraseVolume|partitionDisk|apfs\s+delete\w*)\b/i, "destructive diskutil operations are blocked because they can erase or repartition disks and APFS volumes.");
      block(/\basr\s+restore\b/i, "asr restore is blocked because it can erase and restore disk volumes.");
      block(/\bbless\b/i, "bless is blocked because it changes macOS startup disk and boot settings.");
      block(/\bsecurity\s+(?:find-generic-password|find-internet-password|dump-keychain|export)\b/i, "security commands that read or export keychain secrets are blocked.");
      block(/\bpbpaste\b/i, "pbpaste is blocked because clipboard contents often contain passwords, tokens, or other sensitive data.");
      block(/\blaunchctl\s+(?:bootout|bootstrap|load|unload|kickstart|setenv|unsetenv)\b/i, "launchctl service and environment mutation commands are blocked because they can alter macOS services or session state.");
      block(/\b(?:dscl|sysadminctl)\b/i, "macOS account management commands are blocked because they can modify users or authentication state.");
      block(/\bprofiles\s+(?:install|remove)\b/i, "profiles install/remove is blocked because it can change macOS configuration profiles.");
      block(/\bspctl\s+--master-disable\b/i, "spctl --master-disable is blocked because it disables Gatekeeper.");
      block(/\btccutil\s+reset\b/i, "tccutil reset is blocked because it resets macOS privacy permissions.");

      // Block force pushes
      if (isGitPush && /(^|\s)(-f|--force|--force-with-lease)(\s|$)/i.test(command)) {
        throw new Error("force pushes are blocked because they can overwrite remote commits, destroy work by other developers, and cause irreversible data loss in the git history.");
      }

      // Block pushes to main or master
      if (
        isGitPush &&
        /(\s|:)(main|master)(?=\s|$)/i.test(command)
      ) {
        throw new Error("git push to main or master is blocked because pushing directly to the default branch can bypass code review processes, introduce bugs to production code, and violates the workflow of using feature branches and pull requests.");
      }
    },
  };
};
