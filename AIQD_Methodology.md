# AIQD Methodology

**Project:** PowerShell Event Sender
**Methodology Adopted:** November 16, 2025
**Version:** 1.0

---

## Overview

The **AIQD Methodology** (Acknowledge, Investigate, Question, Advice, Document) is a structured approach to project development that ensures thorough understanding, research-backed decisions, collaborative refinement, and comprehensive documentation.

This methodology is applied to all significant changes, features, and architectural decisions in the PowerShell Event Sender project.

---

## The AIQD Process

When the user says **"AIQD"** or **"Acknowledge, investigate, question, advice, and document"**, the following process is followed:

### 1. **Acknowledge**

**Purpose:** Demonstrate understanding and clarify the request using precise technical terminology.

**Actions:**
- Restate the goal(s) and sub-goal(s) in your own words
- Use technically accurate and potentially more precise terminology than the initial request
- Identify the current state vs. desired state
- Break down the request into actionable components
- Confirm understanding before proceeding

**Example:**
```
User: "Make the script download from GitHub"

Acknowledge: "I understand you want to transform the deployment model from
a download-first, local-execution approach to a web-hosted, one-liner
remote execution model using Invoke-RestMethod (irm) piped to
Invoke-Expression (iex), similar to the Chris Titus Tech Windows Utility
pattern. This involves hosting the script on GitHub and enabling direct
execution via a single PowerShell command."
```

---

### 2. **Investigate**

**Purpose:** Provide educated, current, and research-backed recommendations.

**Actions:**
- Research beyond existing knowledge
- Browse reputable technical forums, blogs, and documentation
- Search for current best practices (2024-2025)
- Review security considerations and industry standards
- Examine similar implementations (e.g., Chris Titus Tech, other PowerShell tools)
- Gather evidence-based recommendations

**Sources to Consult:**
- GitHub repositories (Chris Titus Tech, Microsoft documentation)
- Microsoft Learn documentation
- Stack Overflow and Server Fault
- PowerShell.org forums
- Security blogs (CyberDrain, NinjaOne, 4sysops)
- Recent articles (past 1-2 years)

**Documentation:**
- Cite key findings
- Note security implications
- Identify potential risks
- Record version-specific considerations

---

### 3. **Question**

**Purpose:** Clarify ambiguities and gather missing information before implementation.

**Actions:**
- Ask clarifying questions BEFORE taking action
- Identify decision points that require user input
- Propose alternatives and trade-offs
- Request missing technical details (credentials, domains, preferences)
- Confirm assumptions

**Categories of Questions:**
- **Technical:** "Do you own a custom domain for URL shortening?"
- **Preference:** "Should the script be named Install.ps1 or keep the current name?"
- **Scope:** "Should we add version self-checking?"
- **Security:** "Do you have a code signing certificate?"
- **Infrastructure:** "GitHub public or private repository?"

**Anti-Pattern:**
- ❌ Making assumptions and proceeding without confirmation
- ❌ Implementing a solution that requires resources the user doesn't have
- ❌ Choosing arbitrary defaults without offering alternatives

---

### 4. **Advice**

**Purpose:** Provide expert recommendations based on investigation and experience.

**Actions:**
- Propose a recommended approach with rationale
- Present alternatives with pros/cons
- Explain trade-offs clearly
- Cite evidence from investigation phase
- Provide implementation plan outline
- Highlight risks and mitigations

**Structure:**
```
Recommended Approach: [Clear statement]

Why This Approach:
- ✅ Benefit 1 (with evidence/citation)
- ✅ Benefit 2
- ⚠️ Consideration/Risk + mitigation

Alternatives Considered:
1. Option A: [Pros/Cons]
2. Option B: [Pros/Cons]

Implementation Plan:
1. Step 1
2. Step 2
3. Step 3
```

---

### 5. **Document**

**Purpose:** Create comprehensive, persistent records of decisions, motivations, and actions.

**Actions:**
- Document the plan BEFORE implementation
- Document decisions and rationale
- Document motivations (why, not just what)
- Update CHANGELOG.md with version changes
- Update relevant documentation files (README, ARCHITECTURE, etc.)
- Create session summaries for major work
- Update this AIQD_Methodology.md when process evolves

**Documentation Artifacts:**

1. **Decision Records**
   - What was decided
   - Why it was decided
   - What alternatives were considered
   - What risks were identified

2. **Implementation Plans**
   - Step-by-step approach
   - Files to be modified
   - Expected outcomes
   - Testing strategy

3. **Session Summaries**
   - Work completed
   - Decisions made
   - Next steps
   - Open questions

4. **Code Comments**
   - Why code exists (not just what it does)
   - Security considerations
   - Compatibility notes
   - Future enhancement ideas

5. **Git Commit Messages**
   - Descriptive, structured format
   - Include context and motivation
   - Reference issues/decisions

---

## When to Apply AIQD

### **Mandatory Scenarios:**

Apply the full AIQD process when:
- ✅ Adding new features
- ✅ Changing architecture or deployment model
- ✅ Making security-related decisions
- ✅ Introducing breaking changes
- ✅ Selecting between multiple approaches
- ✅ User explicitly requests "AIQD"

### **Optional but Recommended:**

Consider AIQD for:
- 🔄 Significant refactoring
- 🔄 Performance optimizations
- 🔄 Dependency changes
- 🔄 Documentation restructuring

### **Not Required:**

AIQD not needed for:
- ❌ Simple typo fixes
- ❌ Formatting changes
- ❌ Minor documentation updates
- ❌ Obvious bug fixes with clear solutions

---

## AIQD Benefits

### **For the Project:**
- ✅ **Better decisions** through research and investigation
- ✅ **Fewer mistakes** by questioning assumptions
- ✅ **Comprehensive documentation** for future reference
- ✅ **Knowledge transfer** through documented rationale
- ✅ **Risk mitigation** by identifying issues early

### **For the Developer:**
- ✅ **Clear requirements** before coding begins
- ✅ **Reduced rework** from misunderstood requirements
- ✅ **Learning opportunity** through investigation phase
- ✅ **Confidence** in recommendations

### **For Future Contributors:**
- ✅ **Understand why** decisions were made
- ✅ **Learn from** past investigations
- ✅ **Avoid repeating** already-considered approaches
- ✅ **Context** for architectural choices

---

## AIQD Documentation Standards

### **File Naming:**
- `AIQD_Methodology.md` - This file
- `SESSION_[N]_SUMMARY.md` - Per-session documentation
- `CHANGELOG.md` - Version history with rationale
- `ARCHITECTURE.md` - Technical decisions and trade-offs

### **Commit Message Format:**

```
type: short description (v0.X.Y)

[AIQD] Detailed explanation of what changed and why

ACKNOWLEDGE:
- Goal: [restated goal]
- Current state: [description]
- Desired state: [description]

INVESTIGATE:
- Key finding 1 (source: URL)
- Key finding 2 (source: URL)
- Security consideration (source: URL)

QUESTION:
- Q1: [question and answer]
- Q2: [question and answer]

ADVICE:
- Recommended approach: [description]
- Alternative considered: [description]
- Rationale: [explanation]

DOCUMENT:
- Files modified: [list]
- Documentation updated: [list]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

### **Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code refactoring
- `test`: Testing changes
- `chore`: Maintenance
- `security`: Security-related changes
- `arch`: Architecture changes

---

## Example: AIQD in Action

### **User Request:**
> "Let's use what Chris Titus uses in his Windows Tool, that allows the user to just run a Github hosted one-liner from an admin-rights PowerShell console"

### **AIQD Application:**

**1. Acknowledge:**
- Current: Download-first, local execution model
- Desired: Web-hosted, one-liner remote execution (`irm | iex`)
- Goal: Simplify deployment like Chris Titus Tech Windows Utility

**2. Investigate:**
- Researched Chris Titus Tech GitHub repository structure
- Identified URL redirect mechanism (christitus.com/win → GitHub releases)
- Reviewed PowerShell security best practices for remote execution
- Examined `irm` vs `iwr` and `iex` security implications
- Found execution policy recommendations (RemoteSigned, AllSigned)

**3. Question:**
- GitHub repository details (user, org, public/private)?
- Custom domain availability for short URL?
- Script naming preference (Install.ps1 vs current name)?
- Version self-check feature desired?
- Uninstall option needed?
- Code signing certificate available?

**4. Advice:**
- Recommended: GitHub Releases strategy
- Rationale: Clean URLs, versioning, no custom infrastructure
- Security: HTTPS + GitHub trust (like Chris Titus approach)
- Structure: Rename to Install.ps1, use semantic versioning
- Alternative: Custom domain redirect (requires domain ownership)

**5. Document:**
- Created AIQD_Methodology.md (this file)
- Plan documented before implementation
- Awaiting user answers to proceed
- Next session will document implementation decisions

---

## Continuous Improvement

This methodology document is a living document and should be updated when:
- New insights emerge about effective development processes
- User requests modifications to the approach
- Better practices are discovered
- The project scales and requires additional structure

**Last Updated:** November 16, 2025
**Version:** 1.0
**Next Review:** As needed based on project evolution

---

## References

**Methodology Inspiration:**
- Agile development practices
- Documentation-driven development
- Research-first approach
- Collaborative requirement refinement

**Applied to:**
- PowerShell Event Sender v0.2.0+
- All future development sessions

---

**Adopted by:** gfernandez & Claude Code
**Status:** Active and in use
