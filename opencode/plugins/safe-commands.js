// Safe Commands Plugin - Blocks dangerous bash commands
// Blocks dangerous shell commands, secret access, and destructive macOS operations.

const secretPatterns = [
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

const simpleShellWords = (segment) => (segment.match(/"[^"]*"|'[^']*'|\S+/g) || [])
  .map((word) => word.replace(/^(["'])(.*)\1$/, "$2"));

const commandSegments = (command) => command
  .split(/(?:&&|\|\||[;|])/)
  .map((segment) => simpleShellWords(segment.trim()))
  .filter((words) => words.length > 0)
  .map((words) => {
    const parsedWords = [...words];
    parsedWords[0] = parsedWords[0].replace(/^\(+/, "");
    parsedWords[parsedWords.length - 1] = parsedWords[parsedWords.length - 1].replace(/\)+$/, "");

    while (parsedWords.length > 0) {
      if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(parsedWords[0])) {
        parsedWords.shift();
        continue;
      }

      if (/^(?:builtin|command|noglob|time)$/i.test(parsedWords[0])) {
        parsedWords.shift();
        continue;
      }

      break;
    }

    const name = (parsedWords[0] || "").split("/").pop().toLowerCase();
    return { name, args: parsedWords.slice(1) };
  });

const hasOption = (args, option) => args.some((arg) => arg === option || arg.startsWith(`${option}=`));

const cargoSubcommand = (args) => {
  const optionsWithValues = new Set(["--color", "--config", "--explain", "-c", "-z"]);
  let index = args[0]?.startsWith("+") ? 1 : 0;

  while (index < args.length) {
    const arg = args[index].toLowerCase();
    if (optionsWithValues.has(arg)) {
      index += 2;
      continue;
    }

    if (arg.startsWith("-")) {
      index += 1;
      continue;
    }

    return arg;
  }

  return "";
};

const unsafeGoCommandReason = ({ name, args }) => {
  if (name !== "go") {
    return;
  }

  const subcommand = (args[0] || "").toLowerCase();
  const subcommandArgs = args.slice(1);

  if (subcommand === "install") {
    return "go install is blocked because it writes binaries and can fetch remote code.";
  }

  if (subcommand === "env" && (hasOption(subcommandArgs, "-w") || hasOption(subcommandArgs, "-u"))) {
    return "go env -w/-u is blocked because it mutates global Go environment settings.";
  }

  if (["test", "build", "vet", "list"].includes(subcommand) && hasOption(subcommandArgs, "-toolexec")) {
    return "go -toolexec is blocked because it runs toolchain commands through an arbitrary executable.";
  }

  if (subcommand === "test" && hasOption(subcommandArgs, "-exec")) {
    return "go test -exec is blocked because it runs test binaries through an arbitrary executable.";
  }

  if (subcommand === "vet" && hasOption(subcommandArgs, "-vettool")) {
    return "go vet -vettool is blocked because it executes a custom analyzer binary.";
  }
};

const unsafeCargoCommandReason = ({ name, args }) => {
  if (name !== "cargo") {
    return;
  }

  const subcommand = cargoSubcommand(args);
  if (["install", "uninstall"].includes(subcommand)) {
    return "cargo install/uninstall is blocked because it changes globally installed binaries and can fetch remote code.";
  }

  if (["login", "logout"].includes(subcommand)) {
    return "cargo login/logout is blocked because it changes stored registry credentials.";
  }

  if (subcommand === "owner") {
    return "cargo owner is blocked because it changes crate ownership on a remote registry.";
  }

  if (subcommand === "publish") {
    return "cargo publish is blocked because it uploads crates to a remote registry.";
  }

  if (subcommand === "yank") {
    return "cargo yank is blocked because it changes crate availability on a remote registry.";
  }
};

export const isGitPushCommand = (command) => commandSegments(command)
  .some(({ name, args }) => name === "git" && (args[0] || "").toLowerCase() === "push");

export const isUnsafeGoCommand = (command) => commandSegments(command)
  .some((segment) => Boolean(unsafeGoCommandReason(segment)));

export const getUnsafeCommandReason = (command) => {
  if (isGitPushCommand(command)) {
    return "git push commands are blocked because AI agents are not permitted to publish local commits or modify remote refs.";
  }

  if (/terraform\s+apply/i.test(command)) {
    return "terraform apply commands are blocked because they can make destructive infrastructure changes that are difficult to reverse. The AI agent is not permitted to modify live infrastructure automatically.";
  }

  if (command.includes(".env") || command.includes(".envrc") || command.includes(".vault-password")) {
    return "Access denied: Commands containing '.env', '.envrc', or '.vault-password' are blocked because these files typically contain sensitive credentials, API keys, passwords, or other secrets that should never be exposed or manipulated by AI agents.";
  }

  if (secretPatterns.some((pattern) => pattern.test(command))) {
    return "Access denied: Commands referencing cloud credentials, package tokens, kube configs, Docker auth, GitHub auth, GPG data, or Vault tokens are blocked because they can expose sensitive secrets.";
  }

  for (const segment of commandSegments(command)) {
    const reason = unsafeGoCommandReason(segment) || unsafeCargoCommandReason(segment);
    if (reason) {
      return reason;
    }
  }

  const blockedPatterns = [
    [/\bprintenv\b/i, "printenv commands are blocked because they can expose sensitive environment variables including API keys, credentials, and other secrets that should not be visible to AI agents."],
    [/^\s*env\s*$/i, "env command is blocked because it can display all environment variables including sensitive secrets like API keys, credentials, and configuration values that should not be exposed to AI agents."],
    [/^\s*env\s+/i, "env command is blocked because it can display all environment variables including sensitive secrets like API keys, credentials, and configuration values that should not be exposed to AI agents."],
    [/^\s*(?:set|export|typeset)\s*$/i, "set/export/typeset without arguments are blocked because they can expose sensitive shell variables and environment values."],
    [/\bdeclare\s+-p\b/i, "declare -p is blocked because it can expose sensitive shell variables and environment values."],
    [/\blaunchctl\s+getenv\b/i, "launchctl getenv is blocked because it can expose sensitive macOS session environment values."],
    [/\b(?:sudo|su)\b/i, "sudo and su are blocked because AI agents are not permitted to escalate privileges or run commands as another user."],
    [/\bgit\s+reset\b[^;&|]*\s--hard\b/i, "git reset --hard is blocked because it irreversibly discards local work."],
    [/\bgit\s+checkout\b[^;&|]*\s--(?:\s|$)/i, "git checkout -- is blocked because it can discard local file changes."],
    [/\bgit\s+restore\b[^;&|]*(?:\s\.|\s--worktree\b|\s--staged\s+\.)/i, "broad git restore operations are blocked because they can discard local file changes."],
    [/\bgit\s+branch\b[^;&|]*\s-D\b/i, "git branch -D is blocked because it force-deletes local branches."],
    [/\brm\s+[^;&|]*(?:-[^\s]*r[^\s]*f|-[^\s]*f[^\s]*r)\s+(?:--\s+)?(?:\/|~|\$HOME|\$\{HOME\}|\.|\.\.|\*|\.\/\*)($|\s)/i, "broad rm -rf commands are blocked because they can cause irreversible data loss."],
    [/\bfind\b[^;&|]*\s-delete\b/i, "find -delete is blocked because it can remove many files recursively."],
    [/\brsync\b[^;&|]*\s--delete\b/i, "rsync --delete is blocked because it can mirror-delete files from the destination."],
    [/\b(?:chmod|chown)\b[^;&|]*\s-R\b[^;&|]*(?:\s\/|\s~|\s\$HOME|\s\$\{HOME\}|\s\.|\s\.\.)($|\s)/i, "broad recursive chmod/chown commands are blocked because they can damage file ownership or permissions."],
    [/\bdd\b/i, "dd is blocked because it can overwrite disks or files with little protection."],
    [/\bdiskutil\s+(?:eraseDisk|eraseVolume|partitionDisk|apfs\s+delete\w*)\b/i, "destructive diskutil operations are blocked because they can erase or repartition disks and APFS volumes."],
    [/\basr\s+restore\b/i, "asr restore is blocked because it can erase and restore disk volumes."],
    [/\bbless\b/i, "bless is blocked because it changes macOS startup disk and boot settings."],
    [/\bsecurity\s+(?:find-generic-password|find-internet-password|dump-keychain|export)\b/i, "security commands that read or export keychain secrets are blocked."],
    [/\bpbpaste\b/i, "pbpaste is blocked because clipboard contents often contain passwords, tokens, or other sensitive data."],
    [/\blaunchctl\s+(?:bootout|bootstrap|load|unload|kickstart|setenv|unsetenv)\b/i, "launchctl service and environment mutation commands are blocked because they can alter macOS services or session state."],
    [/\b(?:dscl|sysadminctl)\b/i, "macOS account management commands are blocked because they can modify users or authentication state."],
    [/\bprofiles\s+(?:install|remove)\b/i, "profiles install/remove is blocked because it can change macOS configuration profiles."],
    [/\bspctl\s+--master-disable\b/i, "spctl --master-disable is blocked because it disables Gatekeeper."],
    [/\btccutil\s+reset\b/i, "tccutil reset is blocked because it resets macOS privacy permissions."],
  ];

  if (/\bgit\s+clean\b/i.test(command) && !/(^|\s)(?:-[A-Za-z]*n[A-Za-z]*|--dry-run)(\s|$)/i.test(command)) {
    return "git clean without -n/--dry-run is blocked because it deletes untracked files.";
  }

  const blockedPattern = blockedPatterns.find(([pattern]) => pattern.test(command));
  return blockedPattern?.[1];
};

export const validateSafeCommand = (command) => {
  const reason = getUnsafeCommandReason(command || "");
  if (reason) {
    throw new Error(reason);
  }
};

export const SafeCommandsPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") {
        return;
      }

      const command = output.args?.command;
      validateSafeCommand(Array.isArray(command) ? command.join(" ") : typeof command === "string" ? command : "");
    },
  };
};
