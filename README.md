# Camden District Nursing Housebound Flu Vaccination Analysis

## Project Overview

This project analyses a District Nursing housebound flu vaccination pathway, from identifying eligible patients through validation, contact, visits, vaccination and vaccine stock reconciliation.

The project recreates and extends operational questions encountered within NHS community services using entirely synthetic data for portfolio purposes.

The aim was to identify opportunities to streamline patient validation, reduce avoidable administrative and clinical activity, monitor vaccination performance and improve visibility of workforce and vaccine utilisation.

## Business Problem

District Nursing teams provide flu vaccinations to eligible housebound patients as part of routine community nursing activity.

Before patients can be vaccinated, teams need to ensure that the correct patients are being included in the pathway and that information such as District Nursing caseload status, housebound status, vaccination eligibility and current vaccination status is accurate.

Poorly aligned or incomplete information can create additional administrative work, unnecessary patient contact and avoidable clinical activity.

The analysis therefore focused on the following question:

**How effectively is District Nursing identifying eligible housebound patients and integrating flu vaccination into routine community nursing activity, while minimising unresolved eligibility and vaccination status issues?**

## Objectives

The analysis aimed to:

- Define a validated eligible patient cohort
- Identify records requiring further review
- Analyse patient contact and vaccination pathways
- distinguish current patient status from previous Unable To Contact activity
- Compare operational activity across District Nursing teams
- Adjust team comparisons for vaccination trained WTE
- Analyse GP level eligibility and data quality issues
- Monitor vaccine utilisation, wastage and stock reconciliation
- Create management KPIs and a Power BI dashboard

## Tools Used

**SQL**
Used for data validation, cohort classification, pathway analysis, conditional aggregation, window functions, duplicate prevention and stock reconciliation.

**Excel**
Used for operational validation, lookups, conditional calculations, PivotTables and reconciliation checks.

**Power BI**
Used to create the relational data model, DAX measures, management KPIs and interactive dashboard.

## Dataset

The project uses a fully synthetic dataset created to represent a District Nursing flu vaccination programme.

The dataset contains fictional:

- Patients
- GP practices
- District Nursing teams
- Staff
- Contact attempts
- Home visits
- Vaccination records
- Vaccine stock transactions

No real patient identifiable information or confidential NHS data is included.

## Data Model

The analysis uses several related operational tables:

### Patient List

One row per patient.

Contains information including:

- District Nursing caseload status
- Housebound status
- GP confirmed vaccination eligibility
- GP practice
- District Nursing sub team

### Contact Log

One row per patient contact attempt.

This allows repeated contact activity to be analysed without incorrectly treating each attempt as a separate patient.

### Visit Log

One row per visit or visit attempt.

Contains visit outcomes, allocated staff, travel information and whether vaccination status issues were discovered during the visit.

### Vaccination Records

One row per vaccination.

Contains vaccination date, vaccine manufacturer, batch number, staff member and recording information.

### Staff

Contains District Nursing team, role, band, WTE and vaccination training status.

### Stock Log

Contains vaccine stock received, administered, wasted and remaining by GP supplied batch.

## Data Validation and Cohort Logic

A key part of the analysis was determining which patients should remain in the vaccination pathway.

Patients were classified into categories including:

- Validated Eligible
- Already Vaccinated
- Not Active District Nursing Caseload
- Not Housebound
- Eligibility Not Confirmed
- Review Required
- Deceased

Consent was treated as a pathway outcome rather than an eligibility criterion.

Patients who remained eligible but had not reached a final vaccination outcome were classified as outstanding.

Outstanding patients were further divided into:

**Actionable Outstanding**

Patients who could currently progress through the vaccination pathway.

**Deferred Outstanding**

Patients who remained eligible but were temporarily unable to progress due to factors such as hospitalisation, clinical deferral or vaccine availability.

## Contact Pathway

Patients may require multiple contact attempts before successful contact.

The analysis therefore separates:

- Number of contact attempts
- Number of distinct contact days
- Latest contact outcome
- Previous Unable To Contact status
- Current patient pathway status

A historical Unable To Contact status does not automatically remove a patient from the vaccination pathway.

If a patient is later successfully contacted, their latest status takes priority while previous UTC activity remains available for workload analysis.

## Preventing Duplicate Counting

Several tables contain multiple rows for the same patient.

For example, one patient may have:

- Three contact attempts
- Two visit attempts

Directly joining those raw event tables could create six rows for one patient.

To avoid inflated activity counts, event tables were either analysed separately or aggregated to the appropriate patient level before being combined.

## Key Findings

### Patient Validation

The validation stage identified a number of records requiring further review before vaccination activity could proceed.

Issues included patients who were not on the active District Nursing caseload, patients already vaccinated, unclear eligibility and patients whose housebound status required further review.

This indicates that stronger validation earlier in the pathway could reduce downstream administrative workload.

### Patient Contact

Unable To Contact should not automatically be treated as a final pathway outcome.

Patients may initially be unreachable but later become contactable or may still be seen during routine District Nursing activity.

Maintaining both historical UTC activity and current patient status provides a more accurate view of the vaccination pathway.

### Team Capacity

South 1 recorded the highest vaccination activity relative to vaccination trained WTE.

However, the team also experienced a higher visit and travel burden.

Vaccination output should therefore be interpreted alongside staffing capacity, travel requirements, visit activity and wider District Nursing workload rather than being used as a standalone measure of team efficiency.

### Vaccine Stock

Vaccine stock was analysed using:

**Received = Administered + Wasted + Closing Balance**

Stock utilisation and wastage were also monitored.

Where vaccination records and stock activity did not align, the discrepancy was treated as requiring reconciliation rather than automatically being classified as missing vaccine stock.

## Recommendations

The main operational recommendation is to use the active District Nursing caseload as the starting point for the vaccination programme.

Patients should be grouped by GP practice and sent to the relevant GP for review and confirmation of current vaccination eligibility and vaccination status.

Once returned, District Nursing administration can complete remaining validation before patients progress into the contact and vaccination pathway.

New patients joining the District Nursing caseload during the campaign should be added to the live GP list and highlighted for review before being actioned.

Additional recommendations include:

- Monitor vaccine usage and reconciliation throughout the campaign
- Investigate recurring eligibility issues by GP practice
- Review outstanding patients throughout the vaccination period
- Consider travel and visit burden when comparing District Nursing teams
- Monitor vaccine wastage and investigate reasons for avoidable waste

## Dashboard KPIs

The Power BI dashboard focuses on five headline measures:

- Validated Eligible Patients
- Outstanding Patients
- Successful Visit %
- Stock Utilisation %
- Wastage %

Additional visuals analyse:

- Eligibility and validation issues
- GP practice variation
- District Nursing team activity
- Patient vaccination pathway
- Vaccine stock utilisation

## Limitations

This project uses synthetic data and therefore does not represent actual Camden District Nursing performance.

Operational recording can also be affected by delayed, incomplete or incorrect data entry.

Apparent stock discrepancies may therefore represent recording or reconciliation issues rather than physical vaccine loss.

Vaccinations per WTE should not be interpreted as a complete measure of staff productivity because the analysis does not capture every element of routine District Nursing workload or patient complexity.

## Skills Demonstrated

- SQL data validation
- Data cleaning
- JOINs and CTEs
- CASE statements
- Conditional aggregation
- Window functions
- ROW_NUMBER
- DISTINCTCOUNT
- Patient level aggregation
- Data modelling
- Excel XLOOKUP
- COUNTIFS and SUMIFS
- PivotTables
- Power BI
- DAX
- KPI development
- Operational performance analysis
- Workforce capacity analysis
- Stock reconciliation
- Stakeholder focused recommendations

## Disclaimer

This is an independent portfolio project using synthetic data.

The project is inspired by operational questions encountered within NHS community services but does not contain real patient data, confidential NHS information or actual service performance results.
