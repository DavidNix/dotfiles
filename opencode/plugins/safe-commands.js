// Safe Commands Plugin - Blocks dangerous bash commands
// Blocks: terraform apply, env, any command containing .env, .envrc, .vault-password, printenv

export const SafeCommandsPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") {
        return;
      }

      const command = output.args.command || "";
      const isGitPush = /\bgit\s+push\b/i.test(command);

      // Block terraform apply (any variant)
      if (/terraform\s+apply/i.test(command)) {
        throw new Error("terraform apply commands are blocked because they can make destructive infrastructure changes that are difficult to reverse. The AI agent is not permitted to modify live infrastructure automatically.");
      }

      // Block any command containing .env, .envrc, or .vault-password
      if (command.includes(".env") || command.includes(".envrc") || command.includes(".vault-password")) {
        throw new Error("Access denied: Commands containing '.env', '.envrc', or '.vault-password' are blocked because these files typically contain sensitive credentials, API keys, passwords, or other secrets that should never be exposed or manipulated by AI agents.");
      }

      // Block all printenv commands
      if (/\bprintenv\b/i.test(command)) {
        throw new Error("printenv commands are blocked because they can expose sensitive environment variables including API keys, credentials, and other secrets that should not be visible to AI agents.");
      }

      // Block exact 'env' command only
      if (/^\s*env\s*$/i.test(command) || /^\s*env\s+/.test(command)) {
        throw new Error("env command is blocked because it can display all environment variables including sensitive secrets like API keys, credentials, and configuration values that should not be exposed to AI agents.");
      }

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
