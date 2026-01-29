---
name: dependency-analysis
description: Breaking change detection patterns and dependency safety analysis for PR reviews
---

# Dependency Analysis Skill

Provides expertise in detecting breaking changes, analyzing dependency
safety, and assessing upgrade risks.

## Purpose

This skill equips agents with patterns and techniques for:

- Detecting breaking changes in changelogs
- Analyzing semantic versioning implications
- Identifying risky dependency updates
- Scoring upgrade risk levels

## When to Use

Use this skill when:

- Analyzing dependency update PRs (Dependabot, Renovate, etc.)
- Reviewing semantic version changes
- Assessing breaking change risk
- Making merge/skip decisions for automated dependency updates

## Breaking Change Detection Strategy

### Four-Layer Analysis

#### Layer 1: Changelog Analysis

Parse release notes and changelogs for explicit breaking change indicators:

- Section headers indicating breaking changes (e.g., "Breaking Changes",
  "Migration Guide", "Upgrading")
- Version jump patterns with substantial changes
- Common section names: breaking changes, features, deprecations, removals,
  fixes, security

#### Layer 2: Keyword Analysis

Search for breaking change keywords in context, categorized by severity:

- High severity indicators: explicit breaking change declarations, backwards
  incompatibility statements, migration requirements
- Medium severity indicators: removals, deprecations, end-of-support notices,
  API changes
- Low severity indicators: default changes, renames, relocations

#### Layer 3: Semantic Versioning

Apply semver rules to classify risk:

- MAJOR (X.0.0): Incompatible API changes - HIGH RISK
- MINOR (0.X.0): Backwards compatible features - MEDIUM RISK
- PATCH (0.0.X): Backwards compatible fixes - LOW RISK

#### Layer 4: Community Signals

Check for warning signs:

- High issue activity around release date
- Multiple "breaking" mentions in discussions
- Migration guide present (implies breaking changes)

## Risk Scoring Rubric

Combine signals into risk score:

**HIGH RISK (Skip - Manual Review Required):**

- MAJOR version bump
- Explicit "BREAKING CHANGE" in changelog
- Migration guide present
- Removed APIs used in codebase

**MEDIUM RISK (Extra Scrutiny):**

- MINOR version with "removed"/"deprecated" keywords
- Substantial changelog with multiple changes
- Community reports of issues

**LOW RISK (Safe to Merge):**

- PATCH version bump
- Security fix with no breaking changes
- Minor bugfixes only
- Clean changelog

## Changelog Parsing

Identify standard changelog sections to categorize changes:

- Breaking changes and migration guides
- New features and additions
- Changes and updates
- Deprecations
- Removals
- Bug fixes and patches
- Security updates

## Output Format

Structure findings as a safety report:

- Risk level (low/medium/high)
- Semver classification
- Breaking changes detected (with evidence from changelog)
- Recommendation (merge/skip/manual-review)
- Reasoning with supporting evidence
- Changelog excerpts showing key findings
- Keywords found that triggered classification

## Example Usage

```markdown
Agent using this skill:

1. Fetch changelog for dependency update (from GitHub releases,
   CHANGELOG.md, or release notes)
2. Apply Layer 1: Parse changelog structure and identify sections
3. Apply Layer 2: Search for breaking change indicators using
   keyword analysis
4. Apply Layer 3: Classify semantic version change type
5. Apply Layer 4: Check community signals (issue activity,
   discussion mentions)
6. Score risk using rubric combining all layers
7. Generate structured safety report with evidence and recommendation
```

## Key Principles

- **Evidence-based**: Always cite specific changelog excerpts or version
  info supporting the risk assessment
- **Layered approach**: Combine multiple signals rather than relying on a
  single indicator
- **Context matters**: Keywords like "removed" need surrounding context to
  determine severity
- **Graceful degradation**: If changelog unavailable, fall back to semver
  analysis and community signals
