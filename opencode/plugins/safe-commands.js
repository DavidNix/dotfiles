// Safe Commands Plugin - Blocks dangerous bash commands
// Blocks: terraform apply, env, any command containing .env, .envrc, .vault-password, printenv

export const SafeCommandsPlugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") {
        return;
      }

      const command = output.args.command || "";

      // Block terraform apply (any variant)
      if (/terraform\s+apply/i.test(command)) {
        throw new Error("terraform apply commands are blocked");
      }

      // Block any command containing .env, .envrc, or .vault-password
      if (command.includes(".env") || command.includes(".envrc") || command.includes(".vault-password")) {
        throw new Error("Access denied");
      }

      // Block all printenv commands
      if (/\bprintenv\b/i.test(command)) {
        throw new Error("printenv commands are blocked");
      }

      // Block exact 'env' command only
      if (/^\s*env\s*$/i.test(command) || /^\s*env\s+/.test(command)) {
        throw new Error("env command is blocked");
      }
    },
  };
};
