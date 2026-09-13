---
name: brainstorm
description: Only use this skill when the user explicitly invokes or asks for it. This is an interactive skill that requires the user to be in the loop at all times.
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs through natural collaborative dialogue. This skill is meant to be used interactively with the user in the loop — always ask questions, never make assumptions.

Start by understanding the current project context, then use the `question` tool (or AskUserQuestion) to ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

Complete these items in order, always staying in an interactive loop with the user:

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — use the `question` tool, one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to their complexity, get user approval after each section
5. **Iterate based on feedback** — go back to questions or approaches as needed

## Process Flow

This skill is always used interactively with the user in the loop:

1. **Explore** → Understand current project context
2. **Question** → Use `question` tool to ask clarifying questions one at a time
3. **Propose** → Present 2-3 approaches with trade-offs
4. **Design** → Present design sections and get approval
5. **Iterate** → Revise based on user feedback

Stay in the interactive loop until the user is satisfied with the design. Do NOT proceed to implementation without explicit user direction.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Use the `question` tool to ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Go back and clarify if something doesn't make sense

**Stay interactive:**
- This skill is meant to be a back-and-forth conversation
- The user will guide when they're ready to move forward
- Don't create artifacts or plans unless explicitly asked

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **Be flexible** - Go back and clarify when something doesn't make sense
