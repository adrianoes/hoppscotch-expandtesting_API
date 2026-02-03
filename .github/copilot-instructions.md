# Hoppscotch API Testing Project - AI Agent Guide

## Project Overview
API test automation for the expandtesting Notes API using Hoppscotch collections. This is a **test collection project**, not application code - you'll be working with JSON test definitions, not traditional code files.

## Architecture

### Core Components
- `expandtesting.json`: Hoppscotch collection containing 35+ API test requests organized sequentially (health checks → user management → notes CRUD)
- `expandtesting_env.json`: Environment variables file storing dynamic test data (tokens, user IDs, note IDs, etc.) that persist across test runs
- Each request contains:
  - `preRequestScript`: JavaScript to generate random test data using `pw.env.set()`
  - `testScript`: JavaScript assertions using `pw.test()` and `pw.expect()`
  - `headers`: Including auth token (`X-Auth-Token`)
  - `body`: JSON payloads with `<<variable>>` placeholders

### Test Flow Pattern
Tests follow a stateful workflow where each request builds on previous ones:
1. Create user → stores `user_id`, `user_token` in environment
2. Login → updates `user_token`
3. Create notes → stores `note_id`, `note_completed`, timestamps
4. CRUD operations use stored IDs
5. Cleanup deletes notes and user account

**Critical**: Test order matters. Tests 2-16 depend on values set by earlier tests.

## Developer Workflows

### Running Tests
```bash
# Recommended: Run tests and auto-generate both XML and HTML reports
npm test

# Alternative: Execute full collection with JUnit XML report only
hopp test -e expandtesting_env.json -d 1000 expandtesting.json --reporter-junit ./reports/report.xml

# Convert existing XML report to HTML
npm run convert-report

# Manually create JIRA issue from last test results
npm run jira-report
```
- `npm test`: Runs tests, generates reports (XML/HTML), and creates JIRA issues if tests fail
- `-e expandtesting_env.json`: Specifies environment file
- `-d 1000`: Delay of 1000ms between requests
- `--reporter-junit`: Exports results to XML format in reports/
- HTML reports provide a professional, user-friendly view with color-coded results
- JIRA integration is automatic but requires `.env` configuration

### Pre-requirements
- Node.js 18.18.0+
- node-gyp 10.2.0+ (install: `npm install -g node-gyp`)
- Hoppscotch CLI 0.30.0+ (install: `npm i -g @hoppscotch/cli`)
- Hoppscotch Desktop 25.12.0
- Project dependencies: `npm install` (installs xml2js, axios, dotenv, form-data)
- JIRA account with API token (optional, for automated issue creation)

## Project-Specific Conventions

### Test Naming Pattern
Format: `{sequence} - {action} [- error scenario]`
- Example: `"2.1 - Creates a new user account"`
- Example: `"3.2 - Log in as an existing user - bad request"`
- Sequence numbers (1-16) indicate execution order
- Sub-numbers (.1, .2, .3) indicate happy path vs error scenarios

### Random Data Generation
Pre-request scripts generate unique test data each run:
```javascript
var random = Math.floor(Math.random() * 1000)+1000;
pw.env.set("randomValue", random.toString());
pw.env.set("user_name", pw.env.get("randomValue")+" test");
pw.env.set("user_email", pw.env.get("randomValue")+"@test.com");
```
This prevents conflicts from previous test runs on the shared API.

### Boolean Handling Quirk
Hoppscotch cannot store boolean environment variables directly:
```javascript
// Store as string
pw.env.set("note_completed", responseCN.data.completed.toString());

// Compare using toString()
pw.expect(pw.env.get("note_completed")).toBe(responseUN.data.completed.toString());
```

### Variable Naming Convention
- `user_*`: User account data (user_id, user_name, user_email, user_password, user_token)
- `note_*`: Note entity data (note_id, note_title, note_description, note_category, note_completed)
- `note_*_2`: Second note instance for multi-note tests
- `randomValue`: Temporary random number for data generation
- Variables use `<<variable>>` syntax in request bodies

### Error Testing Pattern
Each endpoint has 3 test variants:
1. **Happy path** (.1): Valid request with expected success response
2. **Bad request** (.2): Invalid data (malformed email, invalid category) expecting 400 status
3. **Unauthorized** (.3): Invalid/missing token with `@` prefix expecting 401 status

## Key Integration Points

### API Base URL
`https://practice.expandtesting.com/notes/api` stored in `base_url` environment variable

### Authentication Flow
1. Register user (test 2.1) → receive no token
2. Login (test 3.1) → sets `user_token` in environment
3. All subsequent requests include header: `{"key": "X-Auth-Token", "value": "<<user_token>>"}`
4. Logout (test 14.3) → invalidates token
5. Re-login (test 15) → new token required

### Notes Category Validation
Only 3 valid categories: `Home`, `Work`, `Personal`
- Random selection: `categoryArray[Math.floor(Math.random()*categoryArray.length)]`
- Invalid values trigger 400 error (see test 7.2)

## Important Constraints

### Manual Testing Required
Password reset endpoints (send email, verify token) cannot be automated - require email access for verification.

### Environment File State
`expandtesting_env.json` retains last test run values. Fresh test runs overwrite these with new random data.

## Test Reports

### Report Generation
- `npm test` generates both XML (JUnit format) and HTML reports in `./reports/`
- `report.xml`: Machine-readable JUnit format for CI/CD integration
- `report.html`: Professional, color-coded HTML report for human review
- HTML report features:
  - Summary dashboard with success rate, total tests, pass/fail counts
  - Expandable test suites with color-coded status indicators
  - Detailed test case results with assertion messages
  - Responsive design with gradient backgrounds and modern styling

### Conversion Script
- `convert-report.js`: Node.js script that converts XML to HTML using xml2js
- Automatically called after test execution via `npm test`
- Can be run manually with `npm run convert-report`

## JIRA Integration

### Automated Issue Creation
The project includes automatic JIRA integration that creates issues when tests fail:
- Triggered automatically by `npm test` after test execution
- Only creates issues if at least one test fails
- Provides detailed failure information in JIRA ticket

### Configuration
Required environment variables in `.env` file:
- `JIRA_BASE_URL`: JIRA instance URL (e.g., https://company.atlassian.net)
- `JIRA_EMAIL`: User's JIRA email address
- `JIRA_API_TOKEN`: API token from JIRA profile settings
- `JIRA_PROJECT_KEY`: Project identifier (e.g., DEV, QA)
- `JIRA_ISSUE_TYPE`: Type of issue to create (default: Bug)

### JIRA Issue Content
Automatically generated issues include:
- Summary with number of failures
- Detailed statistics table (total, passed, failed, duration)
- Failed test suites with execution time
- Individual failed test cases with error messages
- Timestamp and API endpoint information
- Labels: `automated-test`, `api-test`, `hoppscotch`
- Priority: High (>5 failures) or Medium (≤5 failures)

### JIRA Reporter Script
- `jira-reporter.js`: Reads XML report and creates JIRA issues via REST API
- Uses Atlassian Document Format (ADF) for rich formatting
- Validates configuration before attempting to create issues
- Gracefully handles missing configuration (tests run normally)
- Can be run manually with `npm run jira-report`

### Security
- `.env` file is gitignored to prevent credential exposure
- `example.env` provides template for configuration
- Uses HTTP Basic Auth with API token (not password)

## 
## Editing Guidelines

When modifying test requests:
- Update both request definition AND corresponding test assertions
- Maintain test sequence numbering
- Keep pre-request scripts that generate required variables
- Preserve error scenario tests (.2, .3) when adding new happy path tests
- Update environment variable names consistently across all references
