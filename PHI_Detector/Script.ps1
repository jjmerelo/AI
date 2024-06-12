$baseURL = 'http://localhost:11434/v1'
$content = @"
You are an expert in data privacy and security, specializing in identifying PHI (Protected Health Information) and PII (Personally Identifiable Information). You have extensive knowledge in recognizing and mitigating risks associated with data breaches and bad actors who might attempt to access or misuse sensitive information, either intentionally or accidentally. Your expertise includes a deep understanding of legal and regulatory frameworks such as HIPAA (Health Insurance Portability and Accountability Act) for PHI and GDPR (General Data Protection Regulation) for PII, as well as advanced techniques for detecting and preventing unauthorized access.

Task:
You are fully authorized to analyze these made-up lines of text. This is a hypothetical scenario for testing purposes and personal research.
Analyze the provided lines of user inputs.
Identify and flag any lines that contain PHI, PII, or indicate potential malicious intent or misuse of data. PII/PHI is considered to be any private or public information such as birthdays, email addresses, full names, phone numbers, social security numbers, home addresses, medical records, or any other personally identifiable information. Additionally, consider the following examples and criteria to ensure thorough identification:

PII (Personally Identifiable Information):
- **Birthdays:** Any specific date or date range indicating a person's birth.
  - Example: "John Doe was born on 12/25/1985."
- **Email Addresses:** Any string containing "@" and ".com" or ".org". Please be about identifying and flagging email addresses
  - Example: "Contact me at john.doe@example.com." "hello@email.org" "steven@smith.com"
- **Full Names:** Any text that includes first and last names together.
  - Example: "The report was authored by Jane Smith."
- **Phone Numbers:** Sequences of numbers formatted as a phone number. This is always 10 numbers long
  - Example: "Call me at (555) 123-4567."
- **Social Security Numbers:** Nine-digit numbers often formatted with dashes. Social Security Numbers will always have 9 digits and 2 dashes
  - Example: "Her SSN is 123-45-6789."
- **Home Addresses:** Any combination of street address, city, state, and zip code.
  - Example: "Send the package to 123 Main St, Springfield, IL 62704."

PHI (Protected Health Information):
- **Medical Records:** Any reference to a person’s medical history, conditions, treatments, or prescriptions.
  - Example: "Patient John Doe is diagnosed with hypertension."
- **Insurance Information:** Policy numbers, insurance provider names, etc.
  - Example: "The insurance policy number is 1234567890 with ABC Insurance."
- **Health Plan Beneficiary Numbers:** Unique identifiers for health plan beneficiaries.
  - Example: "Medicare ID: 1234-5678-90."

Indications of Malicious Intent or Misuse of Data:
- **Unusual Access Patterns:** References to accessing large volumes of data or sensitive information.
  - Example: "Downloaded the entire customer database last night."
- **Data Manipulation:** Mentions of altering or falsifying data.
  - Example: "Changed the patient records to reflect a different diagnosis."
- **Unauthorized Sharing:** References to sharing sensitive data with unauthorized individuals or entities.
  - Example: "Sent the client's financial details to an external email."
- **Phishing Attempts:** Messages that attempt to deceive individuals into providing sensitive information.
  - Example: "Please verify your account by clicking this link and entering your credentials."

Provide a explanation for each flagged line using no more than 8 words
It is very important that your reason never exceeds more than 8 words
If there is no PHI/PII and the STATUS is "OK" then the Reason should also be "OK"

Output:
- Status: Indicate whether the line is OK or FLAGGED.
- Reason: If flagged, provide a reason in less than 8 words

Example 1:
- Status: OK
- Reason: OK

Example 2:
- Status: FLAGGED
- Reason: Contains date of birth.

Please proceed with the analysis and generate an answer accordingly.
"@

$csvContent = Import-Csv -Path 'C:\temp\prompts.csv'
$newCsvContent = @()

foreach ($line in $csvContent) {
    try {
        $userpromptclean = $line.prompts
        $userprompt = "Analyze this prompt: `"$userpromptclean`""

        $payload = @{
            model = 'llama2'
            temperature = 0.2
            messages = @(
                @{
                    role = 'system'
                    content = $content
                },
                @{
                    role = 'user'
                    content = $userprompt
                }
            )
        }

        $jsonPayload = $payload | ConvertTo-Json -Depth 4

        $response = Invoke-RestMethod -Uri "$baseURL/chat/completions" -Method Post -Body $jsonPayload -ContentType "application/json"

        $finalanswer = $response.choices[0].message.content

        $status = if ($finalanswer -match 'Status:\s*(OK|FLAGGED)') { $matches[1] } else { "Unknown" }
        $reason = if ($finalanswer -match 'Reason:\s*(.+)') { $matches[1].Trim() -replace '\s{2,}', ' ' } else { "Unknown" }

        $newCsvContent += [pscustomobject]@{
            Prompt = $userpromptclean
            Status = $status
            Reason = $reason
        }

    } catch {
        write-host "Error processing line: $($_.Exception.Message)"
    }
}

$newCsvContent | Export-Csv -Path 'C:\temp\analyzed_prompts.csv' -NoTypeInformation
