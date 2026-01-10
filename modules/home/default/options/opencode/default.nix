# programs.opencode.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.opencode;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    age.secrets = {
      openrouter.rekeyFile = ./openrouter.age;
      zen.rekeyFile = ./zen.age;
    };
    programs.opencode = {
      package = perSystem.llm-agents.opencode;
      settings = {
        autoshare = false;
        autoupdate = false;
        provider = {
          openrouter.options.apiKey = "{file:${config.age.secrets.openrouter.path}}";
          opencode.options.apiKey = "{file:${config.age.secrets.zen.path}}";
        };
      };
      commands.changelog = ''
        # Update Changelog Command

        Update CHANGELOG.md with a new entry for the specified version.
        Usage: /changelog [version] [change-type] [message]
      '';
      commands.commit = ''
        # Commit Command

        Create a git commit with proper message formatting.
        Usage: /commit [message]
      '';
      agents.code-reviewer =
        # markdown
        ''
          # Code Reviewer Agent

          You are a senior software engineer specializing in code reviews.
          Focus on code quality, security, and maintainability.

          ## Guidelines
          - Review for potential bugs and edge cases
          - Check for security vulnerabilities
          - Ensure code follows best practices
          - Suggest improvements for readability and performancej
        '';
      rules =
        # markdown
        ''
          # TypeScript Project Rules

          ## External File Loading

          CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

          Instructions:

          - Do NOT preemptively load all references - use lazy loading based on actual need
          - When loaded, treat content as mandatory instructions that override defaults
          - Follow references recursively when needed

          ## Development Guidelines

          For TypeScript code style and best practices: @docs/typescript-guidelines.md
          For React component architecture and hooks patterns: @docs/react-patterns.md
          For REST API design and error handling: @docs/api-standards.md
          For testing strategies and coverage requirements: @test/testing-guidelines.md

          ## General Guidelines

          Read the following file immediately as it's relevant to all workflows: @rules/general-guidelines.md.
        '';
    };
  };
}
