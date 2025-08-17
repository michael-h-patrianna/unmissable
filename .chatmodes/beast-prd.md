# Beast PRD

## Problem Statement
The current `doc.md` file needs optimization to serve as an effective context source for LLM coding agents working on the Unmissable codebase.

## Target Users & Jobs-to-be-Done
- **Primary User**: LLM coding agents
- **JTBD**: Understand codebase architecture, patterns, and requirements to generate high-quality code changes, bug fixes, and new features

## Goals & Success Metrics
- **Primary Goal**: Create comprehensive, LLM-friendly documentation that enables autonomous code generation
- **Success Metrics**:
  - Clear architectural overview with component relationships
  - Documented code patterns and conventions
  - Complete flow descriptions for key features
  - Troubleshooting and debugging guidance
  - Testing requirements and patterns

## Scope

### In Scope
- Restructure doc.md with clear, hierarchical sections
- Document core architecture and component relationships
- Include code patterns, conventions, and best practices
- Add critical flows (calendar integration, overlay management, event handling)
- Document dependencies and configuration requirements
- Include testing strategies and patterns
- Add debugging and troubleshooting guidance

### Out of Scope
- Detailed API documentation (should reference existing docs)
- User-facing feature documentation
- Installation instructions (covered in separate files)

## Functional Requirements
1. **Architecture Section**: Clear component diagram and relationships
2. **Code Patterns**: Swift conventions, error handling, async patterns
3. **Critical Flows**: Step-by-step process descriptions
4. **Dependencies**: External libraries and system requirements
5. **Testing**: Unit, integration, and UI testing patterns
6. **Configuration**: Environment setup and config management

## Non-Functional Requirements
- **Performance**: Document should be scannable and hierarchically organized
- **Accessibility**: Clear headings, bullet points, and code blocks
- **Maintainability**: Structured format that's easy to update

## Acceptance Criteria
1. Document has clear table of contents and section hierarchy
2. Architecture section includes component relationships and data flow
3. Code patterns section has concrete Swift examples
4. Critical flows are documented with step-by-step processes
5. Testing section includes patterns for all test types in the project
6. Configuration and setup requirements are clearly documented
7. Document length is optimized for LLM context windows
8. All sections use actionable language suitable for code agents
