Backend task prompt template

Use this template when asking an AI or a backend developer to implement or fix backend behavior (e.g., password reset, email sending, endpoints). Fill in the placeholders.

Title: [Short description of task]

Context:
- Project: Devoverflow mobile app (Flutter)
- Backend base URL: [e.g., http://192.168.194.38:3000/api]
- Auth: [JWT / none]
- Related endpoints: [list endpoint paths, e.g., /auth/forgot-password]
- Current behavior: [what happens now, include logs, response codes]
- Expected behavior: [what should happen]

Reproduction steps:
1. [Steps to reproduce the issue locally]
2. [Device/emulator details]
3. [Any relevant environment variables or headers]

Logs / Error messages:
- [Paste server logs or client logs here]

Suggested acceptance criteria:
- Endpoint returns 200/201 with JSON { success: true, message: '...' } on success
- Email is sent using configured SMTP or third-party provider
- Token generation and storage verified (if applicable)
- Proper error handling and descriptive messages for failure cases

Attachments:
- Relevant server files: [list filenames]
- Relevant client files: lib/api_service.dart, lib/forgetpassword.dart

Notes for implementer:
- Verify environment variables and API base path (note `/api` vs `/api/v1`)
- For local emulator testing, ensure the correct host mapping (10.0.2.2 or host IP)
- Include unit tests for the password reset flow if possible

Example request body:
{
  "email": "user@example.com"
}

Example successful response:
{
  "success": true,
  "message": "If a user with this email exists, a password reset link will be sent."
}

Example error response:
{
  "success": false,
  "message": "User not found",
  "errors": ["No such user"]
}
