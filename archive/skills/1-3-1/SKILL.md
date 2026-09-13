---
name: 1-3-1
description: Use when the user asks for a "1-3-1", wants decision options, or needs a concise recommendation to forward. Produces one problem, three options, one recommendation, success criteria, and an action plan.
---

# 1-3-1 Communication Rule

Use this skill to turn ambiguous decisions into concise, forwardable recommendations. The format is intentionally constrained: one problem, three options, one recommendation.

## When to Use

Use this skill when:

- The user explicitly asks for a `1-3-1` response.
- The user asks for options, choices, alternatives, or trade-offs.
- A decision has multiple viable approaches with meaningful trade-offs, such as strategy, process, resourcing, timing, positioning, tooling, rollout, or execution scope.
- The user needs a proposal that can be forwarded to a team, manager, stakeholder, or decision-maker.

Do not use this skill when:

- The question has one obvious answer.
- The user is asking you to debug or diagnose an active issue.
- The user has already chosen an approach and wants execution.
- A direct answer would be more useful than a decision memo.

## Output Structure

Use this exact top-level structure:

```markdown
Problem: [one sentence]

Options:

Option A: [approach name]. [brief description]
Pros: [concise pros]
Cons: [concise cons]

Option B: [approach name]. [brief description]
Pros: [concise pros]
Cons: [concise cons]

Option C: [approach name]. [brief description]
Pros: [concise pros]
Cons: [concise cons]

Recommendation: [pick exactly one option and explain why]

Definition of Done:

- [verifiable outcome]
- [verifiable outcome]
- [verifiable outcome]

Action Plan:

1. [concrete step]
2. [concrete step]
3. [concrete step]
```

## Procedure

### 1. Frame the Problem

Write one sentence that captures the core decision or outcome.

- Focus on the what, not the how.
- Avoid solution details and specific tools unless the user made them central to the decision.
- If the sentence needs `and`, you are probably describing two problems. Narrow it.

### 2. Present Exactly Three Options

Create three distinct, viable approaches labeled `Option A`, `Option B`, and `Option C`.

- Make the options meaningfully different strategies, not slight variations of the same idea.
- Include a brief description, pros, and cons for each option.
- Keep trade-offs concrete: cost, complexity, speed, risk, maintainability, reversibility, user impact, operational burden.
- Do not pad weak options. If there are not three viable options, say that and answer directly instead of forcing the format.

### 3. Recommend One Option

Pick exactly one option.

- Be direct; the user asked for judgment, not neutrality.
- Tie the recommendation to the user's context and priorities.
- Avoid hedging phrases like "it depends" unless immediately followed by a clear recommendation.

### 4. Define Done for the Recommendation

List concrete, verifiable success criteria for the recommended option.

- Use outcomes someone can inspect, test, or measure.
- Align every item with the recommended option.
- Avoid vague criteria like "works well", "is scalable", or "improves UX" unless paired with observable evidence.

### 5. Provide an Action Plan

List concrete steps for the recommended option.

- Include owners, timelines, milestones, tools, or concrete actions when applicable.
- Keep the plan scoped to the recommended option.
- If the user later chooses a different option, revise the Recommendation, Definition of Done, and Action Plan to match that option.

## Verification Checklist

Before responding, check that:

- There is exactly one `Problem:` sentence.
- There are exactly three options: `Option A`, `Option B`, and `Option C`.
- Each option has pros and cons.
- The recommendation picks exactly one option.
- The Definition of Done matches the recommended option.
- The Action Plan matches the recommended option.
- The response is concise enough to forward without heavy editing.

## Example

User: "Give me a 1-3-1 for improving our customer support response times."

Response:

```markdown
Problem: Customer support response times are too slow and need a more reliable operating model.

Options:

Option A: Triage-first support process. Route every inbound request through a daily triage queue with severity labels and clear response targets.
Pros: Fast to implement; improves visibility; clarifies which issues need urgent attention.
Cons: Does not add capacity; depends on consistent triage discipline.

Option B: Dedicated support rotation. Assign one team member per day to own first responses and escalations.
Pros: Clear ownership; reduces context switching for the rest of the team; easier to measure coverage.
Cons: Pulls people away from other work; coverage may still break during peak volume.

Option C: Hire or outsource support coverage. Add dedicated support capacity through a new hire, contractor, or support partner.
Pros: Increases capacity; can extend coverage hours; lets specialists handle repeat issues.
Cons: Highest cost; takes time to onboard; quality control requires management overhead.

Recommendation: Option A. It improves response time quickly without adding cost, and the data from triage will show whether dedicated coverage is actually needed.

Definition of Done:

- All new support requests receive a severity label within one business hour.
- Each severity level has a documented first-response target.
- The team reviews unresolved high-severity requests daily.
- Weekly reporting shows median first-response time and backlog by severity.
- Response time improves for two consecutive weeks without increasing reopen rate.

Action Plan:

1. Define severity levels, first-response targets, and escalation rules.
2. Add required severity labels to the support intake workflow.
3. Assign a daily triage owner responsible for labeling and escalation.
4. Review high-severity and aging requests in a 15-minute daily check-in.
5. Track first-response time, backlog, and reopen rate weekly for one month.
```
