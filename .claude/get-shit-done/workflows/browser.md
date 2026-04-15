<purpose>
Browser automation workflow for GSD. Handles web-based interactions with tools like Jenkins,
Plane, and other web interfaces. Supports authentication, navigation, form submission,
screenshot capture, and verification.
</purpose>

<process>

<step name="parse_arguments">
## 1. Parse Arguments

Parse `$ARGUMENTS` to extract:
- `URL`: Target URL (first argument)
- `--task`: Specific task to perform (login, configure-webhook, install-plugins, etc.)
- `--screenshot`: Capture screenshot flag
- `--wait-for`: CSS selector to wait for
- `--credentials`: Credential ID from Jenkins or explicit user:pass
- `--data`: JSON data for form submission

If no URL provided, error: "URL required. Usage: /gsd-browser <url> [--task <task>]"
</step>

<step name="navigate">
## 2. Navigate to URL

```
BrowserNavigate(url="$URL")
```

Verify page loaded by checking title or body presence.
If page fails to load, capture error and exit.
</step>

<step name="execute_task">
## 3. Execute Task

Based on `$TASK` value:

### Task: login
Authenticate with web interface.

**Steps:**
1. Check for login form elements (username/password fields)
2. If credentials not provided via `--credentials`, prompt user
3. Fill username and password fields
4. Click login button
5. Wait for redirect/dashboard
6. Verify successful login
7. Return session status

### Task: navigate
Simple navigation with verification.

**Steps:**
1. Navigate to URL
2. Wait for `--wait-for` selector if provided
3. Take screenshot if `--screenshot` flag set
4. Return page snapshot summary

### Task: jenkins-install-plugins
Install plugins in Jenkins.

**Steps:**
1. Navigate to Manage Jenkins → Plugins
2. Click "Available Plugins"
3. Search for each plugin in list
4. Check checkbox for each plugin
5. Click "Install"
6. Wait for installation completion
7. Return installation status

### Task: plane-create-webhook
Create webhook in Plane.

**Steps:**
1. Navigate to Project Settings → Integrations
2. Click "Webhooks"
3. Click "Create Webhook"
4. Fill webhook URL from `--data`
5. Select events (issue updates)
6. Save webhook
7. Test webhook delivery
8. Return webhook configuration

### Task: jenkins-create-job
Create Jenkins pipeline job.

**Steps:**
1. Click "New Item"
2. Enter job name from `--data`
3. Select "Pipeline"
4. Configure job parameters
5. Add pipeline script from `--data`
6. Save job
7. Return job URL

### Task: verify-integration
End-to-end verification.

**Steps:**
1. Trigger action in source system (Plane)
2. Wait for webhook delivery
3. Verify Jenkins received webhook
4. Verify build triggered
5. Verify Plane updated with result
6. Return test results

### Default (no task)
Navigate to URL, wait for load, optionally screenshot, return page info.
</step>

<step name="capture_results">
## 4. Capture Results

If `--screenshot` flag or task requires documentation:
```
BrowserTakeScreenshot(filename="gsd-browser-$TIMESTAMP.png")
```

Capture page snapshot for verification:
```
BrowserSnapshot()
```

Extract relevant data based on task:
- Login: session status, user info
- Webhook: webhook URL, token, status
- Job: job URL, build number
- Integration: test results, timestamps
</step>

<step name="return_results">
## 5. Return Results

Format output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► BROWSER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: $URL
Task: $TASK
Status: $STATUS

Results:
$result_data

Screenshots: $screenshot_count
Session: $session_duration
```
</step>

</process>

<success_criteria>
- [ ] URL successfully loaded
- [ ] Task executed completely
- [ ] Results captured and returned
- [ ] Screenshots taken if requested
- [ ] Errors handled gracefully
- [ ] Session properly closed
</success_criteria>
